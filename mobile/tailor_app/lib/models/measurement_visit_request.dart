import 'visit_request_status.dart';

// Mirrors backend/prisma/schema.prisma's MeasurementVisitRequest model.
// `customerName` is only present on the tailor-side endpoints
// (/measurement-visits/available, /assigned) — measurement-visits.service.ts's
// tailorViewInclude nests the customer's name/email/phone there, unlike the
// customer's own GET /measurement-visits/me.
class MeasurementVisitRequest {
  const MeasurementVisitRequest({
    required this.id,
    required this.location,
    required this.preferredAt,
    required this.status,
    this.notes,
    this.customerName,
    this.customerPhone,
  });

  factory MeasurementVisitRequest.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return MeasurementVisitRequest(
      id: json['id'] as String,
      location: json['location'] as String,
      preferredAt: DateTime.parse(json['preferredAt'] as String),
      status: VisitRequestStatusX.fromJson(json['status'] as String),
      notes: json['notes'] as String?,
      customerName: customer?['fullName'] as String?,
      customerPhone: customer?['phone'] as String?,
    );
  }

  final String id;
  final String location;
  final DateTime preferredAt;
  final VisitRequestStatus status;
  final String? notes;
  final String? customerName;
  final String? customerPhone;
}
