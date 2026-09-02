import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/ui_components.dart';

class AvailableLoadsScreen extends StatefulWidget {
  const AvailableLoadsScreen({super.key});

  @override
  State<AvailableLoadsScreen> createState() => _AvailableLoadsScreenState();
}

class _AvailableLoadsScreenState extends State<AvailableLoadsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PartnerTripsViewModel>().fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.watch<PartnerTripsViewModel>();
    final loads = tripsVM.availableLoads;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Available Return Loads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => tripsVM.fetchAll(),
          ),
        ],
      ),
      body: tripsVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : loads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                      const SizedBox(height: 12),
                      Text('All return loads on your corridor booked!', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: loads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final load = loads[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bolt, size: 14, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${load.matchScore}% Route Match',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  load.pickupWindow,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.circle, color: AppColors.success, size: 10),
                                const SizedBox(width: 8),
                                Expanded(child: Text(load.origin, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15))),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(height: 14, width: 2, color: AppColors.border),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.danger, size: 14),
                                const SizedBox(width: 6),
                                Expanded(child: Text(load.destination, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${load.smeName} • ${load.cargoType} • ${load.weightTons} Tons',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Guaranteed Payout', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                                    Text(
                                      currency.format(load.offeredPriceInr),
                                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.slateDark),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 140,
                                  child: RedoButton(
                                    title: 'Accept Load',
                                    onPressed: () {
                                      tripsVM.acceptLoad(load);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Load accepted! Added to Active Trips.')),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
