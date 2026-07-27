import { useEffect, useState } from 'react';
import { adminApi, ApiError } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { initials } from '../lib/format';
import { Pagination } from '../components/Pagination';
import type { RentalShopProfile } from '../lib/types';

const PAGE_SIZE = 10;

export function RentalShops() {
  const { accessToken, logout } = useAuth();
  const [shops, setShops] = useState<RentalShopProfile[] | null>(null);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [pendingIds, setPendingIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(search.trim()), 300);
    return () => clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    setPage(1);
  }, [debouncedSearch]);

  useEffect(() => {
    if (!accessToken) return;
    adminApi
      .listRentalShops(accessToken, { q: debouncedSearch || undefined, page, pageSize: PAGE_SIZE })
      .then((result) => {
        setShops(result.data);
        setTotal(result.total);
      })
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) return logout();
        setError(err instanceof Error ? err.message : 'Failed to load rental shops');
      });
  }, [accessToken, logout, debouncedSearch, page]);

  async function toggleSuspended(s: RentalShopProfile) {
    if (!accessToken) return;
    setPendingIds((prev) => new Set(prev).add(s.id));
    try {
      const updated =
        s.status === 'SUSPENDED'
          ? await adminApi.reactivateRentalShop(accessToken, s.id)
          : await adminApi.suspendRentalShop(accessToken, s.id);
      setShops((prev) => prev?.map((existing) => (existing.id === s.id ? updated : existing)) ?? prev);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) return logout();
      setError(err instanceof Error ? err.message : 'Action failed');
    } finally {
      setPendingIds((prev) => {
        const next = new Set(prev);
        next.delete(s.id);
        return next;
      });
    }
  }

  return (
    <section className="view">
      <div className="page-head">
        <div>
          <h1>Rental shops</h1>
          <p>Verified rental shops currently active on the platform.</p>
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
          <div className="search-bar">
            <span className="material-symbols-rounded" style={{ fontSize: 16 }}>
              search
            </span>
            <input
              placeholder="Search rental shops…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>
      </div>

      {error && <div className="card error-note">{error}</div>}

      <div className="card shadow">
        <table>
          <thead>
            <tr>
              <th>Shop</th>
              <th>Items</th>
              <th>Rating</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {shops?.map((s) => (
              <tr key={s.id}>
                <td>
                  <div className="person">
                    <div className="avatar">{initials(s.user.fullName)}</div>
                    <div className="person-name">{s.businessName}</div>
                  </div>
                </td>
                <td>{s.itemCount}</td>
                <td>
                  <span className="rating">
                    <span className="material-symbols-rounded">star</span>
                    {s.ratingCount > 0 ? s.ratingAvg.toFixed(1) : '—'}
                  </span>
                </td>
                <td>
                  <span className={`status-badge ${s.status === 'SUSPENDED' ? 'suspended' : 'active'}`}>
                    {s.status.charAt(0) + s.status.slice(1).toLowerCase()}
                  </span>
                </td>
                <td>
                  {(s.status === 'APPROVED' || s.status === 'SUSPENDED') && (
                    <button
                      type="button"
                      className={`btn btn-sm ${s.status === 'SUSPENDED' ? 'btn-approve' : 'btn-reject'}`}
                      disabled={pendingIds.has(s.id)}
                      onClick={() => toggleSuspended(s)}
                    >
                      {s.status === 'SUSPENDED' ? 'Reactivate' : 'Suspend'}
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {shops && shops.length === 0 && <div className="empty-note">No rental shops match.</div>}
        <Pagination page={page} pageSize={PAGE_SIZE} total={total} onPageChange={setPage} />
      </div>
    </section>
  );
}
