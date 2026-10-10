import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, Protected } from './hooks/useAuth';
import { ToastProvider } from './components/ui';
import Login from './pages/auth/Login';
import Forgot from './pages/auth/Forgot';
import ResetPassword from './pages/auth/ResetPassword';
import AdminDashboard from './pages/admin/Dashboard';
import FleetRadar from './pages/admin/FleetRadar';
import MatchingOverseer from './pages/admin/MatchingOverseer';
import PricingControl from './pages/admin/PricingControl';
import Disputes from './pages/admin/Disputes';
import AdminUsers from './pages/admin/Users';
import AdminKyc from './pages/admin/Kyc';
import AdminBookings from './pages/admin/Bookings';
import AdminPayments from './pages/admin/Payments';
import AdminPayouts from './pages/admin/Payouts';
import ActiveTrips from './pages/admin/ActiveTrips';
import PartnerVerification from './pages/admin/verification/PartnerVerification';
import VehicleVerification from './pages/admin/verification/VehicleVerification';
import CargoVerification from './pages/admin/verification/CargoVerification';
import Documents from './pages/admin/verification/Documents';
import SupportTickets from './pages/admin/communication/SupportTickets';
import CallLogs from './pages/admin/communication/CallLogs';
import Notifications from './pages/admin/communication/Notifications';
import Alerts from './pages/admin/system/Alerts';
import AuditLogs from './pages/admin/system/AuditLogs';
import SystemHealth from './pages/admin/system/SystemHealth';
import Privacy from './pages/Privacy';

export default function App() {
  return (
    <AuthProvider>
      <ToastProvider>
        <BrowserRouter>
          <Routes>
            {/* Direct Admin Root */}
            <Route path="/" element={<Protected><AdminDashboard /></Protected>} />
            <Route path="/login" element={<Login />} />
            <Route path="/forgot-password" element={<Forgot />} />
            <Route path="/reset-password" element={<ResetPassword />} />
            <Route path="/privacy" element={<Privacy />} />
            <Route path="/privacy-policy" element={<Privacy />} />

            {/* Admin Command Center Routes */}
            <Route path="/admin" element={<Protected><AdminDashboard /></Protected>} />
            <Route path="/admin/bookings" element={<Protected><AdminBookings /></Protected>} />
            <Route path="/admin/trips" element={<Protected><ActiveTrips /></Protected>} />
            <Route path="/admin/radar" element={<Protected><FleetRadar /></Protected>} />
            <Route path="/admin/matching" element={<Protected><MatchingOverseer /></Protected>} />
            <Route path="/admin/pricing" element={<Protected><PricingControl /></Protected>} />
            <Route path="/admin/payments" element={<Protected><AdminPayments /></Protected>} />
            <Route path="/admin/payouts" element={<Protected><AdminPayouts /></Protected>} />
            <Route path="/admin/disputes" element={<Protected><Disputes /></Protected>} />
            <Route path="/admin/users" element={<Protected><AdminUsers /></Protected>} />
            <Route path="/admin/kyc" element={<Protected><PartnerVerification /></Protected>} />

            {/* Verification Center Routes */}
            <Route path="/admin/verification/partners" element={<Protected><PartnerVerification /></Protected>} />
            <Route path="/admin/verification/vehicles" element={<Protected><VehicleVerification /></Protected>} />
            <Route path="/admin/verification/cargo" element={<Protected><CargoVerification /></Protected>} />
            <Route path="/admin/verification/documents" element={<Protected><Documents /></Protected>} />

            {/* Communication & Escalation Routes */}
            <Route path="/admin/communication/tickets" element={<Protected><SupportTickets /></Protected>} />
            <Route path="/admin/communication/calls" element={<Protected><CallLogs /></Protected>} />
            <Route path="/admin/communication/notifications" element={<Protected><Notifications /></Protected>} />

            {/* System & Exceptions Routes */}
            <Route path="/admin/system/alerts" element={<Protected><Alerts /></Protected>} />
            <Route path="/admin/system/audit-logs" element={<Protected><AuditLogs /></Protected>} />
            <Route path="/admin/system/health" element={<Protected><SystemHealth /></Protected>} />

            {/* Direct Short Routes */}
            <Route path="/bookings" element={<Protected><AdminBookings /></Protected>} />
            <Route path="/trips" element={<Protected><ActiveTrips /></Protected>} />
            <Route path="/radar" element={<Protected><FleetRadar /></Protected>} />
            <Route path="/matching" element={<Protected><MatchingOverseer /></Protected>} />
            <Route path="/pricing" element={<Protected><PricingControl /></Protected>} />
            <Route path="/payments" element={<Protected><AdminPayments /></Protected>} />
            <Route path="/payouts" element={<Protected><AdminPayouts /></Protected>} />
            <Route path="/disputes" element={<Protected><Disputes /></Protected>} />
            <Route path="/users" element={<Protected><AdminUsers /></Protected>} />
            <Route path="/kyc" element={<Protected><PartnerVerification /></Protected>} />
            <Route path="/health" element={<Protected><SystemHealth /></Protected>} />

            {/* Catch-all to Admin Dashboard */}
            <Route path="*" element={<Navigate to="/admin" replace />} />
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </AuthProvider>
  );
}
