import { Link } from 'react-router-dom';
import { useStats } from '../lib/statsContext';
import { usePendingApplications } from '../lib/useApplications';
import { ApplicationCard } from '../components/ApplicationCard';

const today = new Date().toLocaleDateString('en-US', {
  weekday: 'long',
  month: 'long',
  day: 'numeric',
});

export function Overview() {
  const { stats, error: statsError } = useStats();
  const { applications, error: appsError, leavingIds, decide } = usePendingApplications();
  const preview = applications?.slice(0, 2) ?? [];

  return (
    <section className="view">
      <div className="page-head">
        <div>
          <h1>Overview</h1>
          <p>{today} — here's where things stand.</p>
        </div>
      </div>

      {statsError && <div className="card error-note">{statsError}</div>}

      <div className="stat-grid">
        <div className="card stat-card">
          <div className="stat-num">{stats?.pendingApprovals ?? '—'}</div>
          <div className="stat-label">Pending applications</div>
        </div>
        <div className="card stat-card">
          <div className="stat-num">{stats?.tailorCount ?? '—'}</div>
          <div className="stat-label">Active tailors</div>
        </div>
        <div className="card stat-card">
          <div className="stat-num">{stats?.userCount ?? '—'}</div>
          <div className="stat-label">Total users</div>
        </div>
        <div className="card stat-card">
          <div className="stat-num">{stats?.ordersThisMonth ?? '—'}</div>
          <div className="stat-label">Orders this month</div>
        </div>
      </div>

      <div className="section-head">
        <h3>Needs your review</h3>
        <Link to="/applications">View all →</Link>
      </div>

      {appsError && <div className="card error-note">{appsError}</div>}
      {applications && applications.length === 0 && (
        <div className="card empty-note">Nothing needs review right now.</div>
      )}
      {preview.map((app) => (
        <ApplicationCard
          key={app.id}
          application={app}
          leaving={leavingIds.has(app.id)}
          onDecide={decide}
        />
      ))}
    </section>
  );
}
