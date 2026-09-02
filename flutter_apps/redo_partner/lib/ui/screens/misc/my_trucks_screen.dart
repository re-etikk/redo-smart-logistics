import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/ui_components.dart';

const _cities = ['Mumbai', 'Delhi NCR', 'Pune', 'Jaipur', 'Surat', 'Ahmedabad'];

/// My trucks + "+ Post Return Trip" — the wiring that keeps a truck matchable.
/// Shippers are matched against RETURN TRIPS, so after every run the driver
/// posts the next empty corridor here (exactly like the website's My Trucks).
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
          const SnackBar(content: Text('From and To must be different.')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Return trip posted! You are now matchable on this corridor.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _chips(String value, ValueChanged<String> onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in _cities)
          ChoiceChip(
            label: Text(c,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700)),
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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('My Trucks & Return Trips')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _trucks != null && trucks.isEmpty
            ? ListView(children: [
                const SizedBox(height: 120),
                Center(
                    child: Text('No truck registered yet.',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.w700))),
                Center(
                    child: Text('Complete onboarding to add your truck.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.inkMuted))),
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: trucks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final t = trucks[i];
                  final open = _openFor == t.truckId;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${t.truckType} • ${t.registrationNumber}',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                              StatusBadge(status: t.status),
                            ],
                          ),
                          Text(
                              '${t.bodyType} • ${t.defaultCapacityTons} T • Home: ${t.homeOrigin}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.inkMuted)),
                          const SizedBox(height: 12),
                          RedoButton(
                            title: open ? 'Close' : '+ Post Return Trip',
                            isSecondary: true,
                            onPressed: () => setState(
                                () => _openFor = open ? null : t.truckId),
                          ),
                          if (open) ...[
                            const SizedBox(height: 12),
                            Text('Empty at (From)',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.inkMuted)),
                            const SizedBox(height: 6),
                            _chips(_from, (v) => setState(() => _from = v)),
                            const SizedBox(height: 10),
                            Text('Returning to',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.inkMuted)),
                            const SizedBox(height: 6),
                            _chips(_to, (v) => setState(() => _to = v)),
                            const SizedBox(height: 12),
                            RedoButton(
                              title: _busy
                                  ? 'Posting…'
                                  : 'Post Trip (Tomorrow 10 AM)',
                              onPressed: _busy ? null : () => _postTrip(t),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
