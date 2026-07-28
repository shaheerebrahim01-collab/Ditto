// Kept in sync by hand with mobile/customer_app/lib/data/garment_builder_options.dart
// — the Create flow's fixed vocabulary. A styling recommendation is only
// useful if it's actually orderable, so the model is constrained (via the
// tool's input_schema enums) to pick from these exact values, never invent
// a garment type, fabric, lapel, or button style that doesn't exist.
export const GARMENT_TYPE_IDS = [
  'suit',
  'sherwani',
  'kurta',
  'waistcoat',
  'trousers',
  'blazer',
  'shirt',
  'tuxedo',
] as const;

export const FABRIC_IDS = [
  'charcoal_wool',
  'navy_twill',
  'ivory_linen',
  'slate_grey',
  'beige_cotton',
  'burgundy_silk',
  'midnight_velvet',
  'herringbone_black',
] as const;

export const LAPEL_STYLES = ['Notch', 'Peak', 'Shawl'] as const;

export const BUTTON_STYLES = ['2-Button', '3-Button', 'Double-Breasted'] as const;
