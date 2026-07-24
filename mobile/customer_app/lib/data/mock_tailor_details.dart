import '../models/tailor_detail.dart';

// Keyed by the same ids used in mock_tailors.dart.
const mockTailorDetails = <String, TailorDetail>{
  't1': TailorDetail(
    id: 't1',
    businessName: 'Al-Karam Tailors',
    specialties: ['Suits', 'Sherwanis'],
    ratingAvg: 4.8,
    ratingCount: 132,
    bio: 'Three generations of bespoke tailoring, specializing in suits and '
        'wedding sherwanis with a two-week turnaround.',
    workingHours: [
      WorkingHoursEntry(days: 'Mon – Fri', hours: '9:00 AM – 7:00 PM'),
      WorkingHoursEntry(days: 'Saturday', hours: '10:00 AM – 5:00 PM'),
      WorkingHoursEntry(days: 'Sunday', hours: 'Closed'),
    ],
    portfolio: [
      PortfolioItem(category: 'Suits'),
      PortfolioItem(category: 'Sherwanis'),
      PortfolioItem(category: 'Suits'),
      PortfolioItem(category: 'Sherwanis'),
    ],
  ),
  't2': TailorDetail(
    id: 't2',
    businessName: 'Rehman Stitching House',
    specialties: ['Alterations', 'Casual Wear'],
    ratingAvg: 4.6,
    ratingCount: 87,
    bio: 'Fast, precise alterations and everyday casual wear tailoring — '
        'most orders ready within 48 hours.',
    workingHours: [
      WorkingHoursEntry(days: 'Mon – Sat', hours: '10:00 AM – 8:00 PM'),
      WorkingHoursEntry(days: 'Sunday', hours: '12:00 PM – 4:00 PM'),
    ],
    portfolio: [
      PortfolioItem(category: 'Casual Wear'),
      PortfolioItem(category: 'Alterations'),
      PortfolioItem(category: 'Casual Wear'),
    ],
  ),
  't3': TailorDetail(
    id: 't3',
    businessName: 'Zaman Bespoke',
    specialties: ['Suits'],
    ratingAvg: 4.9,
    ratingCount: 204,
    bio: 'Luxury bespoke suits, hand-finished with imported fabric. '
        'By appointment.',
    workingHours: [
      WorkingHoursEntry(days: 'Tue – Sat', hours: '11:00 AM – 6:00 PM'),
      WorkingHoursEntry(days: 'Sun – Mon', hours: 'Closed'),
    ],
    portfolio: [
      PortfolioItem(category: 'Suits'),
      PortfolioItem(category: 'Suits'),
      PortfolioItem(category: 'Suits'),
      PortfolioItem(category: 'Suits'),
      PortfolioItem(category: 'Suits'),
    ],
  ),
  't4': TailorDetail(
    id: 't4',
    businessName: 'Heritage Sherwani Co.',
    specialties: ['Sherwanis', 'Rentals'],
    ratingAvg: 4.7,
    ratingCount: 156,
    bio: 'Hand-embroidered sherwanis for weddings, available to buy or rent.',
    workingHours: [
      WorkingHoursEntry(days: 'Mon – Sun', hours: '10:00 AM – 8:00 PM'),
    ],
    portfolio: [
      PortfolioItem(category: 'Sherwanis'),
      PortfolioItem(category: 'Rentals'),
      PortfolioItem(category: 'Sherwanis'),
    ],
  ),
  't5': TailorDetail(
    id: 't5',
    businessName: 'Modern Cuts',
    specialties: ['Casual Wear', 'Alterations'],
    ratingAvg: 4.5,
    ratingCount: 61,
    bio: 'Contemporary casual wear with a quick, budget-friendly turnaround.',
    workingHours: [
      WorkingHoursEntry(days: 'Mon – Sat', hours: '9:00 AM – 6:00 PM'),
      WorkingHoursEntry(days: 'Sunday', hours: 'Closed'),
    ],
    portfolio: [
      PortfolioItem(category: 'Casual Wear'),
      PortfolioItem(category: 'Alterations'),
    ],
  ),
};
