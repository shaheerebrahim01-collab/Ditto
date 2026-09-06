import { PrismaService } from '../../src/prisma/prisma.service';

let counter = 0;
// Unique per test run and per call within a run — avoids collisions with
// the unique constraints on User.email/phone without needing a real
// random-id library.
function unique(label: string): string {
  counter += 1;
  return `e2e-${label}-${Date.now()}-${counter}`;
}

export async function createCustomer(prisma: PrismaService) {
  return prisma.user.create({
    data: { fullName: 'E2E Customer', email: `${unique('cust')}@test.dev`, authProvider: 'test', role: 'CUSTOMER' },
  });
}

export async function createAdmin(prisma: PrismaService) {
  return prisma.user.create({
    data: { fullName: 'E2E Admin', email: `${unique('admin')}@test.dev`, authProvider: 'test', role: 'ADMIN' },
  });
}

export async function createTailor(prisma: PrismaService, opts: { status?: 'PENDING' | 'APPROVED' } = {}) {
  const user = await prisma.user.create({
    data: { fullName: 'E2E Tailor', email: `${unique('tailor')}@test.dev`, authProvider: 'test', role: 'TAILOR' },
  });
  const profile = await prisma.tailorProfile.create({
    data: { userId: user.id, businessName: 'E2E Tailor Shop', status: opts.status ?? 'APPROVED' },
  });
  return { user, profile };
}

export async function createRentalShop(prisma: PrismaService, opts: { status?: 'PENDING' | 'APPROVED' } = {}) {
  const user = await prisma.user.create({
    data: { fullName: 'E2E Rental Shop', email: `${unique('shop')}@test.dev`, authProvider: 'test', role: 'RENTAL_SHOP' },
  });
  const profile = await prisma.rentalShopProfile.create({
    data: { userId: user.id, businessName: 'E2E Rental Shop Biz', status: opts.status ?? 'APPROVED' },
  });
  return { user, profile };
}

// Deletes everything a set of test users could possibly own, in FK-safe
// order — same shape of cleanup used throughout this project's manual
// curl verification, now reusable across every e2e spec instead of
// hand-written per session.
export async function cleanupUsers(prisma: PrismaService, userIds: string[]) {
  if (userIds.length === 0) return;
  const ids = { in: userIds };

  const conversations = await prisma.conversation.findMany({
    where: { OR: [{ userAId: ids }, { userBId: ids }] },
    select: { id: true },
  });
  const conversationIds = conversations.map((c) => c.id);

  await prisma.message.deleteMany({ where: { conversationId: { in: conversationIds } } });
  await prisma.conversation.deleteMany({ where: { id: { in: conversationIds } } });
  await prisma.notification.deleteMany({ where: { userId: ids } });

  const orders = await prisma.customOrder.findMany({ where: { customerId: ids }, select: { id: true } });
  const orderIds = orders.map((o) => o.id);
  await prisma.review.deleteMany({ where: { OR: [{ authorId: ids }, { orderId: { in: orderIds } }] } });
  await prisma.payment.deleteMany({ where: { orderId: { in: orderIds } } });
  await prisma.customOrder.deleteMany({ where: { customerId: ids } });

  const bookings = await prisma.rentalBooking.findMany({ where: { renterId: ids }, select: { id: true } });
  await prisma.payment.deleteMany({ where: { rentalBookingId: { in: bookings.map((b) => b.id) } } });
  await prisma.rentalBooking.deleteMany({ where: { renterId: ids } });

  await prisma.measurementVisitRequest.deleteMany({ where: { customerId: ids } });
  await prisma.measurement.deleteMany({ where: { userId: ids } });
  await prisma.businessApplication.deleteMany({ where: { applicantId: ids } });

  const shops = await prisma.rentalShopProfile.findMany({ where: { userId: ids }, select: { id: true } });
  const shopIds = shops.map((s) => s.id);
  await prisma.rentalItem.deleteMany({ where: { shopId: { in: shopIds } } });
  await prisma.rentalShopProfile.deleteMany({ where: { userId: ids } });

  const tailors = await prisma.tailorProfile.findMany({ where: { userId: ids }, select: { id: true } });
  const tailorIds = tailors.map((t) => t.id);
  await prisma.tailorAssistant.deleteMany({ where: { tailorId: { in: tailorIds } } });
  await prisma.tailorProfile.deleteMany({ where: { userId: ids } });
  await prisma.user.deleteMany({ where: { id: ids } });
}
