import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../models/conversation_summary.dart';
import '../models/measurement.dart';
import '../models/measurement_visit_request.dart';
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

  // GET /measurements — the signed-in user's own saved measurements.
  Future<List<Measurement>> listMeasurements(String accessToken) async {
    final response = await _http.get(
      _uri('/measurements'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response).map((e) => Measurement.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST /measurements — every field but label is optional, matching the schema.
  Future<Measurement> createMeasurement(
    String accessToken, {
    String? label,
    double? chest,
    double? waist,
    double? hip,
    double? shoulder,
    double? sleeve,
    double? neck,
    double? inseam,
    String? notes,
  }) async {
    final response = await _http.post(
      _uri('/measurements'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        if (label != null) 'label': label,
        if (chest != null) 'chest': chest,
        if (waist != null) 'waist': waist,
        if (hip != null) 'hip': hip,
        if (shoulder != null) 'shoulder': shoulder,
        if (sleeve != null) 'sleeve': sleeve,
        if (neck != null) 'neck': neck,
        if (inseam != null) 'inseam': inseam,
        if (notes != null) 'notes': notes,
      }),
    );
    return Measurement.fromJson(_decode(response));
  }

  // PATCH /measurements/:id — partial update, only non-null fields sent.
  Future<Measurement> updateMeasurement(
    String accessToken,
    String id, {
    String? label,
    double? chest,
    double? waist,
    double? hip,
    double? shoulder,
    double? sleeve,
    double? neck,
    double? inseam,
    String? notes,
  }) async {
    final response = await _http.patch(
      _uri('/measurements/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        if (label != null) 'label': label,
        if (chest != null) 'chest': chest,
        if (waist != null) 'waist': waist,
        if (hip != null) 'hip': hip,
        if (shoulder != null) 'shoulder': shoulder,
        if (sleeve != null) 'sleeve': sleeve,
        if (neck != null) 'neck': neck,
        if (inseam != null) 'inseam': inseam,
        if (notes != null) 'notes': notes,
      }),
    );
    return Measurement.fromJson(_decode(response));
  }

  // DELETE /measurements/:id — 409s server-side if a CustomOrder references it.
  Future<void> deleteMeasurement(String accessToken, String id) async {
    final response = await _http.delete(
      _uri('/measurements/$id'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    _decode(response);
  }

  // POST /measurement-visits — request an in-person measurement visit.
  Future<MeasurementVisitRequest> createVisitRequest(
    String accessToken, {
    required String location,
    required DateTime preferredAt,
    String? notes,
  }) async {
    final response = await _http.post(
      _uri('/measurement-visits'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({
        'location': location,
        'preferredAt': preferredAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      }),
    );
    return MeasurementVisitRequest.fromJson(_decode(response));
  }

  // GET /measurement-visits/me — the signed-in customer's own requests.
  Future<List<MeasurementVisitRequest>> listMyVisitRequests(String accessToken) async {
    final response = await _http.get(
      _uri('/measurement-visits/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(
      response,
    ).map((e) => MeasurementVisitRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST /measurement-visits/:id/cancel — only works from PENDING/ASSIGNED,
  // enforced server-side.
  Future<MeasurementVisitRequest> cancelVisitRequest(String accessToken, String id) async {
    final response = await _http.post(
      _uri('/measurement-visits/$id/cancel'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return MeasurementVisitRequest.fromJson(_decode(response));
  }

  // POST /conversations — find-or-create the thread with otherUserId.
  // Returns just the id; the caller already knows who they're messaging
  // (the screen that triggered this already has the other participant's
  // name/role on hand), so there's no need to round-trip that back out.
  Future<String> startConversation(String accessToken, String otherUserId) async {
    final response = await _http.post(
      _uri('/conversations'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'otherUserId': otherUserId}),
    );
    return _decode(response)['id'] as String;
  }

  // GET /conversations — the signed-in user's own threads, newest-active first.
  Future<List<ConversationSummary>> listConversations(String accessToken) async {
    final response = await _http.get(
      _uri('/conversations'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(
      response,
    ).map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /conversations/:id/messages — newest first, matching every other
  // paginated list in this app.
  Future<List<ChatMessage>> listMessages(String accessToken, String conversationId) async {
    final response = await _http.get(
      _uri('/conversations/$conversationId/messages'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final body = _decode(response);
    return (body['data'] as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /conversations/:id/messages — text only for now; attachmentUrl/Type
  // exist server-side but there's no upload flow wired to any screen yet.
  Future<ChatMessage> sendMessage(String accessToken, String conversationId, String body) async {
    final response = await _http.post(
      _uri('/conversations/$conversationId/messages'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'body': body}),
    );
    return ChatMessage.fromJson(_decode(response));
  }

  // POST /conversations/:id/read — marks the other participant's messages
  // read; called when a chat thread opens.
  Future<void> markConversationRead(String accessToken, String conversationId) async {
    final response = await _http.post(
      _uri('/conversations/$conversationId/read'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    _decode(response);
  }

  // GET /notifications
  Future<List<AppNotification>> listNotifications(String accessToken) async {
    final response = await _http.get(
      _uri('/notifications'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final body = _decode(response);
    return (body['data'] as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /notifications/unread-count — used for the bell-icon badge.
  Future<int> unreadNotificationCount(String accessToken) async {
    final response = await _http.get(
      _uri('/notifications/unread-count'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decode(response)['count'] as int;
  }

  // POST /notifications/:id/read
  Future<void> markNotificationRead(String accessToken, String id) async {
    final response = await _http.post(
      _uri('/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    _decode(response);
  }

  // POST /notifications/read-all
  Future<void> markAllNotificationsRead(String accessToken) async {
    final response = await _http.post(
      _uri('/notifications/read-all'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    _decode(response);
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
