# REDO — Smart Backhaul & Freight Logistics Platform

> **Uber for Logistics**: Separate, dedicated portals for **Truck Owners** (Drivers/Fleet) and **Customers** (Shippers/SMEs), powered by a unified Supabase database and intelligent backend engine.

---

## 🏛 Architecture Overview

```
redo-smart-logistics/
├── frontend-owner/       # 🚛 TRUCK OWNER PORTAL (Port 5173 / redo-trucks.vercel.app)
│   ├── src/
│   │   ├── pages/        # Dashboard, MyTrucks, AvailableLoads, Bookings, Earnings, Trips, Payments, Documents, Reviews, Support, Settings
│   │   ├── components/   # OwnerLayout, MapPanel, ui primitives
│   │   └── hooks/        # useAuth (Truck Owner role)
├── frontend-customer/    # 📦 CUSTOMER / SHIPPER PORTAL (Port 5174 / redo-customer.vercel.app)
│   ├── src/
│   │   ├── pages/        # Dashboard, BookShipment, PostCargo, Recommendations, Shipments, Invoices, Addresses, RateCard, Support, Profile
│   │   ├── components/   # CustomerLayout, MapPanel, ui primitives
│   │   └── hooks/        # useAuth (Customer / SME role)
├── shared/               # 🔄 Shared contracts, types, Supabase client
├── backend/              # ⚡ Express Node.js API (Render)
├── ml-service/           # 🧠 Python FastAPI Match Engine
└── supabase/             # 🗄 SQL Migrations, RLS, Storage Buckets
```

---

## 🚀 How to Run Locally

```bash
# 1. Run Truck Owner Website (http://localhost:5173)
npm run dev:owner

# 2. Run Customer Website (http://localhost:5174)
npm run dev:customer

# 3. Run Backend API (http://localhost:8000)
npm run dev:backend
```

---

## 🌐 Deployment Guide (Vercel)

Deploying both frontends independently on Vercel is simple because each project is completely self-contained.

### 1. Deploy Truck Owner Portal (`redo-trucks`)
1. Go to [Vercel Dashboard](https://vercel.com/new) and import your `redo-smart-logistics` repo.
2. In **Project Settings**:
   - **Project Name**: `redo-trucks` (or your choice)
   - **Root Directory**: Click *Edit* and select `frontend-owner`
   - **Framework Preset**: `Vite` (auto-detected)
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
3. Add **Environment Variables**:
   - `VITE_API_URL`: `https://your-backend.onrender.com` (or your Render URL)
4. Click **Deploy**.

---

### 2. Deploy Customer Portal (`redo-customer`)
1. In Vercel, click **Add New...** → **Project** and select the same `redo-smart-logistics` repo.
2. In **Project Settings**:
   - **Project Name**: `redo-customer` (or your choice)
   - **Root Directory**: Click *Edit* and select `frontend-customer`
   - **Framework Preset**: `Vite` (auto-detected)
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
3. Add **Environment Variables**:
   - `VITE_API_URL`: `https://your-backend.onrender.com`
4. Click **Deploy**.

---

### 3. Backend (Render)
1. On Render, set your environment variable:
   - `CORS_ORIGIN`: `https://redo-trucks.vercel.app,https://redo-customer.vercel.app,http://localhost:5173,http://localhost:5174`

---

## 🔄 Two-Way Live Booking Flow

```
Customer Portal (Rider)                  Truck Owner Portal (Driver)
──────────────────────                  ───────────────────────────
1. Posts shipment requirement      ───►  2. Sees instant load on "Available Loads"
                                   ◄───  3. Accepts load with selected truck
4. Gets booking confirmation       ───►  5. Manages trip: Pickup → In Transit → Delivered
6. Tracks live GPS & uploads POD   ◄───  7. Receives instant payout in Wallet
```
