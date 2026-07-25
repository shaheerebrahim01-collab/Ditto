// The Prisma schema's Payment model is a per-order transaction record, not a
// saved card — there's no "saved payment method" model yet. This is a
// UI-only placeholder until that exists.
class SavedPaymentMethod {
  const SavedPaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
  });

  final String id;
  final String brand;
  final String last4;
  final String expiry;
}
