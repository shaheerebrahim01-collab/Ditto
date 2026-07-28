import '../models/saved_address.dart';
import '../models/saved_payment_method.dart';
import '../models/wishlist_entry.dart';

const mockAddresses = [
  SavedAddress(id: 'a1', label: 'Home', line1: '221B Baker Street', city: 'Karachi', country: 'Pakistan'),
  SavedAddress(
    id: 'a2',
    label: 'Work',
    line1: '4th Floor, Textile Plaza',
    line2: 'Shahrah-e-Faisal',
    city: 'Karachi',
    country: 'Pakistan',
  ),
];

const mockWishlist = [
  WishlistEntry(id: 'w1', itemType: WishlistItemType.tailor, title: 'Zaman Bespoke', subtitle: 'Suits specialist'),
  WishlistEntry(
    id: 'w2',
    itemType: WishlistItemType.style,
    title: 'Double-Breasted Navy Suit',
    subtitle: 'Saved from Al-Karam Tailors',
  ),
  WishlistEntry(
    id: 'w3',
    itemType: WishlistItemType.rentalItem,
    title: 'Ivory Sherwani — Size L',
    subtitle: 'Available from Heritage Sherwani Co.',
  ),
];

const mockPaymentMethods = [
  SavedPaymentMethod(id: 'p1', brand: 'Visa', last4: '4242', expiry: '09/28'),
  SavedPaymentMethod(id: 'p2', brand: 'Mastercard', last4: '8210', expiry: '02/27'),
];

// Ids into data/mock_tailors.dart.
const favoriteTailorIds = ['t1', 't3'];
