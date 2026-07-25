import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../lib/authContext';
import { StatsProvider } from '../lib/statsContext';

export function RequireAdmin() {
  const { status } = useAuth();

  if (status === 'loading') return null;
  if (status === 'signed-out') return <Navigate to="/login" replace />;

  return (
    <StatsProvider>
      <Outlet />
    </StatsProvider>
  );
}
