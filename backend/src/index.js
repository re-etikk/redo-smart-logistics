import "dotenv/config";
import cors from "cors";
import express from "express";
import { errorHandler } from "./middleware/error.js";
import admin from "./routes/admin.js";
import bookings from "./routes/bookings.js";
import cargo from "./routes/cargo.js";
import extras from "./routes/extras.js";
import misc from "./routes/misc.js";
import pricing from "./routes/pricing.js";
import recommendations from "./routes/recommendations.js";
import trucks from "./routes/trucks.js";

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN || "*" }));
app.use(express.json({ limit: "1mb" }));

// Public health check
app.get("/health", (_req, res) => res.json({ status: "ok" }));

app.use("/trucks", trucks);
app.use("/cargo", cargo);
app.use("/recommendations", recommendations);
app.use("/pricing", pricing);
app.use("/bookings", bookings);
app.use("/admin", admin);
app.use("/", extras);
app.use("/", misc);

app.use((_req, res) => res.status(404).json({ error: "NOT_FOUND", message: "Route not found." }));
app.use(errorHandler);

const port = process.env.PORT || 8000;
app.listen(port, () => console.log(`Redo backend on :${port}`));
