import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../misc/notifications_screen.dart';
import 'tracking_screen.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ShipmentsViewModel>().fetchShipments());
  }

  @override
  Widget build(BuildContext context) {
    final shipmentsVM = context.watch<ShipmentsViewModel>();
    final shipments = shipmentsVM.shipments;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('My Shipments'),
        actions: [
          const NotificationsBell(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => shipmentsVM.fetchShipments(),
          ),
        ],
      ),
      body: shipmentsVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shipments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.inkMuted),
                      const SizedBox(height: 12),
                      Text('No shipments yet.', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: shipments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final s = shipments[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TrackingScreen(booking: s)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(s.id, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                                  StatusBadge(status: s.status),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.circle, color: AppColors.success, size: 10),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(s.origin, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14))),
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
                                  Expanded(child: Text(s.destination, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${s.cargoType} • ${s.weightTons} T',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                                  ),
                                  Text(
                                    currency.format(s.agreedPriceInr),
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slateDark),
                                  ),
                                ],
                              ),
                              if ((s.status == 'confirmed' || s.status == 'pickup_ready') && s.pickupOtp != null) ...[
                                const SizedBox(height: 10),
                                _OtpChip(label: 'PICKUP OTP - share with driver at loading', otp: s.pickupOtp!),
                              ],
                              if ((s.status == 'picked_up' || s.status == 'in_transit') && s.deliveryOtp != null) ...[
                                const SizedBox(height: 10),
                                _OtpChip(label: 'DELIVERY OTP - share with receiver', otp: s.deliveryOtp!),
                              ],
                              if (s.pickupOtp != null &&
                                  const ['confirmed', 'pickup_ready'].contains(s.status)) ...[
                                const SizedBox(height: 10),
                                _OtpChip(label: 'PICKUP OTP - share with driver at loading', otp: s.pickupOtp!),
                              ],
                              if (s.deliveryOtp != null &&
                                  const ['picked_up', 'in_transit'].contains(s.status)) ...[
                                const SizedBox(height: 10),
                                _OtpChip(label: 'DELIVERY OTP - share on arrival', otp: s.deliveryOtp!),
                              ],
                              if (s.status == 'accepted' || s.status == 'delivered') ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.brandYellow,
                                      foregroundColor: AppColors.slateDark,
                                    ),
                                    onPressed: () async {
                                      final vm = context.read<ShipmentsViewModel>();
                                      String? err;
                                      if (s.status == 'accepted') {
                                        err = await vm.confirmBooking(s);
                                      } else {
                                        err = await vm.completeBooking(s);
                                        if (err == null && context.mounted) {
                                          final stars = await showDialog<int>(
                                            context: context,
                                            builder: (ctx) => SimpleDialog(
                                              title: const Text('Rate this trip'),
                                              children: [
                                                for (var n = 5; n >= 1; n--)
                                                  SimpleDialogOption(
                                                    onPressed: () => Navigator.pop(ctx, n),
                                                    child: Text('${'★' * n} ($n)'),
                                                  ),
                                              ],
                                            ),
                                          );
                                          if (stars != null) err = await vm.rate(s, stars);
                                        }
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(err ??
                                              (s.status == 'accepted'
                                                  ? 'Truck confirmed! Driver has been notified.'
                                                  : 'Trip completed - invoice generated, payout settled.')),
                                        ));
                                      }
                                    },
                                    child: Text(
                                      s.status == 'accepted'
                                          ? 'Confirm this Truck'
                                          : 'Mark Completed & Rate',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _OtpChip extends StatelessWidget {
  final String label;
  final String otp;
  const _OtpChip({required this.label, required this.otp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandYellow, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkMuted)),
          ),
          Text(otp.split('').join(' '),
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.slateDark)),
        ],
      ),
    );
  }
}
