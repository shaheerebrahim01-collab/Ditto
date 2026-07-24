import '../../models/tailor_summary.dart';

// Placeholder data for the Home feed until GET /tailors exists.
const homeCategories = ['All', 'Suits', 'Sherwanis', 'Alterations', 'Rentals', 'Casual Wear'];

const mockTailors = [
  TailorSummary(
    id: 't1',
    businessName: 'Al-Karam Tailors',
    specialties: ['Suits', 'Sherwanis'],
    ratingAvg: 4.8,
    ratingCount: 132,
  ),
  TailorSummary(
    id: 't2',
    businessName: 'Rehman Stitching House',
    specialties: ['Alterations', 'Casual Wear'],
    ratingAvg: 4.6,
    ratingCount: 87,
  ),
  TailorSummary(
    id: 't3',
    businessName: 'Zaman Bespoke',
    specialties: ['Suits'],
    ratingAvg: 4.9,
    ratingCount: 204,
  ),
  TailorSummary(
    id: 't4',
    businessName: 'Heritage Sherwani Co.',
    specialties: ['Sherwanis', 'Rentals'],
    ratingAvg: 4.7,
    ratingCount: 156,
  ),
  TailorSummary(
    id: 't5',
    businessName: 'Modern Cuts',
    specialties: ['Casual Wear', 'Alterations'],
    ratingAvg: 4.5,
    ratingCount: 61,
  ),
];
