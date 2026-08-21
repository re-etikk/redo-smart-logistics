import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider, Protected, useAuth } from "./hooks/useAuth";
import { ToastProvider } from "./components/ui";
import Landing from "./pages/Landing";
import Login from "./pages/auth/Login";
import SignUp from "./pages/auth/SignUp";
import Forgot from "./pages/auth/Forgot";
import OwnerOnboarding from "./pages/onboarding/Owner";
import SmeOnboarding from "./pages/onboarding/Sme";
import OwnerDashboard from "./pages/owner/Dashboard";
import AddTrip from "./pages/owner/AddTrip";
import SmeDashboard from "./pages/sme/Dashboard";
import PostCargo from "./pages/sme/PostCargo";
import Recommendations from "./pages/sme/Recommendations";
import MatchDetail from "./pages/MatchDetail";
import Bookings from "./pages/Bookings";
import BookingDetail from "./pages/BookingDetail";
import Tracking from "./pages/Tracking";
import Impact from "./pages/Impact";
import Verification from "./pages/Verification";
import Profile from "./pages/Profile";
import Notifications from "./pages/Notifications";
import Diagnostics from "./pages/Diagnostics";

function Home() {
  const { session, profile, loading } = useAuth();
  if (loading) return null;
  if (session && profile?.onboarding_complete) {
    return <Navigate to={profile.role === "sme" ? "/dashboard/sme" : "/dashboard/owner"} replace />;
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

            <Route path="/dashboard/owner" element={<Protected role="truck_owner"><OwnerDashboard /></Protected>} />
            <Route path="/trips/new" element={<Protected role="truck_owner"><AddTrip /></Protected>} />

            <Route path="/dashboard/sme" element={<Protected role="sme"><SmeDashboard /></Protected>} />
            <Route path="/post-cargo" element={<Protected role="sme"><PostCargo /></Protected>} />
            <Route path="/find-trucks/:cargoId" element={<Protected role="sme"><Recommendations /></Protected>} />
            <Route path="/match/:cargoId/:truckId" element={<Protected role="sme"><MatchDetail /></Protected>} />

            <Route path="/bookings" element={<Protected><Bookings /></Protected>} />
            <Route path="/bookings/:id" element={<Protected><BookingDetail /></Protected>} />
            <Route path="/tracking/:bookingId" element={<Protected><Tracking /></Protected>} />
            <Route path="/impact" element={<Protected><Impact /></Protected>} />
            <Route path="/verification" element={<Protected><Verification /></Protected>} />
            <Route path="/profile" element={<Protected><Profile /></Protected>} />
            <Route path="/notifications" element={<Protected><Notifications /></Protected>} />
            {import.meta.env.DEV && <Route path="/dev/diagnostics" element={<Protected><Diagnostics /></Protected>} />}

            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </AuthProvider>
  );
}
