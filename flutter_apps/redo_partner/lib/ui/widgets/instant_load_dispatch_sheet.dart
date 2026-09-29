import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/models/models.dart';

class InstantLoadDispatchSheet extends StatefulWidget {
  final AvailableLoad load;
  final int secondsRemaining;
  final Future<void> Function() onAccept;
  final VoidCallback onDecline;

  const InstantLoadDispatchSheet({
    super.key,
    required this.load,
    required this.secondsRemaining,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<InstantLoadDispatchSheet> createState() =>
      _InstantLoadDispatchSheetState();
}

class _InstantLoadDispatchSheetState extends State<InstantLoadDispatchSheet> {
  bool _accepting = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _error = null;
    });
    try {
      await widget.onAccept();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final load = widget.load;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final progress = (widget.secondsRemaining / 45).clamp(0.0, 1.0);

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.brandYellow, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandYellow.withValues(alpha: 0.2),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, color: AppColors.brandYellow),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'INSTANT LOAD DISPATCH',
                            style: GoogleFonts.inter(
                              color: AppColors.brandYellow,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 4,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation(
                                  widget.secondsRemaining > 15
                                      ? AppColors.brandYellow
                                      : AppColors.danger,
                                ),
                              ),
                              Text(
                                '${widget.secondsRemaining}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'ESTIMATED DRIVER PAYOUT',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      currency.format(load.offeredPriceInr),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.trip_origin, color: Colors.greenAccent, size: 18),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(load.origin, style: _routeStyle),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(width: 2, height: 17, color: Colors.white24),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(load.destination, style: _routeStyle),
                        ),
                        if (load.distanceKm > 0)
                          Text(
                            '${load.distanceKm.round()} km',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _detailChip('${load.weightTons.toStringAsFixed(1)} T'),
                        _detailChip(load.cargoType),
                        _detailChip(load.pickupWindow),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _accepting ? null : widget.onDecline,
                          child: Text('Decline', style: GoogleFonts.inter(color: Colors.white70)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _accepting ? null : _accept,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandYellow,
                              foregroundColor: AppColors.slateDark,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: _accepting
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_circle),
                            label: Text(
                              _accepting ? 'ACCEPTING…' : 'ACCEPT LOAD',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _routeStyle => GoogleFonts.inter(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      );

  Widget _detailChip(String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          value,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
}