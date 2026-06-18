import { Navigate, Route, Routes } from "react-router-dom";
import { useAuth } from "./context/AuthContext.jsx";
import Layout from "./components/Layout.jsx";
import Login from "./pages/Login.jsx";
import ForgotPassword from "./pages/ForgotPassword.jsx";
import ResetPassword from "./pages/ResetPassword.jsx";
import EmployeeDashboard from "./pages/EmployeeDashboard.jsx";
import CircularSummary from "./pages/CircularSummary.jsx";
import ManagerDashboard from "./pages/ManagerDashboard.jsx";
import AdminUpload from "./pages/AdminUpload.jsx";
import Users from "./pages/Users.jsx";
import Requests from "./pages/Requests.jsx";

// Guard a route: require a session, and optionally a set of roles (RBAC, NFR-07).
function Protected({ children, roles }) {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  if (roles && !roles.includes(user.role)) return <Navigate to="/" replace />;
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/forgot-password" element={<ForgotPassword />} />
      <Route path="/reset-password" element={<ResetPassword />} />

      <Route
        element={
          <Protected>
            <Layout />
          </Protected>
        }
      >
        {/* WF-02 — every signed-in user lands on the circular list */}
        <Route path="/" element={<EmployeeDashboard />} />
        {/* WF-03 — summary + RAG chatbot */}
        <Route path="/circulars/:id" element={<CircularSummary />} />
        {/* WF-04 — manager compliance dashboard */}
        <Route
          path="/compliance"
          element={
            <Protected roles={["Manager", "Administrator"]}>
              <ManagerDashboard />
            </Protected>
          }
        />
        {/* Change requests — managers see theirs, admins resolve all */}
        <Route
          path="/requests"
          element={
            <Protected roles={["Manager", "Administrator"]}>
              <Requests />
            </Protected>
          }
        />
        {/* WF-05 — administrator upload */}
        <Route
          path="/upload"
          element={
            <Protected roles={["Administrator"]}>
              <AdminUpload />
            </Protected>
          }
        />
        {/* Admin — user management (FR-02, FR-05) */}
        <Route
          path="/users"
          element={
            <Protected roles={["Administrator"]}>
              <Users />
            </Protected>
          }
        />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
