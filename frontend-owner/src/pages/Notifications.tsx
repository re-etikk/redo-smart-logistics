import OwnerLayout from "../components/OwnerLayout"

export default function Notifications() {
  return (
    <OwnerLayout activeTab="dashboard">
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
        <h1 className="text-2xl font-black mb-4">Notifications</h1>
        <div className="text-slate-500 text-sm">No new notifications.</div>
      </div>
    </OwnerLayout>
  )
}
