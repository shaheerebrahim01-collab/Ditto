import { NavLink, Outlet } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { useAuth } from '../lib/authContext';
import { useStats } from '../lib/statsContext';

const THEME_KEY = 'ditto-admin-theme';

function navClass({ isActive }: { isActive: boolean }) {
  return `nav-item${isActive ? ' active' : ''}`;
}

export function Layout() {
  const { logout, user } = useAuth();
  const { stats } = useStats();
  const [theme, setTheme] = useState<'light' | 'dark'>(
    () => (localStorage.getItem(THEME_KEY) as 'light' | 'dark') ?? 'light',
  );

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem(THEME_KEY, theme);
  }, [theme]);

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="mark">
          <div className="mark-icon">D</div>
          <div className="mark-text">
            <div className="mark-word">Ditto</div>
            <div className="mark-sub">Admin</div>
          </div>
        </div>
        <nav>
          <NavLink to="/" end className={navClass}>
            <span className="material-symbols-rounded">dashboard</span> Overview
          </NavLink>
          <NavLink to="/applications" className={navClass}>
            <span className="material-symbols-rounded">fact_check</span> Applications
            {!!stats?.pendingApprovals && (
              <span className="nav-badge">{stats.pendingApprovals}</span>
            )}
          </NavLink>
          <NavLink to="/users" className={navClass}>
            <span className="material-symbols-rounded">group</span> Users
          </NavLink>
          <NavLink to="/tailors" className={navClass}>
            <span className="material-symbols-rounded">content_cut</span> Tailors
          </NavLink>
        </nav>
        <div className="sidebar-foot">
          <button
            type="button"
            className="theme-toggle"
            onClick={() => setTheme((t) => (t === 'light' ? 'dark' : 'light'))}
          >
            <span className="material-symbols-rounded">
              {theme === 'light' ? 'dark_mode' : 'light_mode'}
            </span>
            <span>{theme === 'light' ? 'Dark mode' : 'Light mode'}</span>
          </button>
          {user && (
            <button type="button" className="theme-toggle" onClick={() => void logout()}>
              <span className="material-symbols-rounded">logout</span>
              <span>Sign out</span>
            </button>
          )}
        </div>
      </aside>
      <main>
        <Outlet />
      </main>
    </div>
  );
}
