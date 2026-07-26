import type {
  AdminStats,
  BusinessApplication,
  BusinessStatus,
  DittoUser,
  Role,
  TailorProfile,
} from './types';

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000';

export class ApiError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

async function request<T>(
  path: string,
  token: string,
  options: { method?: string; body?: unknown } = {},
): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: options.method ?? 'GET',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
  });

  if (!res.ok) {
    const body = await res.json().catch(() => null);
    throw new ApiError(res.status, body?.message ?? `${res.status} ${res.statusText}`);
  }
  return res.json();
}

// POST /auth/firebase doesn't need our own JWT — it's how you get one — so
// it's the one call here that isn't routed through `request()`.
export async function exchangeFirebaseToken(
  idToken: string,
): Promise<{ accessToken: string; user: DittoUser }> {
  const res = await fetch(`${API_BASE}/auth/firebase`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ idToken }),
  });
  if (!res.ok) {
    const body = await res.json().catch(() => null);
    throw new ApiError(res.status, body?.message ?? 'Sign-in failed');
  }
  return res.json();
}

export const adminApi = {
  getStats: (token: string) => request<AdminStats>('/admin/stats', token),

  listBusinessApplications: (token: string, status?: BusinessStatus) =>
    request<BusinessApplication[]>(
      `/admin/business-applications${status ? `?status=${status}` : ''}`,
      token,
    ),

  approveApplication: (token: string, id: string, reviewNotes?: string) =>
    request<BusinessApplication>(`/admin/business-applications/${id}/approve`, token, {
      method: 'POST',
      body: { reviewNotes },
    }),

  rejectApplication: (token: string, id: string, reviewNotes?: string) =>
    request<BusinessApplication>(`/admin/business-applications/${id}/reject`, token, {
      method: 'POST',
      body: { reviewNotes },
    }),

  listUsers: (token: string, role?: Role) =>
    request<DittoUser[]>(`/admin/users${role ? `?role=${role}` : ''}`, token),

  suspendUser: (token: string, id: string) =>
    request<DittoUser>(`/admin/users/${id}/suspend`, token, { method: 'POST' }),

  reactivateUser: (token: string, id: string) =>
    request<DittoUser>(`/admin/users/${id}/reactivate`, token, { method: 'POST' }),

  listTailors: (token: string) => request<TailorProfile[]>('/admin/tailors', token),

  suspendTailor: (token: string, id: string) =>
    request<TailorProfile>(`/admin/tailors/${id}/suspend`, token, { method: 'POST' }),

  reactivateTailor: (token: string, id: string) =>
    request<TailorProfile>(`/admin/tailors/${id}/reactivate`, token, { method: 'POST' }),
};
