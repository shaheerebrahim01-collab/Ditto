import 'visit_request_status.dart';

// Mirrors backend/prisma/schema.prisma's MeasurementVisitRequest model.
class MeasurementVisitRequest {
  const MeasurementVisitRequest({
    required this.id,
    required this.location,
    required this.preferredAt,
    required this.status,
    this.notes,
  });

  factory MeasurementVisitRequest.fromJson(Map<String, dynamic> json) => MeasurementVisitRequest(
    id: json['id'] as String,
    location: json['location'] as String,
    preferredAt: DateTime.parse(json['preferredAt'] as String),
    status: VisitRequestStatusX.fromJson(json['status'] as String),
    notes: json['notes'] as String?,
  );

  final String id;
  final String location;
  final DateTime preferredAt;
  final VisitRequestStatus status;
  final String? notes;
}
