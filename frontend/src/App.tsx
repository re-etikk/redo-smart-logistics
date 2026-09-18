import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, Protected } from './hooks/useAuth';
import { ToastProvider } from './components/ui';
import Login from './pages/auth/Login';
import AdminDashboard from './pages/admin/Dashboard';
import FleetRadar from './pages/admin/FleetRadar';
import MatchingOverseer from './pages/admin/MatchingOverseer';
import PricingControl from './pages/admin/PricingControl';
import Disputes from './pages/admin/Disputes';
import AdminUsers from './pages/admin/Users';
import AdminKyc from './pages/admin/Kyc';

export default function App() {
  return (
    <AuthProvider>
      <ToastProvider>
        <BrowserRouter>
          <Routes>
            {/* Direct Admin Root */}
            <Route path="/" element={<Protected><AdminDashboard /></Protected>} />
            <Route path="/login" element={<Login />} />

            {/* Admin Command Center Routes */}
            <Route path="/admin" element={<Protected><AdminDashboard /></Protected>} />
            <Route path="/admin/radar" element={<Protected><FleetRadar /></Protected>} />
            <Route path="/admin/matching" element={<Protected><MatchingOverseer /></Protected>} />
            <Route path="/admin/pricing" element={<Protected><PricingControl /></Protected>} />
            <Route path="/admin/disputes" element={<Protected><Disputes /></Protected>} />
            <Route path="/admin/users" element={<Protected><AdminUsers /></Protected>} />
            <Route path="/admin/kyc" element={<Protected><AdminKyc /></Protected>} />

            {/* Direct Short Routes */}
            <Route path="/radar" element={<Protected><FleetRadar /></Protected>} />
            <Route path="/matching" element={<Protected><MatchingOverseer /></Protected>} />
            <Route path="/pricing" element={<Protected><PricingControl /></Protected>} />
            <Route path="/disputes" element={<Protected><Disputes /></Protected>} />
            <Route path="/users" element={<Protected><AdminUsers /></Protected>} />
            <Route path="/kyc" element={<Protected><AdminKyc /></Protected>} />

            {/* Catch-all to Admin Dashboard */}
            <Route path="*" element={<Navigate to="/admin" replace />} />
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </AuthProvider>
  );
}
