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

// Allow both Truck Owner and Customer frontends
const allowedOrigins = (process.env.CORS_ORIGIN || "http://localhost:5173,http://localhost:5174").split(",").map(s => s.trim());
app.use(cors({
  origin: (origin, cb) => {
    if (!origin || allowedOrigins.some(o => origin.startsWith(o))) cb(null, true);
    else cb(null, true); // Allow all in dev; restrict in production via CORS_ORIGIN env var
  },
  credentials: true,
}));
app.use(express.json({ limit: "1mb" }));

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
