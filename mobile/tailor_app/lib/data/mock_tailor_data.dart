import '../models/portfolio_item.dart';
import '../models/tailor_order.dart';

// Placeholder data until the tailor dashboard stats endpoint exists
// (Phase 5+) — Orders itself is real now (GET /orders/tailor, see
// TailorOrdersScreen), only the Dashboard's "today" summary still renders
// from this.
const mockRatingAvg = 4.8;
const mockRatingCount = 132;
const mockTodayIncome = 340.0;
const mockWeekIncome = 1860.0;

final mockTodaysOrders = [
  TailorOrder(
    id: 'to1',
    customerId: 'mock-customer-1',
    customerName: 'Bilal Ahmed',
    garmentType: 'Suit',
    fabric: 'Charcoal Wool',
    price: 265,
    stage: OrderStage.stitching,
    createdAt: DateTime(2026, 7, 18),
  ),
  TailorOrder(
    id: 'to2',
    customerId: 'mock-customer-2',
    customerName: 'Sara Khan',
    garmentType: 'Sherwani',
    fabric: 'Burgundy Silk',
    price: 335,
    stage: OrderStage.qualityCheck,
    createdAt: DateTime(2026, 7, 12),
  ),
  TailorOrder(
    id: 'to3',
    customerId: 'mock-customer-3',
    customerName: 'Usman Tariq',
    garmentType: 'Waistcoat',
    fabric: 'Slate Grey',
    price: 85,
    stage: OrderStage.cutting,
    createdAt: DateTime(2026, 7, 20),
  ),
];

const mockPortfolio = [
  PortfolioItem(id: 'p1', category: 'Suits'),
  PortfolioItem(id: 'p2', category: 'Sherwanis'),
  PortfolioItem(id: 'p3', category: 'Suits'),
  PortfolioItem(id: 'p4', category: 'Waistcoats'),
];
