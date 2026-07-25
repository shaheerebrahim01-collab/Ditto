import '../models/incoming_request.dart';
import '../models/portfolio_item.dart';
import '../models/tailor_order.dart';

// Placeholder data until the tailor-facing endpoints exist (Phase 5+).
const mockRatingAvg = 4.8;
const mockRatingCount = 132;
const mockTodayIncome = 340.0;
const mockWeekIncome = 1860.0;

final mockTodaysOrders = [
  TailorOrder(
    id: 'to1',
    customerName: 'Bilal Ahmed',
    garmentType: 'Suit',
    price: 265,
    stage: OrderStage.stitching,
    dueDate: DateTime(2026, 7, 25),
  ),
  TailorOrder(
    id: 'to2',
    customerName: 'Sara Khan',
    garmentType: 'Sherwani',
    price: 335,
    stage: OrderStage.qualityCheck,
    dueDate: DateTime(2026, 7, 25),
  ),
  TailorOrder(
    id: 'to3',
    customerName: 'Usman Tariq',
    garmentType: 'Waistcoat',
    price: 85,
    stage: OrderStage.cutting,
    dueDate: DateTime(2026, 7, 26),
  ),
];

final mockIncomingRequests = [
  IncomingRequest(
    id: 'r1',
    customerName: 'Ayesha Malik',
    garmentType: 'Kurta',
    fabric: 'Ivory Linen',
    price: 110,
    requestedAt: DateTime(2026, 7, 24, 9, 15),
  ),
  IncomingRequest(
    id: 'r2',
    customerName: 'Hassan Raza',
    garmentType: 'Tuxedo',
    fabric: 'Midnight Velvet',
    price: 455,
    requestedAt: DateTime(2026, 7, 24, 11, 40),
  ),
];

final mockActiveOrders = [
  TailorOrder(
    id: 'ao1',
    customerName: 'Fatima Sheikh',
    garmentType: 'Blazer',
    price: 195,
    stage: OrderStage.fabricSelected,
    dueDate: DateTime(2026, 8, 2),
  ),
  TailorOrder(
    id: 'ao2',
    customerName: 'Zeeshan Iqbal',
    garmentType: 'Suit',
    price: 275,
    stage: OrderStage.embroidery,
    dueDate: DateTime(2026, 7, 30),
  ),
];

const mockPortfolio = [
  PortfolioItem(id: 'p1', category: 'Suits'),
  PortfolioItem(id: 'p2', category: 'Sherwanis'),
  PortfolioItem(id: 'p3', category: 'Suits'),
  PortfolioItem(id: 'p4', category: 'Waistcoats'),
];
