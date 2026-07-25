// A request a customer has sent that the tailor hasn't accepted yet.
// CustomOrder in the Prisma schema only starts at OrderStage.ORDER_CONFIRMED
// — there's no "pending tailor approval" row yet, so this whole concept
// (and the accept/decline action) is ahead of what the backend models
// today. UI-only until that's designed (Phase 5+, see docs/ROADMAP.md).
class IncomingRequest {
  const IncomingRequest({
    required this.id,
    required this.customerName,
    required this.garmentType,
    required this.fabric,
    required this.price,
    required this.requestedAt,
  });

  final String id;
  final String customerName;
  final String garmentType;
  final String fabric;
  final double price;
  final DateTime requestedAt;
}
