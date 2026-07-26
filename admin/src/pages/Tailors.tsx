import { useEffect, useMemo, useState } from 'react';
import { adminApi, ApiError } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { initials } from '../lib/format';
import type { TailorProfile } from '../lib/types';

export function Tailors() {
  const { accessToken, logout } = useAuth();
  const [tailors, setTailors] = useState<TailorProfile[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [pendingIds, setPendingIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (!accessToken) return;
    adminApi
      .listTailors(accessToken)
      .then(setTailors)
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) return logout();
        setError(err instanceof Error ? err.message : 'Failed to load tailors');
      });
  }, [accessToken, logout]);

  const filtered = useMemo(() => {
    if (!tailors) return null;
    const q = search.trim().toLowerCase();
    if (!q) return tailors;
    return tailors.filter(
      (t) =>
        t.businessName.toLowerCase().includes(q) || t.user.fullName.toLowerCase().includes(q),
    );
  }, [tailors, search]);

  async function toggleSuspended(t: TailorProfile) {
    if (!accessToken) return;
    setPendingIds((prev) => new Set(prev).add(t.id));
    try {
      const updated =
        t.status === 'SUSPENDED'
          ? await adminApi.reactivateTailor(accessToken, t.id)
          : await adminApi.suspendTailor(accessToken, t.id);
      setTailors((prev) => prev?.map((existing) => (existing.id === t.id ? updated : existing)) ?? prev);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) return logout();
      setError(err instanceof Error ? err.message : 'Action failed');
    } finally {
      setPendingIds((prev) => {
        const next = new Set(prev);
        next.delete(t.id);
        return next;
      });
    }
  }

  return (
    <section className="view">
      <div className="page-head">
        <div>
          <h1>Tailors</h1>
          <p>Verified tailors currently active on the platform.</p>
        </div>
        <div className="search-bar">
          <span className="material-symbols-rounded" style={{ fontSize: 16 }}>
            search
          </span>
          <input
            placeholder="Search tailors…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      {error && <div className="card error-note">{error}</div>}

      <div className="card shadow">
        <table>
          <thead>
            <tr>
              <th>Tailor</th>
              <th>Specialty</th>
              <th>Orders completed</th>
              <th>Rating</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {filtered?.map((t) => (
              <tr key={t.id}>
                <td>
                  <div className="person">
                    <div className="avatar">{initials(t.user.fullName)}</div>
                    <div className="person-name">{t.businessName}</div>
                  </div>
                </td>
                <td>{t.specialties.length > 0 ? t.specialties.join(', ') : '—'}</td>
                <td>{t.completedOrders}</td>
                <td>
                  <span className="rating">
                    <span className="material-symbols-rounded">star</span>
                    {t.ratingCount > 0 ? t.ratingAvg.toFixed(1) : '—'}
                  </span>
                </td>
                <td>
                  <span className={`status-badge ${t.status === 'SUSPENDED' ? 'suspended' : 'active'}`}>
                    {t.status.charAt(0) + t.status.slice(1).toLowerCase()}
                  </span>
                </td>
                <td>
                  {(t.status === 'APPROVED' || t.status === 'SUSPENDED') && (
                    <button
                      type="button"
                      className={`btn btn-sm ${t.status === 'SUSPENDED' ? 'btn-approve' : 'btn-reject'}`}
                      disabled={pendingIds.has(t.id)}
                      onClick={() => toggleSuspended(t)}
                    >
                      {t.status === 'SUSPENDED' ? 'Reactivate' : 'Suspend'}
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered && filtered.length === 0 && <div className="empty-note">No tailors match.</div>}
      </div>
    </section>
  );
}
