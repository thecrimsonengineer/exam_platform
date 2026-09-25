import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/csp11_blueprint.dart';
import '../../../services/auth/learner_local_identity.dart';
import '../../../services/online_access/firebase_learner_access_token_provider.dart';
import '../../../services/online_access/learner_online_access_runtime.dart';
import '../../../services/supabase/supabase_bootstrap_service.dart';
import 'published_flashcard_package.dart';
import 'uid_scoped_flashcard_package_cache.dart';

abstract interface class LearnerFlashcardPackageGateway {
  Future<List<PublishedFlashcardPackageDescriptor>> loadCatalog();

  Future<FlashcardPackageResolution> resolveCompetency({
    required String competencyId,
    PublishedFlashcardPackageDescriptor? knownPackage,
  });
}

class SupabaseLearnerFlashcardPackageGateway
    implements LearnerFlashcardPackageGateway {
  SupabaseLearnerFlashcardPackageGateway({
    SupabaseClient? client,
    FirebaseLearnerAccessTokenProvider? tokenProvider,
  }) : _client = client,
       _tokenProvider = tokenProvider ?? FirebaseLearnerAccessTokenProvider();

  final SupabaseClient? _client;
  final FirebaseLearnerAccessTokenProvider _tokenProvider;

  SupabaseClient get _resolvedClient {
    if (!SupabaseBootstrapService.isInitialized) {
      throw StateError(
        'Supabase is not configured for learner flashcard delivery.',
      );
    }
    return _client ?? Supabase.instance.client;
  }

  @override
  Future<List<PublishedFlashcardPackageDescriptor>> loadCatalog() async {
    final token = await _currentFirebaseToken();
    final response = await _resolvedClient.functions.invoke(
      'learner-question-packages',
      body: const <String, dynamic>{'operation': 'flashcard_catalog'},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final data = _responseMap(response.data);
    final rawCatalog = data['catalog'];
    if (rawCatalog is! List) {
      throw const FormatException(
        'Flashcard catalog response must contain a list.',
      );
    }

    final descriptors = <PublishedFlashcardPackageDescriptor>[];
    for (final raw in rawCatalog) {
      if (raw is! Map) {
        throw const FormatException(
          'Flashcard catalog entries must be objects.',
        );
      }
      descriptors.add(
        PublishedFlashcardPackageDescriptor.fromJson(
          Map<String, dynamic>.from(raw),
        ),
      );
    }

    descriptors.sort(
      (left, right) => left.competencyId.compareTo(right.competencyId),
    );
    return List<PublishedFlashcardPackageDescriptor>.unmodifiable(descriptors);
  }

  @override
  Future<FlashcardPackageResolution> resolveCompetency({
    required String competencyId,
    PublishedFlashcardPackageDescriptor? knownPackage,
  }) async {
    final normalized = _normalizeCompetencyId(competencyId);
    final token = await _currentFirebaseToken();

    final body = <String, dynamic>{
      'operation': 'flashcard_competency',
      'competencyId': normalized,
      if (knownPackage != null)
        ...knownPackage.toKnownRequestJson()..remove('competencyId'),
    };

    final response = await _resolvedClient.functions.invoke(
      'learner-question-packages',
      body: body,
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    return FlashcardPackageResolution.fromJson(_responseMap(response.data));
  }

  Future<String> _currentFirebaseToken() async {
    final token = await _tokenProvider.currentToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError(
        'A current Firebase ID token is required for flashcard delivery.',
      );
    }
    return token.trim();
  }

  Map<String, dynamic> _responseMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException(
      'Flashcard gateway response must be a JSON object.',
    );
  }
}

abstract interface class SignedFlashcardPackageDownloader {
  Future<List<int>> download(Uri signedUrl);
}

class HttpSignedFlashcardPackageDownloader
    implements SignedFlashcardPackageDownloader {
  const HttpSignedFlashcardPackageDownloader();

  @override
  Future<List<int>> download(Uri signedUrl) async {
    if (signedUrl.scheme.toLowerCase() != 'https') {
      throw const FormatException('Flashcard download URL must use HTTPS.');
    }

    final response = await http.get(signedUrl);
    if (response.statusCode != 200) {
      throw StateError(
        'Flashcard package download failed with HTTP ${response.statusCode}.',
      );
    }
    return List<int>.unmodifiable(response.bodyBytes);
  }
}

abstract interface class FlashcardPackageRepository {
  Future<List<PublishedFlashcardPackageDescriptor>> loadCatalog();

  Future<FlashcardDeckPackage> loadCompetency(String competencyId);
}

class CloudFlashcardPackageRepository implements FlashcardPackageRepository {
  CloudFlashcardPackageRepository({
    LearnerFlashcardPackageGateway? gateway,
    SignedFlashcardPackageDownloader? downloader,
    FlashcardPackageDecoder decoder = const FlashcardPackageDecoder(),
  }) : _gateway = gateway,
       _downloader = downloader ?? const HttpSignedFlashcardPackageDownloader(),
       _decoder = decoder;

  LearnerFlashcardPackageGateway? _gateway;
  final SignedFlashcardPackageDownloader _downloader;
  final FlashcardPackageDecoder _decoder;

  @override
  Future<List<PublishedFlashcardPackageDescriptor>> loadCatalog() async {
    _requireAuthorizedUser();
    final gateway = _gateway ??= SupabaseLearnerFlashcardPackageGateway();
    final catalog = await gateway.loadCatalog();

    final d01d02 = catalog
        .where(
          (item) =>
              item.competencyId.startsWith('d01_') ||
              item.competencyId.startsWith('d02_'),
        )
        .toList(growable: false);

    return List<PublishedFlashcardPackageDescriptor>.unmodifiable(d01d02);
  }

  @override
  Future<FlashcardDeckPackage> loadCompetency(String competencyId) async {
    final normalized = _normalizeCompetencyId(competencyId);
    final userId = _requireAuthorizedUser();
    final boundary = LearnerOnlineAccessRuntime.requireBoundaryFor(userId);
    final preferences = await SharedPreferences.getInstance();

    final cache = UidScopedFlashcardPackageCache(
      preferences: preferences,
      userId: userId,
      accessBoundary: boundary,
    );

    final gateway = _gateway ??= SupabaseLearnerFlashcardPackageGateway();
    final known = await cache.descriptorFor(normalized);
    var resolution = await gateway.resolveCompetency(
      competencyId: normalized,
      knownPackage: known,
    );

    if (resolution.current) {
      final cached = await cache.loadVerified(normalized, decoder: _decoder);
      if (cached != null) {
        return _decoder
            .decode(
              descriptor: cached.descriptor,
              compressedBytes: cached.compressedBytes,
            )
            .package;
      }

      resolution = await gateway.resolveCompetency(competencyId: normalized);
    }

    final signedUrl = resolution.signedUrl;
    if (signedUrl == null) {
      throw StateError(
        'Flashcard gateway did not return a replacement package URL.',
      );
    }

    final bytes = await _downloader.download(signedUrl);
    await cache.saveVerified(
      descriptor: resolution.descriptor,
      compressedBytes: bytes,
      decoder: _decoder,
    );

    final cached = await cache.loadVerified(normalized, decoder: _decoder);
    if (cached == null) {
      throw StateError(
        'Verified flashcard package was unavailable after persistence.',
      );
    }

    return _decoder
        .decode(
          descriptor: cached.descriptor,
          compressedBytes: cached.compressedBytes,
        )
        .package;
  }

  String _requireAuthorizedUser() {
    final userId = LearnerLocalIdentity.requireCurrentUserId();
    final boundary = LearnerOnlineAccessRuntime.requireBoundaryFor(userId);

    if (!boundary.isAuthorizedFor(userId)) {
      throw StateError(
        'Protected flashcards remain locked until current online '
        'authorization succeeds.',
      );
    }
    return userId;
  }
}

String _normalizeCompetencyId(String competencyId) {
  final normalized = competencyId.trim().toLowerCase();
  final competency = competencyForId(normalized);
  if (competency == null ||
      (!normalized.startsWith('d01_') && !normalized.startsWith('d02_'))) {
    throw ArgumentError.value(
      competencyId,
      'competencyId',
      'Published flashcards currently support Domain 01 and Domain 02.',
    );
  }
  return normalized;
}
