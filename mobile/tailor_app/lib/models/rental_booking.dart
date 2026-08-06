import 'rental_item.dart';
import 'rental_status.dart';

// Only present on shop-side bookings (GET /rentals/shop) — mirrors
// RentalsService.listShopBookings's `renter: { select: {...} }` include.
class BookingRenter {
  const BookingRenter({required this.fullName, this.email, this.phone});

  factory BookingRenter.fromJson(Map<String, dynamic> json) => BookingRenter(
    fullName: json['fullName'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
  );

  final String fullName;
  final String? email;
  final String? phone;
}

// Mirrors backend/prisma/schema.prisma's RentalBooking model. `renter` and
// `overdue` are only populated on shop-side responses (GET /rentals/shop) —
// renter-side responses (GET /rentals/me) omit both.
class RentalBooking {
  const RentalBooking({
    required this.id,
    required this.itemId,
    required this.renterId,
    required this.pickupDate,
    required this.returnDate,
    required this.status,
    required this.lateFee,
    required this.item,
    this.renter,
    this.overdue = false,
  });

  factory RentalBooking.fromJson(Map<String, dynamic> json) {
    return RentalBooking(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      renterId: json['renterId'] as String,
      pickupDate: DateTime.parse(json['pickupDate'] as String),
      returnDate: DateTime.parse(json['returnDate'] as String),
      status: RentalStatusX.fromJson(json['status'] as String),
      lateFee: (json['lateFee'] as num).toDouble(),
      item: RentalItem.fromJson(json['item'] as Map<String, dynamic>),
      renter: json['renter'] != null ? BookingRenter.fromJson(json['renter'] as Map<String, dynamic>) : null,
      overdue: json['overdue'] as bool? ?? false,
    );
  }

  final String id;
  final String itemId;
  // Always present on the raw response (Prisma scalar) even though `renter`
  // (name/email/phone) is only populated on shop-side responses — used to
  // start a conversation with the renter.
  final String renterId;
  final DateTime pickupDate;
  final DateTime returnDate;
  final RentalStatus status;
  final double lateFee;
  final RentalItem item;
  final BookingRenter? renter;
  final bool overdue;
}
