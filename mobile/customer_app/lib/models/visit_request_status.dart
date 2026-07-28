import 'package:flutter/material.dart';

// Mirrors backend/prisma/schema.prisma's VisitRequestStatus enum exactly.
enum VisitRequestStatus { pending, assigned, completed, cancelled }

extension VisitRequestStatusX on VisitRequestStatus {
  static VisitRequestStatus fromJson(String value) => switch (value) {
    'PENDING' => VisitRequestStatus.pending,
    'ASSIGNED' => VisitRequestStatus.assigned,
    'COMPLETED' => VisitRequestStatus.completed,
    'CANCELLED' => VisitRequestStatus.cancelled,
    _ => throw ArgumentError('Unknown VisitRequestStatus: $value'),
  };

  String get label => switch (this) {
    VisitRequestStatus.pending => 'Pending',
    VisitRequestStatus.assigned => 'Assigned',
    VisitRequestStatus.completed => 'Completed',
    VisitRequestStatus.cancelled => 'Cancelled',
  };

  Color get color => switch (this) {
    VisitRequestStatus.pending => const Color(0xFF8A6244),
    VisitRequestStatus.assigned => const Color(0xFFC7A363),
    VisitRequestStatus.completed => const Color(0xFF3F7D4A),
    VisitRequestStatus.cancelled => const Color(0xFF7A6F68),
  };
}
