import { useEffect, useState, type FormEvent } from 'react';
import { adminApi, ApiError } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { useStats } from '../lib/statsContext';
import { formatDate, initials, roleLabel } from '../lib/format';
import { Modal } from '../components/Modal';
import { Pagination } from '../components/Pagination';
import type { DittoUser, Role } from '../lib/types';

const PAGE_SIZE = 10;
const ROLES: Role[] = ['CUSTOMER', 'TAILOR', 'RENTAL_SHOP', 'DESIGNER', 'EMBROIDERY_SPECIALIST', 'ADMIN'];

export function Users() {
  const { accessToken, logout, user: currentUser } = useAuth();
  const { refresh: refreshStats } = useStats();
  const [users, setUsers] = useState<DittoUser[] | null>(null);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [pendingIds, setPendingIds] = useState<Set<string>>(new Set());
  const [showCreate, setShowCreate] = useState(false);

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
      .listUsers(accessToken, { q: debouncedSearch || undefined, page, pageSize: PAGE_SIZE })
      .then((result) => {
        setUsers(result.data);
        setTotal(result.total);
      })
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) return logout();
        setError(err instanceof Error ? err.message : 'Failed to load users');
      });
  }, [accessToken, logout, debouncedSearch, page]);

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

  function handleCreated() {
    setShowCreate(false);
    void refreshStats();
    if (page !== 1) {
      setPage(1);
    } else if (accessToken) {
      adminApi
        .listUsers(accessToken, { q: debouncedSearch || undefined, page: 1, pageSize: PAGE_SIZE })
        .then((result) => {
          setUsers(result.data);
          setTotal(result.total);
        })
        .catch(() => {});
    }
  }

  return (
    <section className="view">
      <div className="page-head">
        <div>
          <h1>Users</h1>
          <p>Everyone with a Ditto account.</p>
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
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
          <button type="button" className="btn btn-approve" onClick={() => setShowCreate(true)}>
            <span className="material-symbols-rounded">add</span>Add user
          </button>
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
            {users?.map((u) => (
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
        {users && users.length === 0 && <div className="empty-note">No users match.</div>}
        <Pagination page={page} pageSize={PAGE_SIZE} total={total} onPageChange={setPage} />
      </div>

      {showCreate && (
        <CreateUserModal
          onClose={() => setShowCreate(false)}
          onCreated={handleCreated}
        />
      )}
    </section>
  );
}

function CreateUserModal({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const { accessToken, logout } = useAuth();
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [role, setRole] = useState<Role>('CUSTOMER');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!accessToken) return;
    if (!email.trim() && !phone.trim()) {
      setError('Provide at least an email or a phone number.');
      return;
    }
    setError(null);
    setSubmitting(true);
    try {
      await adminApi.createUser(accessToken, {
        fullName: fullName.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        role,
      });
      onCreated();
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) return logout();
      setError(err instanceof Error ? err.message : 'Failed to create user');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Modal title="Add user" onClose={onClose}>
      <form onSubmit={handleSubmit}>
        <div className="field">
          <label htmlFor="fullName">Full name</label>
          <input
            id="fullName"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="email">Email</label>
          <input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor="phone">Phone</label>
          <input id="phone" value={phone} onChange={(e) => setPhone(e.target.value)} />
        </div>
        <p className="field-hint">Provide at least one of email or phone.</p>
        <div className="field">
          <label htmlFor="role">Role</label>
          <select id="role" value={role} onChange={(e) => setRole(e.target.value as Role)}>
            {ROLES.map((r) => (
              <option key={r} value={r}>
                {roleLabel(r)}
              </option>
            ))}
          </select>
        </div>

        {error && <p className="error-note" style={{ padding: 0 }}>{error}</p>}

        <div className="modal-actions">
          <button type="button" className="btn btn-reject" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="btn btn-approve" disabled={submitting}>
            {submitting ? 'Creating…' : 'Create user'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
