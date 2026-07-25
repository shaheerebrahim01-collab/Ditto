import { businessTypeLabel, initials, relativeTime } from '../lib/format';
import type { BusinessApplication } from '../lib/types';

interface Props {
  application: BusinessApplication;
  leaving: boolean;
  onDecide: (id: string, action: 'approve' | 'reject') => void;
}

export function ApplicationCard({ application, leaving, onDecide }: Props) {
  const applicantName = application.applicant?.fullName ?? 'Unknown applicant';
  const contact = application.applicant?.email ?? application.applicant?.phone ?? 'no contact on file';

  return (
    <div className={`card app-card${leaving ? ' leaving' : ''}`}>
      <div className="app-avatar">{initials(applicantName)}</div>
      <div className="app-info">
        <div className="app-name">{applicantName}</div>
        <div className="app-meta">
          <span className="type-chip">{businessTypeLabel(application.businessType)}</span>
          {contact} · submitted {relativeTime(application.submittedAt)}
        </div>
      </div>
      <div className="app-actions">
        <button
          className="btn btn-reject"
          type="button"
          disabled={leaving}
          onClick={() => onDecide(application.id, 'reject')}
        >
          <span className="material-symbols-rounded">close</span>Decline
        </button>
        <button
          className="btn btn-approve"
          type="button"
          disabled={leaving}
          onClick={() => onDecide(application.id, 'approve')}
        >
          <span className="material-symbols-rounded">check</span>Approve
        </button>
      </div>
    </div>
  );
}
