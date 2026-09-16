import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/ui_components.dart';

const _cities = ['Mumbai', 'Delhi NCR', 'Pune', 'Jaipur', 'Surat', 'Ahmedabad', 'Bengaluru', 'Chennai', 'Kolkata', 'Hyderabad'];

class MyTrucksScreen extends StatefulWidget {
  const MyTrucksScreen({super.key});

  @override
  State<MyTrucksScreen> createState() => _MyTrucksScreenState();
}

class _MyTrucksScreenState extends State<MyTrucksScreen> {
  List<TruckModel>? _trucks;
  String? _openFor;
  String _from = 'Mumbai';
  String _to = 'Delhi NCR';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await SupabaseService.getMyTrucks();
      if (mounted) setState(() => _trucks = t);
    } catch (_) {
      if (mounted) setState(() => _trucks ??= []);
    }
  }

  Future<void> _postTrip(TruckModel t) async {
    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and To must be different.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await SupabaseService.postReturnTrip(
        truckId: t.truckId,
        origin: _from,
        destination: _to,
        capacityTons: t.defaultCapacityTons,
      );
      setState(() => _openFor = null);
      if (mounted) {
        context.read<PartnerTripsViewModel>().fetchAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Return trip posted! You are now matchable on this corridor.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  void _showAddTruckModal(BuildContext context) {
    final regCtrl = TextEditingController();
    String truckType = '32ft MXL Container';
    String bodyType = 'Container';
    double capacityTons = 16.0;
    String homeOrigin = 'Delhi NCR';
    bool saving = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.slateDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Register Commercial Truck',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Add your commercial vehicle to receive live load matches',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: regCtrl,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Registration Number (e.g. DL01AB1234)',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: truckType,
                      decoration: InputDecoration(
                        labelText: 'Truck Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Tata Ace (1.5T)', child: Text('Tata Ace (1.5T)')),
                        DropdownMenuItem(value: '14ft Eicher (4T)', child: Text('14ft Eicher (4T)')),
                        DropdownMenuItem(value: '19ft Container (7T)', child: Text('19ft (7T)')),
                        DropdownMenuItem(value: '24ft Heavy (10T)', child: Text('24ft (10T)')),
                        DropdownMenuItem(value: '32ft MXL Container', child: Text('32ft MXL (16T)')),
                        DropdownMenuItem(value: '40ft Trailer (25T+)', child: Text('40ft Trailer (25T)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            truckType = val;
                            if (val.contains('1.5')) capacityTons = 1.5;
                            else if (val.contains('4T')) capacityTons = 4.0;
                            else if (val.contains('7T')) capacityTons = 7.0;
                            else if (val.contains('10T')) capacityTons = 10.0;
                            else if (val.contains('16T') || val.contains('32ft')) capacityTons = 16.0;
                            else if (val.contains('25T')) capacityTons = 25.0;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: bodyType,
                      decoration: InputDecoration(
                        labelText: 'Body Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Container', child: Text('Container (Closed)')),
                        DropdownMenuItem(value: 'Open Body', child: Text('Open Body (Tarpaulin)')),
                        DropdownMenuItem(value: 'Flatbed', child: Text('Flatbed Trailer')),
                        DropdownMenuItem(value: 'Reefer', child: Text('Refrigerated (Reefer)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => bodyType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: homeOrigin,
                decoration: InputDecoration(
                  labelText: 'Home Depot / Base City',
                  prefixIcon: const Icon(Icons.home_work_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setSheetState(() => homeOrigin = val);
                },
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandYellow,
                    foregroundColor: AppColors.slateDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: saving ? null : () async {
                    final reg = regCtrl.text.trim().toUpperCase();
                    if (reg.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter vehicle registration number.')),
                      );
                      return;
                    }
                    setSheetState(() => saving = true);
                    try {
                      await SupabaseService.saveTruckStep(
                        registrationNumber: reg,
                        truckType: truckType,
                        bodyType: bodyType,
                        capacityTons: capacityTons,
                        homeOrigin: homeOrigin,
                        emptyReturnFrom: homeOrigin == 'Mumbai' ? 'Delhi NCR' : 'Mumbai',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _load();
                      if (context.mounted) {
                        context.read<PartnerTripsViewModel>().fetchAll();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ Truck $reg registered and verified!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      setSheetState(() => saving = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Registration failed: $e')),
                        );
                      }
                    }
                  },
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slateDark))
                      : Text('Save & Register Truck', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chips(String value, ValueChanged<String> onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in _cities)
          ChoiceChip(
            label: Text(c, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
            selected: value == c,
            selectedColor: AppColors.brandYellow,
            onSelected: (_) => onTap(c),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trucks = _trucks ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Commercial Trucks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.brandYellowDark),
            tooltip: 'Register Commercial Truck',
            onPressed: () => _showAddTruckModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandYellow,
        foregroundColor: AppColors.slateDark,
        icon: const Icon(Icons.add),
        label: Text('Register Truck', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        onPressed: () => _showAddTruckModal(context),
      ),
      body: RefreshIndicator(
        color: AppColors.brandYellow,
        onRefresh: _load,
        child: _trucks != null && trucks.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 60),
                  const Center(
                    child: Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.brandYellow),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No Commercial Trucks Registered',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Register your freight truck to receive instant loads and return corridor trips.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandYellow,
                        foregroundColor: AppColors.slateDark,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text('Register Commercial Truck', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                      onPressed: () => _showAddTruckModal(context),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: trucks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final t = trucks[i];
                  final open = _openFor == t.truckId;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${t.truckType} • ${t.registrationNumber}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            StatusBadge(status: t.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.bodyType} • ${t.defaultCapacityTons} T • Home: ${t.homeOrigin}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                        ),
                        const SizedBox(height: 12),
                        RedoButton(
                          title: open ? 'Close' : '+ Post Return Trip',
                          isSecondary: true,
                          onPressed: () => setState(() => _openFor = open ? null : t.truckId),
                        ),
                        if (open) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Empty at (From)',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: 6),
                          _chips(_from, (v) => setState(() => _from = v)),
                          const SizedBox(height: 10),
                          Text(
                            'Returning to',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: 6),
                          _chips(_to, (v) => setState(() => _to = v)),
                          const SizedBox(height: 12),
                          RedoButton(
                            title: _busy ? 'Posting…' : 'Post Trip (Tomorrow 10 AM)',
                            onPressed: _busy ? null : () => _postTrip(t),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
