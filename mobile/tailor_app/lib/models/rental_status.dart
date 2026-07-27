import 'package:flutter/material.dart';

// Mirrors backend/prisma/schema.prisma's RentalStatus enum exactly.
enum RentalStatus { reserved, pickedUp, returned, late, cancelled }

extension RentalStatusX on RentalStatus {
  static RentalStatus fromJson(String value) => switch (value) {
    'RESERVED' => RentalStatus.reserved,
    'PICKED_UP' => RentalStatus.pickedUp,
    'RETURNED' => RentalStatus.returned,
    'LATE' => RentalStatus.late,
    'CANCELLED' => RentalStatus.cancelled,
    _ => throw ArgumentError('Unknown RentalStatus: $value'),
  };

  String get label => switch (this) {
    RentalStatus.reserved => 'Reserved',
    RentalStatus.pickedUp => 'Picked Up',
    RentalStatus.returned => 'Returned',
    RentalStatus.late => 'Late',
    RentalStatus.cancelled => 'Cancelled',
  };

  Color get color => switch (this) {
    RentalStatus.reserved => const Color(0xFF8A6244),
    RentalStatus.pickedUp => const Color(0xFFC7A363),
    RentalStatus.returned => const Color(0xFF3F7D4A),
    RentalStatus.late => const Color(0xFFB3452C),
    RentalStatus.cancelled => const Color(0xFF7A6F68),
  };
}
