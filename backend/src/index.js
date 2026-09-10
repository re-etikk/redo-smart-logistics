import "dotenv/config";
import cors from "cors";
import express from "express";
import { errorHandler } from "./middleware/error.js";
import admin from "./routes/admin.js";
import bookings from "./routes/bookings.js";
import cargo from "./routes/cargo.js";
import extras from "./routes/extras.js";
import misc from "./routes/misc.js";
import recommendations from "./routes/recommendations.js";
import trucks from "./routes/trucks.js";

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN || "http://localhost:5173" }));
app.use(express.json({ limit: "1mb" }));

// Public, unauthenticated health check — must be reachable by Render's own
// health checks and external uptime pingers (UptimeRobot etc.) without a
// login. Registered before any router that applies its own requireAuth
// middleware globally (extras.js does `router.use(requireAuth)`, which
// would otherwise swallow this same path and return 401 first).
app.get("/health", (_req, res) => res.json({ status: "ok" }));

app.use("/trucks", trucks);
app.use("/cargo", cargo);
app.use("/recommendations", recommendations);
app.use("/bookings", bookings);
app.use("/admin", admin);
app.use("/", extras);
app.use("/", misc);

app.use((_req, res) => res.status(404).json({ error: "NOT_FOUND", message: "Route not found." }));
app.use(errorHandler);

const port = process.env.PORT || 8000;
app.listen(port, () => console.log(`Redo backend on :${port}`));
