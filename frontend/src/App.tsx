import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, Protected, useAuth } from './hooks/useAuth';
import { ToastProvider } from './components/ui';
import Landing from './pages/Landing';
import Login from './pages/auth/Login';
import SignUp from './pages/auth/SignUp';
import Forgot from './pages/auth/Forgot';
import OwnerOnboarding from './pages/onboarding/Owner';
import SmeOnboarding from './pages/onboarding/Sme';
import OwnerDashboard from './pages/owner/Dashboard';
import MyTrucks from './pages/owner/MyTrucks';
import AvailableLoads from './pages/owner/AvailableLoads';
import Earnings from './pages/owner/Earnings';
import Trips from './pages/owner/Trips';
import Payments from './pages/owner/Payments';
import Reviews from './pages/owner/Reviews';
import SmeDashboard from './pages/sme/Dashboard';
import BookShipment from './pages/sme/BookShipment';
import Recommendations from './pages/sme/Recommendations';
import MatchDetail from './pages/MatchDetail';
import Bookings from './pages/Bookings';
import BookingDetail from './pages/BookingDetail';
import Tracking from './pages/Tracking';
import Impact from './pages/Impact';
import Documents from './pages/Verification';
import ProfileSettings from './pages/Profile';
import Notifications from './pages/Notifications';
import Invoices from './pages/Invoices';
import Addresses from './pages/Addresses';
import RateCard from './pages/RateCard';
import Support from './pages/Support';
import AdminDashboard from './pages/admin/Dashboard';
import AdminUsers from './pages/admin/Users';
import AdminKyc from './pages/admin/Kyc';
import Diagnostics from './pages/Diagnostics';

function Home() {
  const { session, profile, loading } = useAuth();
  if (loading) return null;
  if (session) {
    const dest = profile?.role === 'truck_owner' ? '/dashboard/owner' : '/dashboard/sme';
    return <Navigate to={dest} replace />;
  }
  return <Landing />;
}

export default function App() {
  return (
    <AuthProvider>
      <ToastProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/login" element={<Login />} />
            <Route path="/signup" element={<SignUp />} />
            <Route path="/forgot-password" element={<Forgot />} />

            <Route path="/onboarding/owner" element={<Protected role="truck_owner" allowIncompleteOnboarding><OwnerOnboarding /></Protected>} />
            <Route path="/onboarding/sme" element={<Protected role="sme" allowIncompleteOnboarding><SmeOnboarding /></Protected>} />

            {/* Shipper */}
            <Route path="/dashboard/sme" element={<Protected role="sme"><SmeDashboard /></Protected>} />
            <Route path="/book" element={<Protected role="sme"><BookShipment /></Protected>} />
            <Route path="/find-trucks/:cargoId" element={<Protected role="sme"><Recommendations /></Protected>} />
            <Route path="/match/:cargoId/:truckId" element={<Protected role="sme"><MatchDetail /></Protected>} />
            <Route path="/invoices" element={<Protected role="sme"><Invoices /></Protected>} />
            <Route path="/addresses" element={<Protected role="sme"><Addresses /></Protected>} />
            <Route path="/rate-card" element={<Protected role="sme"><RateCard /></Protected>} />

            {/* Truck owner */}
            <Route path="/dashboard/owner" element={<Protected role="truck_owner"><OwnerDashboard /></Protected>} />
            <Route path="/trucks" element={<Protected role="truck_owner"><MyTrucks /></Protected>} />
            <Route path="/loads" element={<Protected role="truck_owner"><AvailableLoads /></Protected>} />
            <Route path="/earnings" element={<Protected role="truck_owner"><Earnings /></Protected>} />
            <Route path="/trips" element={<Protected role="truck_owner"><Trips /></Protected>} />
            <Route path="/payments" element={<Protected role="truck_owner"><Payments /></Protected>} />
            <Route path="/reviews" element={<Protected role="truck_owner"><Reviews /></Protected>} />
            <Route path="/documents" element={<Protected role="truck_owner"><Documents /></Protected>} />

            {/* Admin */}
            <Route path="/admin" element={<Protected role="admin"><AdminDashboard /></Protected>} />
            <Route path="/admin/users" element={<Protected role="admin"><AdminUsers /></Protected>} />
            <Route path="/admin/kyc" element={<Protected role="admin"><AdminKyc /></Protected>} />

            {/* Shared authenticated */}
            <Route path="/shipments" element={<Protected><Bookings /></Protected>} />
            <Route path="/bookings/:id" element={<Protected><BookingDetail /></Protected>} />
            <Route path="/tracking/:bookingId" element={<Protected><Tracking /></Protected>} />
            <Route path="/impact" element={<Protected><Impact /></Protected>} />
            <Route path="/verification" element={<Protected><Documents /></Protected>} />
            <Route path="/support" element={<Protected><Support /></Protected>} />
            <Route path="/settings" element={<Protected><ProfileSettings /></Protected>} />
            <Route path="/notifications" element={<Protected><Notifications /></Protected>} />
            {import.meta.env.DEV && <Route path="/dev/diagnostics" element={<Protected><Diagnostics /></Protected>} />}

            {/* Legacy redirects from v2 routes */}
            <Route path="/post-cargo" element={<Navigate to="/book" replace />} />
            <Route path="/bookings" element={<Navigate to="/shipments" replace />} />
            <Route path="/trips/new" element={<Navigate to="/trucks" replace />} />
            <Route path="/profile" element={<Navigate to="/settings" replace />} />

            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </AuthProvider>
  );
}
