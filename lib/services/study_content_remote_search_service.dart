import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/learner_local_identity.dart';
import 'online_access/firebase_learner_access_token_provider.dart';
import 'online_access/learner_online_access_runtime.dart';
import 'study_content_search_service.dart';
import 'supabase/supabase_bootstrap_service.dart';

class RemoteStudyContentSearchService extends StudyContentSearchService {
  RemoteStudyContentSearchService({
    SupabaseClient? client,
    FirebaseLearnerAccessTokenProvider? tokenProvider,
  }) : _client = client,
       _tokenProvider = tokenProvider ?? FirebaseLearnerAccessTokenProvider(),
       super(loadPublishedContent: () async => const []);

  static const _requestTimeout = Duration(seconds: 8);
  static const _cacheTtl = Duration(minutes: 2);
  static const _maxCacheEntries = 24;

  final SupabaseClient? _client;
  final FirebaseLearnerAccessTokenProvider _tokenProvider;
  final LinkedHashMap<String, _CachedRemoteSearch> _cache = LinkedHashMap();
  final Map<String, Future<List<StudyContentSearchResult>>> _inFlight = {};

  SupabaseClient get _resolvedClient {
    if (!SupabaseBootstrapService.isInitialized) {
      throw StateError(
        'Supabase is not configured for protected learner content search.',
      );
    }

    return _client ?? Supabase.instance.client;
  }

  @override
  Future<List<StudyContentSearchResult>> search(
    String rawQuery, {
    int limit = 8,
  }) async {
    final query = _normalizeQuery(rawQuery);
    if (query.length < 2 || limit <= 0) {
      return const <StudyContentSearchResult>[];
    }

    final userId = LearnerLocalIdentity.requireCurrentUserId();
    _requireAuthorizedUser(userId);

    final effectiveLimit = limit.clamp(1, 20).toInt();
    final cacheKey = '$userId|${query.toLowerCase()}|$effectiveLimit';
    final now = DateTime.now();
    final cached = _cache[cacheKey];

    if (cached != null && now.difference(cached.createdAt) <= _cacheTtl) {
      _cache
        ..remove(cacheKey)
        ..[cacheKey] = cached;
      return cached.results;
    }

    if (cached != null) {
      _cache.remove(cacheKey);
    }

    final existingRequest = _inFlight[cacheKey];
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _performSearch(query, userId: userId, limit: effectiveLimit)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            'Protected learner content search timed out.',
            _requestTimeout,
          ),
        );

    _inFlight[cacheKey] = request;

    try {
      final results = await request;
      _requireSameAuthorizedUser(userId);
      _cache[cacheKey] = _CachedRemoteSearch(
        createdAt: DateTime.now(),
        results: results,
      );
      while (_cache.length > _maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      return results;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  Future<List<StudyContentSearchResult>> _performSearch(
    String query, {
    required String userId,
    required int limit,
  }) async {
    _requireSameAuthorizedUser(userId);

    final token = await _tokenProvider.currentToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError(
        'A current Firebase ID token is required for protected learner search.',
      );
    }

    _requireSameAuthorizedUser(userId);

    final response = await _resolvedClient.functions.invoke(
      'learner-content-search',
      body: <String, dynamic>{'query': query, 'limit': limit},
      headers: <String, String>{'Authorization': 'Bearer ${token.trim()}'},
    );

    _requireSameAuthorizedUser(userId);

    final data = _responseMap(response.data);
    final rawResults = data['results'];
    if (rawResults is! List) {
      throw const FormatException(
        'Learner content search response must contain a results list.',
      );
    }

    final results = rawResults
        .map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Learner content search result must be an object.',
            );
          }
          final json = Map<String, dynamic>.from(raw);
          final domainId = _requiredString(json, 'domainId').toLowerCase();
          final competencyId = _requiredString(
            json,
            'competencyId',
          ).toLowerCase();
          final topicId = _requiredString(json, 'topicId').toLowerCase();
          final subtopicId = _requiredString(json, 'subtopicId').toLowerCase();

          if (!RegExp(r'^d\d{2}$').hasMatch(domainId) ||
              !RegExp(r'^d\d{2}_c\d{2}$').hasMatch(competencyId) ||
              !RegExp(r'^d\d{2}_c\d{2}_t\d{2}$').hasMatch(topicId) ||
              !RegExp(r'^d\d{2}_c\d{2}_t\d{2}_s\d{2}$').hasMatch(subtopicId) ||
              !topicId.startsWith('${competencyId}_t') ||
              !subtopicId.startsWith('${topicId}_s')) {
            throw const FormatException(
              'Learner content search result contains invalid route identity.',
            );
          }

          return StudyContentSearchResult(
            domainId: domainId,
            domainLabel: domainId.toUpperCase(),
            domainTitle: _requiredString(json, 'domainTitle'),
            competencyId: competencyId,
            competencyTitle: _requiredString(json, 'competencyTitle'),
            topicId: topicId,
            topicTitle: _requiredString(json, 'topicTitle'),
            subtopicId: subtopicId,
            subtopicTitle: _requiredString(json, 'subtopicTitle'),
            matchSection: _requiredString(json, 'matchSection'),
            snippet: _requiredString(json, 'snippet'),
            score: _requiredInt(json, 'score'),
          );
        })
        .toList(growable: false);

    if (results.length > limit) {
      throw const FormatException(
        'Learner content search returned more results than requested.',
      );
    }

    return List<StudyContentSearchResult>.unmodifiable(results);
  }

  void _requireAuthorizedUser(String userId) {
    final boundary = LearnerOnlineAccessRuntime.requireBoundaryFor(userId);
    if (!boundary.isAuthorizedFor(userId)) {
      throw StateError(
        'Protected learner search is locked until online authorization succeeds.',
      );
    }
  }

  void _requireSameAuthorizedUser(String expectedUserId) {
    final currentUserId = LearnerLocalIdentity.requireCurrentUserId();
    if (currentUserId != expectedUserId) {
      throw StateError('Learner identity changed during protected search.');
    }
    _requireAuthorizedUser(expectedUserId);
  }

  static String _normalizeQuery(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
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
      'Learner content search response must be a JSON object.',
    );
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field]?.toString().trim() ?? '';
    if (value.isEmpty) {
      throw FormatException('Learner content search field "$field" is empty.');
    }
    return value;
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    final parsed = value is int
        ? value
        : value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException(
        'Learner content search field "$field" is not an integer.',
      );
    }
    return parsed;
  }
}

class _CachedRemoteSearch {
  const _CachedRemoteSearch({required this.createdAt, required this.results});

  final DateTime createdAt;
  final List<StudyContentSearchResult> results;
}
