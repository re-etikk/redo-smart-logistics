import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/redo_partner_components.dart';
import 'pickup_verification_screen.dart';

/// Screen 05 — Navigation
/// Faithfully recreates the live driver navigation UI matching Reference 05.
/// Shows turn-by-turn instruction card, full-bleed interactive map,
/// bottom sheet with shipment & customer data, and "Arrived at pickup" action.
class NavigationScreen extends StatefulWidget {
  final ActiveTrip trip;

  const NavigationScreen({super.key, required this.trip});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  bool _isAdvancing = false;

  void _callCustomer(BuildContext context) async {
    final phone = widget.trip.shipperPhone ?? '+919876543210';
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone call to $phone')),
        );
      }
    }
  }

  Future<void> _handleArrivedAtPickup() async {
    if (_isAdvancing) return;
    setState(() => _isAdvancing = true);

    try {
      final tripsVM = context.read<PartnerTripsViewModel>();
      if (widget.trip.status == 'confirmed' || widget.trip.status == 'accepted') {
        await tripsVM.advanceTripStatus(widget.trip);
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PickupVerificationScreen(trip: widget.trip),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAdvancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.watch<PartnerTripsViewModel>();
    final myTruck = tripsVM.myTrucks.isNotEmpty ? tripsVM.myTrucks.first : null;
    final truckReg = myTruck?.registrationNumber ?? 'UP 32 AB 1234';
    final truckCapacity = '${(myTruck?.capacityTons ?? 14).toInt()} Ton capacity';

    final origin = widget.trip.origin.isNotEmpty ? widget.trip.origin : 'Delhi, DL';
    final destination = widget.trip.destination.isNotEmpty ? widget.trip.destination : 'Patna, BR';
    final customerName = widget.trip.shipperName.isNotEmpty ? widget.trip.shipperName : 'Ritik Kumar';
    final cargoName = widget.trip.cargoType.isNotEmpty ? widget.trip.cargoType : 'Mac Mini M4 Pro';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Full-bleed Live Interactive Map
            Positioned.fill(
              child: MapPanel(
                originName: origin,
                destName: destination,
                height: double.infinity,
                showControls: true,
              ),
            ),

            // 2. Top Header with Back, Brand, and Status Chip
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ReDoPartnerColors.lightGrey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Brand
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: ReDoPartnerColors.brandYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: ReDoPartnerColors.darkNavy,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ReDo',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: ReDoPartnerColors.darkNavy,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Partner',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ReDoPartnerColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ReDoPartnerColors.brandYellow.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF9800),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'On the way to pickup',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.more_vert_rounded, color: ReDoPartnerColors.darkNavy),
                  ],
                ),
              ),
            ),

            // 3. Floating Turn-by-Turn Instruction Banner
            Positioned(
              top: 64,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ReDoPartnerColors.darkNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.turn_left_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Turn left in 400 m',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                          Text(
                            'Continue on NH 44',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: ReDoPartnerColors.border,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Pickup in',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: ReDoPartnerColors.secondary,
                          ),
                        ),
                        Text(
                          '3.8 km',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: ReDoPartnerColors.darkNavy,
                          ),
                        ),
                        Text(
                          'ETA 11 min',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Sliding Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: ReDoPartnerColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Shipment row
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ReDoPartnerColors.border),
                          ),
                          child: const Icon(
                            Icons.devices_rounded,
                            size: 24,
                            color: ReDoPartnerColors.darkNavy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shipment',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: ReDoPartnerColors.secondary,
                                ),
                              ),
                              Text(
                                cargoName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: ReDoPartnerColors.darkNavy,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        size: 11, color: ReDoPartnerColors.secondary),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Electronics',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: ReDoPartnerColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(widget.trip.weightTons > 0 ? widget.trip.weightTons * 1000 : 12).toInt()} kg • 2 packages',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: ReDoPartnerColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Two columns: Customer & Vehicle
                    Row(
                      children: [
                        // Customer
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFE2E8F0),
                                child: const Icon(Icons.person_rounded,
                                    size: 22, color: ReDoPartnerColors.darkNavy),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: ReDoPartnerColors.secondary,
                                      ),
                                    ),
                                    Text(
                                      customerName,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: ReDoPartnerColors.darkNavy,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded,
                                            size: 11, color: ReDoPartnerColors.success),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Verified',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: ReDoPartnerColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: ReDoPartnerColors.border,
                        ),
                        const SizedBox(width: 12),
                        // Vehicle
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7DC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_rounded,
                                  size: 20,
                                  color: Color(0xFFB78103),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your vehicle',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: ReDoPartnerColors.secondary,
                                      ),
                                    ),
                                    Text(
                                      truckReg,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: ReDoPartnerColors.darkNavy,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      truckCapacity,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: ReDoPartnerColors.secondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Primary Button: "Arrived at pickup"
                    PartnerButton(
                      title: 'Arrived at pickup',
                      icon: Icons.location_on_rounded,
                      isLoading: _isAdvancing,
                      onPressed: _handleArrivedAtPickup,
                    ),
                    const SizedBox(height: 10),

                    // Secondary Button: "Call customer"
                    PartnerSecondaryButton(
                      title: 'Call customer',
                      icon: Icons.phone_rounded,
                      onPressed: () => _callCustomer(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
