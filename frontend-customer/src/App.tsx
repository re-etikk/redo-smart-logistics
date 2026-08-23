import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider, Protected } from "./hooks/useAuth";

// Auth pages
import Login from "./pages/auth/Login";
import SignUp from "./pages/auth/SignUp";
import CustomerOnboarding from "./pages/onboarding/Sme";

// Customer pages
import Dashboard from "./pages/Dashboard";
import BookShipment from "./pages/BookShipment";
import PostCargo from "./pages/PostCargo";
import Recommendations from "./pages/Recommendations";
import Bookings from "./pages/Bookings";
import BookingDetail from "./pages/BookingDetail";
import MatchDetail from "./pages/MatchDetail";
import Tracking from "./pages/Tracking";
import Invoices from "./pages/Invoices";
import Addresses from "./pages/Addresses";
import RateCard from "./pages/RateCard";
import Support from "./pages/Support";
import Profile from "./pages/Profile";
import Notifications from "./pages/Notifications";
import Landing from "./pages/Landing";

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Public */}
          <Route path="/" element={<Landing />} />
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<SignUp />} />

          {/* Onboarding */}
          <Route path="/onboarding" element={<Protected><CustomerOnboarding /></Protected>} />
          <Route path="/onboarding/sme" element={<Protected><CustomerOnboarding /></Protected>} />

          {/* Protected — Customer Only */}
          <Route path="/dashboard" element={<Protected><Dashboard /></Protected>} />
          <Route path="/book" element={<Protected><BookShipment /></Protected>} />
          <Route path="/post-cargo" element={<Protected><PostCargo /></Protected>} />
          <Route path="/find-trucks/:cargoId" element={<Protected><Recommendations /></Protected>} />
          <Route path="/match/:cargoId/:truckId" element={<Protected><MatchDetail /></Protected>} />
          <Route path="/shipments" element={<Protected><Bookings /></Protected>} />
          <Route path="/shipments/:id" element={<Protected><BookingDetail /></Protected>} />
          <Route path="/bookings" element={<Protected><Bookings /></Protected>} />
          <Route path="/bookings/:id" element={<Protected><BookingDetail /></Protected>} />
          <Route path="/tracking/:bookingId" element={<Protected><Tracking /></Protected>} />
          <Route path="/invoices" element={<Protected><Invoices /></Protected>} />
          <Route path="/addresses" element={<Protected><Addresses /></Protected>} />
          <Route path="/rate-card" element={<Protected><RateCard /></Protected>} />
          <Route path="/support" element={<Protected><Support /></Protected>} />
          <Route path="/settings" element={<Protected><Profile /></Protected>} />
          <Route path="/profile" element={<Protected><Profile /></Protected>} />
          <Route path="/notifications" element={<Protected><Notifications /></Protected>} />

          {/* Catch-all */}
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
