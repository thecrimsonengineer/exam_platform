import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/csp11_blueprint.dart';
import '../../models/question.dart';
import '../auth/learner_local_identity.dart';
import '../online_access/firebase_learner_access_token_provider.dart';
import '../online_access/learner_online_access_runtime.dart';
import '../supabase/supabase_bootstrap_service.dart';
import 'published_question_package.dart';
import 'uid_scoped_question_package_cache.dart';

abstract interface class LearnerQuestionPackageGateway {
  Future<QuestionPackageResolution> resolveCompetency({
    required String competencyId,
    PublishedQuestionPackageDescriptor? knownPackage,
  });
}

class SupabaseLearnerQuestionPackageGateway
    implements LearnerQuestionPackageGateway {
  SupabaseLearnerQuestionPackageGateway({
    SupabaseClient? client,
    FirebaseLearnerAccessTokenProvider? tokenProvider,
  }) : _client = client,
       _tokenProvider = tokenProvider ?? FirebaseLearnerAccessTokenProvider();

  final SupabaseClient? _client;
  final FirebaseLearnerAccessTokenProvider _tokenProvider;

  SupabaseClient get _resolvedClient {
    if (!SupabaseBootstrapService.isInitialized) {
      throw StateError(
        'Supabase is not configured for learner question delivery.',
      );
    }

    return _client ?? Supabase.instance.client;
  }

  @override
  Future<QuestionPackageResolution> resolveCompetency({
    required String competencyId,
    PublishedQuestionPackageDescriptor? knownPackage,
  }) async {
    final normalized = _normalizeCompetencyId(competencyId);
    final token = await _tokenProvider.currentToken();

    if (token == null || token.trim().isEmpty) {
      throw StateError(
        'A current Firebase ID token is required for question delivery.',
      );
    }

    final body = <String, dynamic>{
      'operation': 'competency',
      'competencyId': normalized,
      if (knownPackage != null)
        ...knownPackage.toKnownRequestJson()..remove('competencyId'),
    };

    final response = await _resolvedClient.functions.invoke(
      'learner-question-packages',
      body: body,
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return QuestionPackageResolution.fromJson(data);
    }

    if (data is Map) {
      return QuestionPackageResolution.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return QuestionPackageResolution.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    }

    throw const FormatException(
      'Question-package gateway response must be a JSON object.',
    );
  }
}

abstract interface class SignedQuestionPackageDownloader {
  Future<List<int>> download(Uri signedUrl);
}

class HttpSignedQuestionPackageDownloader
    implements SignedQuestionPackageDownloader {
  const HttpSignedQuestionPackageDownloader();

  @override
  Future<List<int>> download(Uri signedUrl) async {
    if (signedUrl.scheme.toLowerCase() != 'https') {
      throw const FormatException(
        'Question-package download URL must use HTTPS.',
      );
    }

    final response = await http.get(signedUrl);

    if (response.statusCode != 200) {
      throw StateError(
        'Question-package download failed with HTTP '
        '${response.statusCode}.',
      );
    }

    return List<int>.unmodifiable(response.bodyBytes);
  }
}

class LearnerQuestionPackageDeliveryService {
  LearnerQuestionPackageDeliveryService({
    LearnerQuestionPackageGateway? gateway,
    SignedQuestionPackageDownloader? downloader,
    QuestionPackageDecoder decoder = const QuestionPackageDecoder(),
  }) : _gateway = gateway,
       _downloader = downloader ?? const HttpSignedQuestionPackageDownloader(),
       _decoder = decoder;

  LearnerQuestionPackageGateway? _gateway;
  final SignedQuestionPackageDownloader _downloader;
  final QuestionPackageDecoder _decoder;

  Future<List<Question>> loadCompetency(String competencyId) async {
    final normalized = _normalizeCompetencyId(competencyId);
    final userId = LearnerLocalIdentity.requireCurrentUserId();
    final boundary = LearnerOnlineAccessRuntime.requireBoundaryFor(userId);

    if (!boundary.isAuthorizedFor(userId)) {
      throw StateError(
        'Protected questions remain locked until current online '
        'authorization succeeds.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final cache = UidScopedQuestionPackageCache(
      store: SharedPreferencesProtectedQuestionPackageCacheStore(preferences),
      userId: userId,
      accessBoundary: boundary,
    );

    final gateway = _gateway ??= SupabaseLearnerQuestionPackageGateway();
    final cachedDescriptor = await cache.descriptorFor(normalized);
    var resolution = await gateway.resolveCompetency(
      competencyId: normalized,
      knownPackage: cachedDescriptor,
    );

    if (resolution.current) {
      final cached = await cache.loadVerified(normalized, decoder: _decoder);

      if (cached != null) {
        return _decodeQuestions(cached);
      }

      resolution = await gateway.resolveCompetency(competencyId: normalized);
    }

    final signedUrl = resolution.signedUrl;
    if (signedUrl == null) {
      throw StateError(
        'Question-package gateway did not return a replacement URL.',
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
        'Verified question package was unavailable after persistence.',
      );
    }

    return _decodeQuestions(cached);
  }

  Future<List<Question>> loadDomain(int domainNumber) async {
    final domain = domainForNumber(domainNumber);
    final merged = <int, Question>{};

    for (final competency in domain.competencies) {
      final questions = await loadCompetency(competency.id);

      for (final question in questions) {
        merged.putIfAbsent(question.id, () => question);
      }
    }

    final questions = merged.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));

    return List<Question>.unmodifiable(questions);
  }

  Future<List<Question>> loadForScope({
    required int domain,
    String? competencyId,
    String? topicId,
    String? subtopicId,
    String? quizId,
  }) {
    final explicitCompetency = competencyId?.trim();

    if (explicitCompetency != null && explicitCompetency.isNotEmpty) {
      return loadCompetency(explicitCompetency);
    }

    for (final candidate in <String?>[subtopicId, topicId, quizId]) {
      final mapped = competencyIdFromScopedId(candidate);
      if (mapped != null) {
        return loadCompetency(mapped);
      }
    }

    return loadDomain(domain);
  }

  List<Question> _decodeQuestions(CachedQuestionPackage cached) {
    return _decoder
        .decode(
          descriptor: cached.descriptor,
          compressedBytes: cached.compressedBytes,
        )
        .questions;
  }

  static String? competencyIdFromScopedId(String? value) {
    final normalized = value?.trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final match = RegExp(r'd\d{2}_c\d{2}').firstMatch(normalized);
    if (match == null) {
      return null;
    }

    final competencyId = match.group(0)!;
    return competencyForId(competencyId) == null ? null : competencyId;
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
