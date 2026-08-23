import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider, Protected } from "./hooks/useAuth";

// Auth pages
import Login from "./pages/auth/Login";
import SignUp from "./pages/auth/SignUp";
import OwnerOnboarding from "./pages/onboarding/Owner";

// Owner pages
import Dashboard from "./pages/Dashboard";
import MyTrucks from "./pages/MyTrucks";
import Bookings from "./pages/Bookings";
import Earnings from "./pages/Earnings";
import Trips from "./pages/Trips";
import Payments from "./pages/Payments";
import Documents from "./pages/Documents";
import Reviews from "./pages/Reviews";
import Support from "./pages/Support";
import Settings from "./pages/Settings";
import AvailableLoads from "./pages/AvailableLoads";
import AddTrip from "./pages/AddTrip";
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
          <Route path="/onboarding" element={<Protected><OwnerOnboarding /></Protected>} />
          <Route path="/onboarding/owner" element={<Protected><OwnerOnboarding /></Protected>} />

          {/* Protected — Truck Owner Only */}
          <Route path="/dashboard" element={<Protected><Dashboard /></Protected>} />
          <Route path="/trucks" element={<Protected><MyTrucks /></Protected>} />
          <Route path="/bookings" element={<Protected><Bookings /></Protected>} />
          <Route path="/earnings" element={<Protected><Earnings /></Protected>} />
          <Route path="/trips" element={<Protected><Trips /></Protected>} />
          <Route path="/trips/add" element={<Protected><AddTrip /></Protected>} />
          <Route path="/payments" element={<Protected><Payments /></Protected>} />
          <Route path="/documents" element={<Protected><Documents /></Protected>} />
          <Route path="/reviews" element={<Protected><Reviews /></Protected>} />
          <Route path="/support" element={<Protected><Support /></Protected>} />
          <Route path="/settings" element={<Protected><Settings /></Protected>} />
          <Route path="/loads" element={<Protected><AvailableLoads /></Protected>} />
          <Route path="/notifications" element={<Protected><Notifications /></Protected>} />

          {/* Catch-all */}
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
