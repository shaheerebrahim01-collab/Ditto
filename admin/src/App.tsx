import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider } from './lib/authContext';
import { RequireAdmin } from './components/RequireAdmin';
import { Layout } from './components/Layout';
import { Login } from './pages/Login';
import { Overview } from './pages/Overview';
import { Applications } from './pages/Applications';
import { Users } from './pages/Users';
import { Tailors } from './pages/Tailors';
import { RentalShops } from './pages/RentalShops';

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route element={<RequireAdmin />}>
            <Route element={<Layout />}>
              <Route index element={<Overview />} />
              <Route path="applications" element={<Applications />} />
              <Route path="users" element={<Users />} />
              <Route path="tailors" element={<Tailors />} />
              <Route path="rental-shops" element={<RentalShops />} />
            </Route>
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
