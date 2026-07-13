import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/token_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  ApiClient._();

  static String get baseUrl => AppConfig().baseUrl;
  static final http.Client _client = http.Client();

  static Completer<void>? _refreshCompleter;

  static Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _send('GET', path, headers: headers);
  }

  static Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _send('POST', path, headers: headers, body: body);
  }

  static Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    return _send(
      'DELETE',
      path,
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  static Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
    bool retried = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    final mergedHeaders = <String, String>{
      if (headers != null) ...headers,
    };

    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      mergedHeaders['Authorization'] = 'Bearer $accessToken';
    }

    http.Response response;
    if (method == 'GET') {
      response = await _client.get(uri, headers: mergedHeaders);
    } else if (method == 'POST') {
      response = await _client.post(uri, headers: mergedHeaders, body: body);
    } else if (method == 'DELETE') {
      response = await _client.delete(uri, headers: mergedHeaders);
    } else {
      throw UnsupportedError('HTTP method not supported: $method');
    }

    if (response.statusCode != 401 || retried) {
      return response;
    }

    await _refreshAccessTokenOrThrow();

    final refreshedHeaders = <String, String>{
      if (headers != null) ...headers,
    };
    final newAccessToken = await TokenStorage.getAccessToken();
    if (newAccessToken != null && newAccessToken.isNotEmpty) {
      refreshedHeaders['Authorization'] = 'Bearer $newAccessToken';
    }

    if (method == 'GET') {
      return _client.get(uri, headers: refreshedHeaders);
    } else if (method == 'DELETE') {
      return _client.delete(uri, headers: refreshedHeaders);
    }
    return _client.post(uri, headers: refreshedHeaders, body: body);
  }

  static Future<void> _refreshAccessTokenOrThrow() async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('SESSION_EXPIRED');
      }
      return;
    }

    _refreshCompleter = Completer<void>();
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await TokenStorage.clearAllTokens();
        throw Exception('SESSION_EXPIRED');
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh/'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode != 200) {
        await TokenStorage.clearAllTokens();
        throw Exception('SESSION_EXPIRED');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        await TokenStorage.clearAllTokens();
        throw Exception('SESSION_EXPIRED');
      }

      final accessToken = decoded['access_token']?.toString() ?? '';
      final newRefreshToken = decoded['refresh_token']?.toString() ?? '';
      if (accessToken.isEmpty || newRefreshToken.isEmpty) {
        await TokenStorage.clearAllTokens();
        throw Exception('SESSION_EXPIRED');
      }

      await TokenStorage.setAccessToken(accessToken);
      await TokenStorage.setRefreshToken(newRefreshToken);
    } finally {
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }
}

