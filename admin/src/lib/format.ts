export function initials(name: string): string {
  return name
    .trim()
    .split(/\s+/)
    .map((w) => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();
}

// BusinessApplication.businessType is a free-form string on the backend
// ("tailor" | "rental_shop" | "designer" | "embroidery" per the schema
// comment) — this just maps the known values to the same labels the
// prototype used, and falls back to the raw value for anything else.
const BUSINESS_TYPE_LABELS: Record<string, string> = {
  tailor: 'Tailor',
  rental_shop: 'Suit Rental Shop',
  designer: 'Designer',
  embroidery: 'Embroidery Specialist',
};

export function businessTypeLabel(businessType: string): string {
  return BUSINESS_TYPE_LABELS[businessType] ?? businessType;
}

const ROLE_LABELS: Record<string, string> = {
  CUSTOMER: 'Customer',
  TAILOR: 'Tailor',
  RENTAL_SHOP: 'Suit Rental Shop',
  DESIGNER: 'Designer',
  EMBROIDERY_SPECIALIST: 'Embroidery Specialist',
  ADMIN: 'Admin',
};

export function roleLabel(role: string): string {
  return ROLE_LABELS[role] ?? role;
}

export function relativeTime(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const minutes = Math.floor(diffMs / 60_000);
  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes} minute${minutes === 1 ? '' : 's'} ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hour${hours === 1 ? '' : 's'} ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days} day${days === 1 ? '' : 's'} ago`;
  const weeks = Math.floor(days / 7);
  if (weeks < 5) return `${weeks} week${weeks === 1 ? '' : 's'} ago`;
  const months = Math.floor(days / 30);
  return `${months} month${months === 1 ? '' : 's'} ago`;
}

export function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}
