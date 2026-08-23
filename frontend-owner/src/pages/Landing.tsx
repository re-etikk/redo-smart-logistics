import { Link } from 'react-router-dom'
import { Truck, IndianRupee, ShieldCheck, MapPin } from 'lucide-react'

export default function Landing() {
  return (
    <div className="min-h-screen bg-canvas text-ink font-sans">
      <header className="px-6 py-4 flex items-center justify-between border-b border-line bg-white">
        <div className="font-black text-2xl tracking-tight text-ink">
          redo <span className="text-amber-500 text-sm align-top">OWNER</span>
        </div>
        <div className="flex gap-4">
          <Link to="/login" className="font-bold text-sm px-4 py-2 hover:bg-slate-50 rounded-xl transition">Login</Link>
          <Link to="/signup" className="font-black text-sm px-4 py-2 bg-brand hover:bg-brand-dark text-brand-ink rounded-xl transition shadow-sm">
            Register as Truck Owner
          </Link>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6 py-20 text-center space-y-12">
        <div className="space-y-4 max-w-3xl mx-auto">
          <h1 className="text-5xl font-black tracking-tight leading-tight">
            Grow Your Trucking Business with <span className="text-amber-500">REDO</span>
          </h1>
          <p className="text-lg text-ink-soft font-medium">
            India's smartest freight platform. Register your trucks, get matched with loads, and earn more.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 pt-10">
          <div className="bg-white p-6 rounded-2xl shadow-card border border-line space-y-3">
            <div className="w-12 h-12 bg-amber-50 text-amber-600 rounded-xl flex items-center justify-center mb-4 mx-auto">
              <MapPin size={24} />
            </div>
            <h3 className="font-black">Get Matched with Loads</h3>
            <p className="text-sm text-ink-soft">Find loads on your preferred routes instantly.</p>
          </div>
          <div className="bg-white p-6 rounded-2xl shadow-card border border-line space-y-3">
            <div className="w-12 h-12 bg-emerald-50 text-emerald-600 rounded-xl flex items-center justify-center mb-4 mx-auto">
              <IndianRupee size={24} />
            </div>
            <h3 className="font-black">Track Earnings</h3>
            <p className="text-sm text-ink-soft">Detailed insights and clear view of all payments.</p>
          </div>
          <div className="bg-white p-6 rounded-2xl shadow-card border border-line space-y-3">
            <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center mb-4 mx-auto">
              <Truck size={24} />
            </div>
            <h3 className="font-black">Manage Fleet</h3>
            <p className="text-sm text-ink-soft">Manage all your trucks and documents in one place.</p>
          </div>
          <div className="bg-white p-6 rounded-2xl shadow-card border border-line space-y-3">
            <div className="w-12 h-12 bg-purple-50 text-purple-600 rounded-xl flex items-center justify-center mb-4 mx-auto">
              <ShieldCheck size={24} />
            </div>
            <h3 className="font-black">Fast Payments</h3>
            <p className="text-sm text-ink-soft">Get paid directly in your bank quickly and securely.</p>
          </div>
        </div>
      </main>
    </div>
  )
}
