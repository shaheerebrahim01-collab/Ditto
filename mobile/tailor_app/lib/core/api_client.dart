import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/rental_booking.dart';
import '../models/rental_item.dart';
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

  // GET /rental-shops/me — the signed-in shop owner's own profile.
  Future<RentalShop> getMyRentalShop(String accessToken) async {
    final response = await _http.get(
      _uri('/rental-shops/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return RentalShop.fromJson(_decode(response));
  }

  // PATCH /rental-shops/me — only businessName is editable, per the schema.
  Future<RentalShop> updateMyRentalShop(String accessToken, {required String businessName}) async {
    final response = await _http.patch(
      _uri('/rental-shops/me'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'businessName': businessName}),
    );
    return RentalShop.fromJson(_decode(response));
  }

  // GET /rental-shops/me/items — this shop's inventory.
  Future<List<RentalItem>> listMyRentalItems(String accessToken) async {
    final response = await _http.get(
      _uri('/rental-shops/me/items'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response).map((e) => RentalItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST /rental-shops/me/items — add an item to this shop's inventory.
  Future<RentalItem> createRentalItem(
    String accessToken, {
    required String name,
    required String category,
    required double pricePerDay,
    required double depositAmount,
    String? imageUrl,
  }) async {
    final response = await _http.post(
      _uri('/rental-shops/me/items'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        'name': name,
        'category': category,
        'pricePerDay': pricePerDay,
        'depositAmount': depositAmount,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }),
    );
    return RentalItem.fromJson(_decode(response));
  }

  // PATCH /rental-shops/me/items/:id — partial update, only non-null fields sent.
  Future<RentalItem> updateRentalItem(
    String accessToken,
    String itemId, {
    String? name,
    String? category,
    double? pricePerDay,
    double? depositAmount,
    String? imageUrl,
  }) async {
    final response = await _http.patch(
      _uri('/rental-shops/me/items/$itemId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (pricePerDay != null) 'pricePerDay': pricePerDay,
        if (depositAmount != null) 'depositAmount': depositAmount,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }),
    );
    return RentalItem.fromJson(_decode(response));
  }

  // DELETE /rental-shops/me/items/:id — 409s server-side if the item has
  // bookings against it (Prisma FK constraint, caught in RentalShopsService).
  Future<void> deleteRentalItem(String accessToken, String itemId) async {
    final response = await _http.delete(
      _uri('/rental-shops/me/items/$itemId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    _decode(response);
  }

  // GET /rentals/shop — this shop's bookings, optionally filtered by status.
  Future<List<RentalBooking>> listShopBookings(String accessToken, {String? status}) async {
    final uri = status != null
        ? _uri('/rentals/shop').replace(queryParameters: {'status': status})
        : _uri('/rentals/shop');
    final response = await _http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
    return _decodeList(response).map((e) => RentalBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST /rentals/:id/pickup — only works from RESERVED, enforced server-side.
  Future<RentalBooking> markRentalPickedUp(String accessToken, String id) async {
    final response = await _http.post(
      _uri('/rentals/$id/pickup'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return RentalBooking.fromJson(_decode(response));
  }

  // POST /rentals/:id/return — only works from PICKED_UP; server computes
  // any late fee.
  Future<RentalBooking> markRentalReturned(String accessToken, String id) async {
    final response = await _http.post(
      _uri('/rentals/$id/return'),
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
