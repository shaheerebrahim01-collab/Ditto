import { useCallback, useEffect, useState } from 'react';
import { adminApi, ApiError } from './apiClient';
import { useAuth } from './authContext';
import { useStats } from './statsContext';
import type { BusinessApplication } from './types';

// Shared between the Overview preview list and the full Applications view —
// both show the same pending queue and the same approve/reject action, just
// in different amounts and layouts.
export function usePendingApplications() {
  const { accessToken, logout } = useAuth();
  const { refresh: refreshStats } = useStats();
  const [applications, setApplications] = useState<BusinessApplication[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [leavingIds, setLeavingIds] = useState<Set<string>>(new Set());

  const load = useCallback(async () => {
    if (!accessToken) return;
    try {
      const apps = await adminApi.listBusinessApplications(accessToken, 'PENDING');
      setApplications(apps);
      setError(null);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) return logout();
      setError(err instanceof Error ? err.message : 'Failed to load applications');
    }
  }, [accessToken, logout]);

  useEffect(() => {
    void load();
  }, [load]);

  async function decide(id: string, action: 'approve' | 'reject') {
    if (!accessToken) return;
    setLeavingIds((prev) => new Set(prev).add(id));
    try {
      if (action === 'approve') {
        await adminApi.approveApplication(accessToken, id);
      } else {
        await adminApi.rejectApplication(accessToken, id);
      }
      setTimeout(() => {
        setApplications((prev) => prev?.filter((a) => a.id !== id) ?? prev);
        setLeavingIds((prev) => {
          const next = new Set(prev);
          next.delete(id);
          return next;
        });
      }, 220);
      void refreshStats();
    } catch (err) {
      setLeavingIds((prev) => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      });
      if (err instanceof ApiError && err.status === 401) return logout();
      setError(err instanceof Error ? err.message : 'Action failed');
    }
  }

  return { applications, error, leavingIds, decide };
}
