import { useEffect, useState, type FormEvent } from 'react';
import { adminApi, ApiError } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { useStats } from '../lib/statsContext';
import { initials } from '../lib/format';
import { Modal } from '../components/Modal';
import { Pagination } from '../components/Pagination';
import type { TailorProfile } from '../lib/types';

const PAGE_SIZE = 10;

export function Tailors() {
  const { accessToken, logout } = useAuth();
  const { refresh: refreshStats } = useStats();
  const [tailors, setTailors] = useState<TailorProfile[] | null>(null);
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
      .listTailors(accessToken, { q: debouncedSearch || undefined, page, pageSize: PAGE_SIZE })
      .then((result) => {
        setTailors(result.data);
        setTotal(result.total);
      })
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) return logout();
        setError(err instanceof Error ? err.message : 'Failed to load tailors');
      });
  }, [accessToken, logout, debouncedSearch, page]);

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

  function handleCreated() {
    setShowCreate(false);
    void refreshStats();
    if (page !== 1) {
      setPage(1);
    } else if (accessToken) {
      adminApi
        .listTailors(accessToken, { q: debouncedSearch || undefined, page: 1, pageSize: PAGE_SIZE })
        .then((result) => {
          setTailors(result.data);
          setTotal(result.total);
        })
        .catch(() => {});
    }
  }

  return (
    <section className="view">
      <div className="page-head">
        <div>
          <h1>Tailors</h1>
          <p>Verified tailors currently active on the platform.</p>
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
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
          <button type="button" className="btn btn-approve" onClick={() => setShowCreate(true)}>
            <span className="material-symbols-rounded">add</span>Add tailor
          </button>
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
            {tailors?.map((t) => (
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
        {tailors && tailors.length === 0 && <div className="empty-note">No tailors match.</div>}
        <Pagination page={page} pageSize={PAGE_SIZE} total={total} onPageChange={setPage} />
      </div>

      {showCreate && (
        <CreateTailorModal onClose={() => setShowCreate(false)} onCreated={handleCreated} />
      )}
    </section>
  );
}

function CreateTailorModal({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const { accessToken, logout } = useAuth();
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [businessName, setBusinessName] = useState('');
  const [bio, setBio] = useState('');
  const [specialties, setSpecialties] = useState('');
  const [deliveryRadiusKm, setDeliveryRadiusKm] = useState('');
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
      await adminApi.createTailor(accessToken, {
        fullName: fullName.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        businessName: businessName.trim(),
        bio: bio.trim() || undefined,
        specialties: specialties
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean),
        deliveryRadiusKm: deliveryRadiusKm ? Number(deliveryRadiusKm) : undefined,
      });
      onCreated();
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) return logout();
      setError(err instanceof Error ? err.message : 'Failed to create tailor');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Modal title="Add tailor" onClose={onClose}>
      <form onSubmit={handleSubmit}>
        <div className="field">
          <label htmlFor="t-fullName">Owner's full name</label>
          <input
            id="t-fullName"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="t-email">Email</label>
          <input id="t-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor="t-phone">Phone</label>
          <input id="t-phone" value={phone} onChange={(e) => setPhone(e.target.value)} />
        </div>
        <p className="field-hint">Provide at least one of email or phone.</p>
        <div className="field">
          <label htmlFor="t-businessName">Business name</label>
          <input
            id="t-businessName"
            value={businessName}
            onChange={(e) => setBusinessName(e.target.value)}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="t-bio">Bio</label>
          <textarea id="t-bio" value={bio} onChange={(e) => setBio(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor="t-specialties">Specialties (comma-separated)</label>
          <input
            id="t-specialties"
            placeholder="Suits, Sherwanis"
            value={specialties}
            onChange={(e) => setSpecialties(e.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="t-radius">Delivery radius (km)</label>
          <input
            id="t-radius"
            type="number"
            min="0"
            step="0.1"
            value={deliveryRadiusKm}
            onChange={(e) => setDeliveryRadiusKm(e.target.value)}
          />
        </div>

        {error && <p className="error-note" style={{ padding: 0 }}>{error}</p>}

        <div className="modal-actions">
          <button type="button" className="btn btn-reject" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="btn btn-approve" disabled={submitting}>
            {submitting ? 'Creating…' : 'Create tailor'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
