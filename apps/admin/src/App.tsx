import { Navigate, Route, Routes } from "react-router-dom";
import { RequireAuth } from "./auth";
import { Layout } from "./components/Layout";
import { LoginPage } from "./pages/LoginPage";
import { EarningsPage } from "./pages/EarningsPage";
import { SpacesPage } from "./pages/SpacesPage";
import { UsersPage } from "./pages/UsersPage";

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        element={
          <RequireAuth>
            <Layout />
          </RequireAuth>
        }
      >
        <Route path="/espacios" element={<SpacesPage />} />
        <Route path="/ganancias" element={<EarningsPage />} />
        <Route path="/usuarios" element={<UsersPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/espacios" replace />} />
    </Routes>
  );
}
