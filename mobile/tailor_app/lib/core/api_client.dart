import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';
import 'env.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// Thin wrapper around the backend HTTP API. Knows nothing about Firebase —
// it only ever sends/receives *our* JWT, matching the split documented in
// backend/src/modules/auth/auth.service.ts.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri _uri(String path) => Uri.parse('${Env.apiBaseUrl}$path');

  // POST /auth/firebase — trades a Firebase ID token for our access token.
  Future<({String accessToken, DittoUser user})> loginWithFirebase(String idToken) async {
    final response = await _http.post(
      _uri('/auth/firebase'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    final body = _decode(response);
    return (
      accessToken: body['accessToken'] as String,
      user: DittoUser.fromJson(body['user'] as Map<String, dynamic>),
    );
  }

  // GET /users/me — requires the JWT from loginWithFirebase, sent as
  // `Authorization: Bearer <token>`.
  Future<DittoUser> getMe(String accessToken) async {
    final response = await _http.get(
      _uri('/users/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return DittoUser.fromJson(_decode(response));
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
