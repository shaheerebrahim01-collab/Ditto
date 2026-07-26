import { useEffect, useMemo, useState } from 'react';
import { adminApi, ApiError } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { formatDate, initials, roleLabel } from '../lib/format';
import type { DittoUser } from '../lib/types';

export function Users() {
  const { accessToken, logout, user: currentUser } = useAuth();
  const [users, setUsers] = useState<DittoUser[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [pendingIds, setPendingIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (!accessToken) return;
    adminApi
      .listUsers(accessToken)
      .then(setUsers)
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) return logout();
        setError(err instanceof Error ? err.message : 'Failed to load users');
      });
  }, [accessToken, logout]);

  const filtered = useMemo(() => {
    if (!users) return null;
    const q = search.trim().toLowerCase();
    if (!q) return users;
    return users.filter(
      (u) => u.fullName.toLowerCase().includes(q) || u.email?.toLowerCase().includes(q),
    );
  }, [users, search]);

  async function toggleSuspended(u: DittoUser) {
    if (!accessToken) return;
    setPendingIds((prev) => new Set(prev).add(u.id));
    try {
      const updated = u.suspended
        ? await adminApi.reactivateUser(accessToken, u.id)
        : await adminApi.suspendUser(accessToken, u.id);
      setUsers((prev) => prev?.map((existing) => (existing.id === u.id ? updated : existing)) ?? prev);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) return logout();
      setError(err instanceof Error ? err.message : 'Action failed');
    } finally {
      setPendingIds((prev) => {
        const next = new Set(prev);
        next.delete(u.id);
        return next;
      });
    }
  }

  return (
    <section className="view">
      <div className="page-head">
        <div>
          <h1>Users</h1>
          <p>Everyone with a Ditto account.</p>
        </div>
        <div className="search-bar">
          <span className="material-symbols-rounded" style={{ fontSize: 16 }}>
            search
          </span>
          <input
            placeholder="Search users…"
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
              <th>Name</th>
              <th>Role</th>
              <th>Joined</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {filtered?.map((u) => (
              <tr key={u.id}>
                <td>
                  <div className="person">
                    <div className="avatar">{initials(u.fullName)}</div>
                    <div>
                      <div className="person-name">{u.fullName}</div>
                      <div className="person-sub">{u.email ?? u.phone ?? '—'}</div>
                    </div>
                  </div>
                </td>
                <td>
                  <span className="role-badge">{roleLabel(u.role)}</span>
                </td>
                <td>{formatDate(u.createdAt)}</td>
                <td>
                  <span className={`status-badge ${u.suspended ? 'suspended' : 'active'}`}>
                    {u.suspended ? 'Suspended' : 'Active'}
                  </span>
                </td>
                <td>
                  {u.id === currentUser?.id ? null : (
                    <button
                      type="button"
                      className={`btn btn-sm ${u.suspended ? 'btn-approve' : 'btn-reject'}`}
                      disabled={pendingIds.has(u.id)}
                      onClick={() => toggleSuspended(u)}
                    >
                      {u.suspended ? 'Reactivate' : 'Suspend'}
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered && filtered.length === 0 && <div className="empty-note">No users match.</div>}
      </div>
    </section>
  );
}
