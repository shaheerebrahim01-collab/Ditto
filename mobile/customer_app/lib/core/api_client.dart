import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/rental_booking.dart';
import '../models/rental_shop.dart';
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

  // GET /rental-shops — public browse, approved shops only, server-side
  // search + pagination (mirrors admin's listTailors pattern).
  Future<({List<RentalShop> data, int total, int page, int pageSize})> listRentalShops({
    String? q,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = {
      'page': '$page',
      'pageSize': '$pageSize',
      if (q != null && q.isNotEmpty) 'q': q,
    };
    final response = await _http.get(_uri('/rental-shops').replace(queryParameters: query));
    final body = _decode(response);
    return (
      data: (body['data'] as List<dynamic>)
          .map((e) => RentalShop.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: body['total'] as int,
      page: body['page'] as int,
      pageSize: body['pageSize'] as int,
    );
  }

  // GET /rental-shops/:id — public shop detail, includes its items.
  Future<RentalShop> getRentalShop(String id) async {
    final response = await _http.get(_uri('/rental-shops/$id'));
    return RentalShop.fromJson(_decode(response));
  }

  // POST /rentals — book an item for a date range.
  Future<RentalBooking> createRentalBooking(
    String accessToken, {
    required String itemId,
    required DateTime pickupDate,
    required DateTime returnDate,
  }) async {
    final response = await _http.post(
      _uri('/rentals'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        'itemId': itemId,
        'pickupDate': pickupDate.toIso8601String(),
        'returnDate': returnDate.toIso8601String(),
      }),
    );
    return RentalBooking.fromJson(_decode(response));
  }

  // GET /rentals/me — the signed-in renter's own bookings.
  Future<List<RentalBooking>> getMyRentalBookings(String accessToken) async {
    final response = await _http.get(
      _uri('/rentals/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response).map((e) => RentalBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST /rentals/:id/cancel — only works from RESERVED, enforced server-side.
  Future<RentalBooking> cancelRentalBooking(String accessToken, String id) async {
    final response = await _http.post(
      _uri('/rentals/$id/cancel'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return RentalBooking.fromJson(_decode(response));
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as List<dynamic>;
  }
}
