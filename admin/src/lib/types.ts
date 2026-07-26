// Mirrors backend/src/modules/admin — kept in sync by hand since the
// admin app doesn't share a package with the NestJS backend.

export type Role =
  | 'CUSTOMER'
  | 'TAILOR'
  | 'RENTAL_SHOP'
  | 'DESIGNER'
  | 'EMBROIDERY_SPECIALIST'
  | 'ADMIN';

export type BusinessStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED';

export interface DittoUser {
  id: string;
  email: string | null;
  phone: string | null;
  role: Role;
  fullName: string;
  avatarUrl: string | null;
  authProvider: string;
  suspended: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface AdminStats {
  userCount: number;
  tailorCount: number;
  pendingApprovals: number;
  totalRevenue: number;
  ordersThisMonth: number;
}

export interface Applicant {
  id: string;
  fullName: string;
  email: string | null;
  phone: string | null;
}

export interface BusinessApplication {
  id: string;
  applicantId: string;
  businessType: string;
  status: BusinessStatus;
  submittedAt: string;
  reviewedAt: string | null;
  reviewNotes: string | null;
  applicant: Applicant | null;
}

export interface TailorProfile {
  id: string;
  userId: string;
  businessName: string;
  bio: string | null;
  specialties: string[];
  deliveryRadiusKm: number | null;
  status: BusinessStatus;
  ratingAvg: number;
  ratingCount: number;
  completedOrders: number;
  user: {
    fullName: string;
    email: string | null;
    phone: string | null;
  };
}
