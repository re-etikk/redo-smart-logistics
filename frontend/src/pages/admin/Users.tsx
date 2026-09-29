import { useEffect, useState, useMemo } from "react";
import { 
  Users, ShieldCheck, ShieldAlert, UserCheck, Search, RefreshCw, 
  Phone, Building2, Calendar, UserX, Crown
} from "lucide-react";
import Layout from "../../components/Layout";
import { useAuth } from "../../hooks/useAuth";
import { api } from "../../services/api";
import { Badge, Button, Card, CardSkeleton, SectionHead, useToast } from "../../components/ui";

interface UserProfile {
  id: string;
  full_name: string;
  email?: string | null;
  company_name?: string;
  role: 'admin' | 'truck_owner' | 'sme';
  admin_previous_role?: 'truck_owner' | 'sme' | null;
  phone?: string;
  status?: 'active' | 'suspended';
  created_at: string;
}

export default function AdminUsers() {
  const [users, setUsers] = useState<UserProfile[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionBusyId, setActionBusyId] = useState<string | null>(null);
  const [roleFilter, setRoleFilter] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const toast = useToast();
  const { profile: currentAdmin } = useAuth();

  const loadUsers = async () => {
    setLoading(true);
    try {
      const res = await api.get<UserProfile[]>("/admin/users");
      setUsers(Array.isArray(res) ? res : []);
    } catch (err) {
      console.error('Error fetching users:', err);
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const handleRoleChange = async (userId: string, newRole: 'admin' | 'truck_owner' | 'sme') => {
    setActionBusyId(userId);
    try {
      await api.patch(`/admin/users/${userId}/role`, { role: newRole });
      toast(`User role updated to ${newRole.toUpperCase()}`, "ok");
      loadUsers();
    } catch (err: any) {
      toast(err?.message || "Failed to update role", "danger");
    } finally {
      setActionBusyId(null);
    }
  };

  const handleStatusToggle = async (userId: string, currentStatus?: string) => {
    const nextStatus = currentStatus === 'suspended' ? 'active' : 'suspended';
    setActionBusyId(userId);
    try {
      await api.patch(`/admin/users/${userId}/role`, { status: nextStatus });
      toast(`User marked ${nextStatus}`, "ok");
      loadUsers();
    } catch (err: any) {
      toast(err?.message || "Failed to update status", "danger");
    } finally {
      setActionBusyId(null);
    }
  };

  const counts = useMemo(() => {
    const list = users ?? [];
    return {
      total: list.length,
      admins: list.filter(u => u.role === 'admin').length,
      owners: list.filter(u => u.role === 'truck_owner').length,
      shippers: list.filter(u => u.role === 'sme').length,
    };
  }, [users]);

  const filteredUsers = useMemo(() => {
    const list = users ?? [];
    return list.filter(u => {
      const matchRole = roleFilter === "all" || u.role === roleFilter;
      const q = searchQuery.toLowerCase().trim();
      if (!q) return matchRole;
      const matchQuery = 
        u.full_name.toLowerCase().includes(q) ||
        (u.email && u.email.toLowerCase().includes(q)) ||
        (u.company_name && u.company_name.toLowerCase().includes(q)) ||
        (u.phone && u.phone.includes(q)) ||
        u.role.toLowerCase().includes(q);
      return matchRole && matchQuery;
    });
  }, [users, roleFilter, searchQuery]);

  return (
    <Layout>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <SectionHead 
          title="User Directory & Access Control" 
          sub="Platform user directory with 1-click administrator approval, partner verification, and account status governance." 
        />
        <div className="flex items-center gap-2">
          <Button 
            variant="secondary" 
            onClick={loadUsers} 
            disabled={loading}
            className="gap-2 bg-slate-900 border-slate-800 text-slate-300 hover:text-white"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            <span>Refresh</span>
          </Button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="mt-5 grid grid-cols-2 sm:grid-cols-4 gap-3">
        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">Total Accounts</span>
            <Users size={16} className="text-amber-400" />
          </div>
          <p className="text-2xl font-black text-white mt-1">{counts.total}</p>
          <span className="text-[10px] text-slate-500">Registered platform users</span>
        </Card>

        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">Administrators</span>
            <Crown size={16} className="text-amber-400" />
          </div>
          <p className="text-2xl font-black text-amber-400 mt-1">{counts.admins}</p>
          <span className="text-[10px] text-slate-500">Super-users with clearance</span>
        </Card>

        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">Truck Partners</span>
            <UserCheck size={16} className="text-sky-400" />
          </div>
          <p className="text-2xl font-black text-sky-400 mt-1">{counts.owners}</p>
          <span className="text-[10px] text-slate-500">Drivers & Fleet Operators</span>
        </Card>

        <Card className="p-4 bg-slate-900/90 border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">Shippers</span>
            <Building2 size={16} className="text-emerald-400" />
          </div>
          <p className="text-2xl font-black text-emerald-400 mt-1">{counts.shippers}</p>
          <span className="text-[10px] text-slate-500">SME cargo consignors</span>
        </Card>
      </div>

      {/* Filter Tabs & Search */}
      <div className="mt-6 flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="flex flex-wrap gap-1.5 p-1 bg-slate-900 border border-slate-800 rounded-xl">
          {[
            { id: "all", label: `All Users (${counts.total})` },
            { id: "admin", label: `Admins (${counts.admins})` },
            { id: "truck_owner", label: `Truck Partners (${counts.owners})` },
            { id: "sme", label: `Shippers (${counts.shippers})` },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setRoleFilter(tab.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                roleFilter === tab.id
                  ? "bg-amber-400 text-slate-950 shadow-sm"
                  : "text-slate-400 hover:text-white"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div className="relative min-w-[260px]">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search name, phone, company…"
            className="w-full pl-9 pr-3 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>
      </div>

      {/* Users Table */}
      <Card className="mt-4 p-0 bg-slate-900/90 border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        {loading ? (
          <div className="p-6"><CardSkeleton /></div>
        ) : filteredUsers.length === 0 ? (
          <div className="p-12 text-center text-slate-500">
            <p className="font-bold text-slate-300">No users found</p>
            <p className="text-xs mt-1">Try adjusting your filters or search keywords.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[700px]">
              <thead className="bg-slate-950/60 border-b border-slate-800 text-[11px] font-black uppercase tracking-wider text-slate-400">
                <tr>
                  <th className="py-3 px-4">User Details</th>
                  <th className="py-3 px-4">Company / Entity</th>
                  <th className="py-3 px-4">Phone / Contact</th>
                  <th className="py-3 px-4">Current Role</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4 text-right">Admin Governance</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60">
                {filteredUsers.map((u) => {
                  const isBusy = actionBusyId === u.id;
                  const isAdmin = u.role === 'admin';
                  const isSuspended = u.status === 'suspended';

                  return (
                    <tr key={u.id} className="hover:bg-slate-800/30 transition">
                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-2">
                          <div className={`w-7 h-7 rounded-lg flex items-center justify-center font-bold text-xs ${
                            isAdmin ? 'bg-amber-400/20 text-amber-400 border border-amber-400/30' : 'bg-slate-800 text-slate-300'
                          }`}>
                            {isAdmin ? <Crown size={14} /> : u.full_name[0]?.toUpperCase() || 'U'}
                          </div>
                          <div>
                            <span className="font-bold text-white block">{u.full_name}</span>
                            {u.email && <span className="text-[10px] text-slate-400 block">{u.email}</span>}
                            <span className="text-[10px] text-slate-500 font-mono">
                              Joined {new Date(u.created_at).toLocaleDateString("en-IN", { month: "short", day: "numeric", year: "numeric" })}
                            </span>
                          </div>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 text-slate-300">
                        {u.company_name || <span className="text-slate-600">—</span>}
                      </td>

                      <td className="py-3.5 px-4 font-mono text-slate-300">
                        {u.phone || <span className="text-slate-600">—</span>}
                      </td>

                      <td className="py-3.5 px-4">
                        <span className={`px-2 py-0.5 rounded text-[10px] font-black uppercase ${
                          isAdmin 
                            ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' 
                            : u.role === 'truck_owner'
                            ? 'bg-sky-500/20 text-sky-400 border border-sky-500/30'
                            : 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                        }`}>
                          {isAdmin ? 'Admin' : u.role === 'truck_owner' ? 'Truck Partner' : 'Shipper'}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        <Badge tone={isSuspended ? "danger" : "ok"}>
                          {isSuspended ? "Suspended" : "Active"}
                        </Badge>
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          {/* 1-Click Make / Revoke Admin Button */}
                          {isAdmin ? (
                            <Button
                              variant="secondary"
                              onClick={() => handleRoleChange(u.id, u.admin_previous_role || 'sme')}
                              disabled={isBusy || u.id === currentAdmin?.id}
                              className="!py-1 !px-2.5 text-[11px] bg-slate-800 hover:bg-rose-950 hover:text-rose-400 text-slate-300 border-slate-700"
                            >
                              Revoke Admin
                            </Button>
                          ) : (
                            <Button
                              onClick={() => handleRoleChange(u.id, 'admin')}
                              disabled={isBusy || u.id === currentAdmin?.id}
                              className="!py-1 !px-2.5 text-[11px] bg-amber-400 hover:bg-amber-500 text-slate-950 font-bold"
                            >
                              Grant Admin
                            </Button>
                          )}

                          {/* Suspend / Reactivate Toggle */}
                          <button
                            onClick={() => handleStatusToggle(u.id, u.status)}
                            disabled={isBusy || u.id === currentAdmin?.id}
                            title={isSuspended ? "Reactivate User" : "Suspend User"}
                            className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white transition"
                          >
                            {isSuspended ? <UserCheck size={14} className="text-emerald-400" /> : <UserX size={14} className="text-rose-400" />}
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </Layout>
  );
}
