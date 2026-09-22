import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/csp11_blueprint.dart';
import '../../models/study_content.dart';
import '../auth/learner_local_identity.dart';
import '../online_access/firebase_learner_access_token_provider.dart';
import '../online_access/learner_online_access_runtime.dart';
import '../supabase/supabase_bootstrap_service.dart';
import 'published_content_package.dart';
import 'uid_scoped_content_package_cache.dart';

abstract interface class LearnerContentPackageGateway {
  Future<ContentPackageResolution> resolveCompetency({
    required String competencyId,
    PublishedContentPackageDescriptor? knownPackage,
  });

  Future<List<PublishedContentPackageDescriptor>> loadCatalog();
}

class SupabaseLearnerContentPackageGateway
    implements LearnerContentPackageGateway {
  SupabaseLearnerContentPackageGateway({
    SupabaseClient? client,
    FirebaseLearnerAccessTokenProvider? tokenProvider,
  }) : _client = client,
       _tokenProvider = tokenProvider ?? FirebaseLearnerAccessTokenProvider();

  final SupabaseClient? _client;
  final FirebaseLearnerAccessTokenProvider _tokenProvider;

  SupabaseClient get _resolvedClient {
    if (!SupabaseBootstrapService.isInitialized) {
      throw StateError(
        'Supabase is not configured for learner content delivery.',
      );
    }

    return _client ?? Supabase.instance.client;
  }

  @override
  Future<List<PublishedContentPackageDescriptor>> loadCatalog() async {
    final token = await _currentFirebaseToken();
    final response = await _resolvedClient.functions.invoke(
      'learner-question-packages',
      body: const <String, dynamic>{'operation': 'content_catalog'},
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final data = _responseMap(response.data);
    final rawCatalog = data['catalog'];

    if (rawCatalog is! List) {
      throw const FormatException(
        'Content-package catalog response must contain a list.',
      );
    }

    final descriptors = <PublishedContentPackageDescriptor>[];

    for (final rawDescriptor in rawCatalog) {
      if (rawDescriptor is! Map) {
        throw const FormatException(
          'Content-package catalog entries must be objects.',
        );
      }

      descriptors.add(
        PublishedContentPackageDescriptor.fromJson(
          Map<String, dynamic>.from(rawDescriptor),
        ),
      );
    }

    descriptors.sort(
      (left, right) => left.competencyId.compareTo(right.competencyId),
    );

    return List<PublishedContentPackageDescriptor>.unmodifiable(descriptors);
  }

  @override
  Future<ContentPackageResolution> resolveCompetency({
    required String competencyId,
    PublishedContentPackageDescriptor? knownPackage,
  }) async {
    final normalized = _normalizeCompetencyId(competencyId);
    final token = await _currentFirebaseToken();

    final body = <String, dynamic>{
      'operation': 'content_competency',
      'competencyId': normalized,
      if (knownPackage != null)
        ...knownPackage.toKnownRequestJson()..remove('competencyId'),
    };

    final response = await _resolvedClient.functions.invoke(
      'learner-question-packages',
      body: body,
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    return ContentPackageResolution.fromJson(_responseMap(response.data));
  }

  Future<String> _currentFirebaseToken() async {
    final token = await _tokenProvider.currentToken();

    if (token == null || token.trim().isEmpty) {
      throw StateError(
        'A current Firebase ID token is required for content delivery.',
      );
    }

    return token.trim();
  }

  Map<String, dynamic> _responseMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw const FormatException(
      'Content-package gateway response must be a JSON object.',
    );
  }
}

abstract interface class SignedContentPackageDownloader {
  Future<List<int>> download(Uri signedUrl);
}

class HttpSignedContentPackageDownloader
    implements SignedContentPackageDownloader {
  const HttpSignedContentPackageDownloader();

  @override
  Future<List<int>> download(Uri signedUrl) async {
    if (signedUrl.scheme.toLowerCase() != 'https') {
      throw const FormatException(
        'Content-package download URL must use HTTPS.',
      );
    }

    final response = await http.get(signedUrl);

    if (response.statusCode != 200) {
      throw StateError(
        'Content-package download failed with HTTP ${response.statusCode}.',
      );
    }

    return List<int>.unmodifiable(response.bodyBytes);
  }
}

class LearnerContentPackageDeliveryService {
  LearnerContentPackageDeliveryService({
    LearnerContentPackageGateway? gateway,
    SignedContentPackageDownloader? downloader,
    ContentPackageDecoder decoder = const ContentPackageDecoder(),
  }) : _gateway = gateway,
       _downloader = downloader ?? const HttpSignedContentPackageDownloader(),
       _decoder = decoder;

  LearnerContentPackageGateway? _gateway;
  final SignedContentPackageDownloader _downloader;
  final ContentPackageDecoder _decoder;

  Future<List<PublishedContentPackageDescriptor>> loadCatalog() async {
    _requireAuthorizedUser();
    final gateway = _gateway ??= SupabaseLearnerContentPackageGateway();
    return gateway.loadCatalog();
  }

  Future<StudyContent> loadCompetency(String competencyId) async {
    final normalized = _normalizeCompetencyId(competencyId);
    final userId = _requireAuthorizedUser();
    final boundary = LearnerOnlineAccessRuntime.requireBoundaryFor(userId);
    final preferences = await SharedPreferences.getInstance();
    final cache = UidScopedContentPackageCache(
      store: SharedPreferencesProtectedContentPackageCacheStore(preferences),
      userId: userId,
      accessBoundary: boundary,
    );

    final gateway = _gateway ??= SupabaseLearnerContentPackageGateway();
    final cachedDescriptor = await cache.descriptorFor(normalized);

    var resolution = await gateway.resolveCompetency(
      competencyId: normalized,
      knownPackage: cachedDescriptor,
    );

    if (resolution.current) {
      final cached = await cache.loadVerified(normalized, decoder: _decoder);

      if (cached != null) {
        return _decodeContent(cached);
      }

      resolution = await gateway.resolveCompetency(
        competencyId: normalized,
      );
    }

    final signedUrl = resolution.signedUrl;

    if (signedUrl == null) {
      throw StateError(
        'Content-package gateway did not return a replacement URL.',
      );
    }

    final compressedBytes = await _downloader.download(signedUrl);

    await cache.saveVerified(
      descriptor: resolution.descriptor,
      compressedBytes: compressedBytes,
      decoder: _decoder,
    );

    final cached = await cache.loadVerified(normalized, decoder: _decoder);

    if (cached == null) {
      throw StateError(
        'Verified content package was unavailable after persistence.',
      );
    }

    return _decodeContent(cached);
  }

  String _requireAuthorizedUser() {
    final userId = LearnerLocalIdentity.requireCurrentUserId();
    final boundary = LearnerOnlineAccessRuntime.requireBoundaryFor(userId);

    if (!boundary.isAuthorizedFor(userId)) {
      throw StateError(
        'Protected StudyContent remains locked until current online '
        'authorization succeeds.',
      );
    }

    return userId;
  }

  StudyContent _decodeContent(CachedContentPackage cached) {
    return _decoder
        .decode(
          descriptor: cached.descriptor,
          compressedBytes: cached.compressedBytes,
        )
        .content;
  }
}

String _normalizeCompetencyId(String competencyId) {
  final normalized = competencyId.trim().toLowerCase();

  if (competencyForId(normalized) == null) {
    throw ArgumentError.value(
      competencyId,
      'competencyId',
      'Unknown CSP11 competency ID.',
    );
  }

  return normalized;
}
