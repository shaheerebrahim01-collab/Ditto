import { usePendingApplications } from '../lib/useApplications';
import { ApplicationCard } from '../components/ApplicationCard';

export function Applications() {
  const { applications, error, leavingIds, decide } = usePendingApplications();

  return (
    <section className="view">
      <div className="page-head">
        <div>
          <h1>Business applications</h1>
          <p>New tailors, rental shops, designers, and embroidery specialists waiting on review.</p>
        </div>
      </div>

      {error && <div className="card error-note">{error}</div>}
      {applications && applications.length === 0 && (
        <div className="card empty-note">All caught up — no pending applications.</div>
      )}
      {applications?.map((app) => (
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
