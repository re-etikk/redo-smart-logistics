import { Link, useNavigate } from 'react-router-dom';
import { Logo } from '../components/Layout';
import { Button, Card } from '../components/ui';

function RouteViz() {
  const steps = [
    'Loaded outbound trip', 'Delivery completed', 'Return journey',
    'Spare capacity', 'SME cargo matched',
  ];
  return (
    <Card className="p-6">
      <ol className="space-y-0">
        {steps.map((s, i) => (
          <li key={s} className="flex items-start gap-3">
            <div className="flex flex-col items-center">
              <span className={`h-7 w-7 rounded-full grid place-items-center text-xs font-bold
                ${i === steps.length - 1 ? 'bg-ok text-white' : 'bg-accent-soft text-accent'}`}>{i + 1}</span>
              {i < steps.length - 1 && <span className="w-0.5 h-6 bg-line" />}
            </div>
            <p className={`pt-1 text-sm font-semibold ${i === steps.length - 1 ? 'text-ok' : 'text-ink'}`}>{s}</p>
          </li>
        ))}
      </ol>
      <div className="mt-5 rounded-lg bg-canvas border border-line p-4">
        <div className="flex justify-between text-xs font-semibold text-ink-faint mb-1">
          <span>Return capacity used</span><span>1.5 / 4.0 T matched</span>
        </div>
        <div className="h-2.5 rounded-full bg-ink/10 overflow-hidden">
          <div className="h-full rounded-full bg-accent" style={{ width: '37.5%' }} />
        </div>
      </div>
    </Card>
  );
}

export default function Landing() {
  const navigate = useNavigate();
  return (
    <div className="min-h-screen bg-canvas">
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur border-b border-line">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center justify-between">
          <Logo />
          <nav className="hidden md:flex items-center gap-5 text-sm font-medium text-ink-soft" aria-label="Landing">
            <a href="#how" className="hover:text-ink">How it works</a>
            <a href="#owners" className="hover:text-ink">For truck owners</a>
            <a href="#smes" className="hover:text-ink">For SMEs</a>
          </nav>
          <div className="flex items-center gap-2">
            <Link to="/login"><Button variant="ghost">Sign in</Button></Link>
            <Link to="/signup"><Button>Get started</Button></Link>
          </div>
        </div>
      </header>

      <section className="mx-auto max-w-6xl px-4 pt-14 pb-16 grid gap-10 lg:grid-cols-2 items-center">
        <div>
          <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-ink">Make every return trip earn.</h1>
          <p className="mt-4 text-lg text-ink-soft max-w-md">
            Connect unused truck capacity with affordable SME freight on the same route.
          </p>
          <p className="mt-3 text-sm text-ink-soft max-w-md">
            We are not finding a truck for cargo — we are finding cargo for trucks that are already going there.
          </p>
          <div className="mt-7 flex flex-wrap gap-3">
            <Button onClick={() => navigate('/signup?role=sme')}>Find transport</Button>
            <Button variant="secondary" onClick={() => navigate('/signup?role=truck_owner')}>Use my truck</Button>
          </div>
          <p className="mt-6 text-xs text-ink-faint max-w-md">
            Studies attributed to NITI Aayog estimate a significant share of truck kilometres in India run empty or
            underutilized (commonly cited at 28–43%). Redo targets exactly this waste on return legs.
          </p>
        </div>
        <RouteViz />
      </section>

      <section id="how" className="bg-white border-y border-line">
        <div className="mx-auto max-w-6xl px-4 py-14">
          <h2 className="text-2xl font-extrabold text-ink">How it works</h2>
          <div className="mt-6 grid gap-4 md:grid-cols-3">
            {[
              ['Post', 'Owners post return trips with spare tonnes. SMEs post partial loads.'],
              ['Match', 'Hard filters check route, timing and capacity; the ML model ranks eligible trucks by predicted match success.'],
              ['Deliver', 'Book, track the shipment, upload pickup and delivery proof, and see the measured impact.'],
            ].map(([t, d]) => (
              <Card key={t} className="p-5">
                <p className="font-bold text-ink">{t}</p>
                <p className="mt-1 text-sm text-ink-soft">{d}</p>
              </Card>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-4 py-14 grid gap-6 md:grid-cols-2">
        <Card id="owners" className="p-6">
          <h3 className="text-lg font-bold text-ink">For truck owners</h3>
          <p className="mt-1 text-sm text-ink-soft">Turn empty return kilometres into income. Post your return leg once and get ranked cargo matches with estimated earnings.</p>
          <Button className="mt-5" variant="secondary" onClick={() => navigate('/signup?role=truck_owner')}>Start earning on returns</Button>
        </Card>
        <Card id="smes" className="p-6">
          <h3 className="text-lg font-bold text-ink">For SMEs</h3>
          <p className="mt-1 text-sm text-ink-soft">Ship 1–3 tonne loads without paying for a full truck. Verified owners, transparent pricing, tracking and digital proof.</p>
          <Button className="mt-5" variant="secondary" onClick={() => navigate('/signup?role=sme')}>Ship a partial load</Button>
        </Card>
      </section>

      <footer className="border-t border-line">
        <div className="mx-auto max-w-6xl px-4 py-8 flex flex-wrap items-center justify-between gap-3 text-xs text-ink-faint">
          <span>REDO — Smart Backhaul Network · Match. Consolidate. Trust. Track. Optimize.</span>
          <span>Built for Smart India Hackathon</span>
        </div>
      </footer>
    </div>
  );
}
