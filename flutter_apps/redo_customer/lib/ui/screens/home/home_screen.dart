import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../../widgets/redo_design_system.dart';
import '../misc/notifications_screen.dart';
import '../misc/support_screen.dart';
import '../shipments/tracking_screen.dart';
import '../ai/ai_assistant_screen.dart';

/// ReDo Customer App — SCREEN 01: HOME SCREEN
/// Fully native Flutter reconstruction matching the ReDo design system.
class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onTabChangeRequested;
  final VoidCallback? onCreateShipment;

  const HomeScreen({
    super.key,
    this.onTabChangeRequested,
    this.onCreateShipment,
  });

  @override
  Widget build(BuildContext context) {
    final shipmentsVM = context.watch<ShipmentsViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.profile;

    // Check if there is an active shipment in transit or booked
    BookingItem? activeShipment;
    if (shipmentsVM.shipments.isNotEmpty) {
      for (final s in shipmentsVM.shipments) {
        if (s.status.toLowerCase() != 'delivered' &&
            s.status.toLowerCase() != 'cancelled') {
          activeShipment = s;
          break;
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : ReDoColors.warmBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==============================================================
              // 1. TOP BAR: Brand Logo, Notification Bell, User Avatar
              // ==============================================================
              _buildTopBar(context, user),
              const SizedBox(height: 24),

              // ==============================================================
              // 2. GREETING & HEADLINE
              // ==============================================================
              _buildGreetingSection(user),
              const SizedBox(height: 20),

              // ==============================================================
              // 3. HERO CTA CARD: "Send a shipment"
              // ==============================================================
              _buildSendShipmentCard(context),
              const SizedBox(height: 28),

              // ==============================================================
              // 4. SECTION: "Live shipment" + Map & Floating Card
              // ==============================================================
              ReDoSectionHeader(
                title: 'Live shipment',
                actionText: 'View all',
                onActionTap: () => onTabChangeRequested?.call(1),
              ),
              const SizedBox(height: 14),
              _buildLiveShipmentCard(context, activeShipment),
              const SizedBox(height: 24),

              // ==============================================================
              // 5. QUICK ACTIONS: Track Shipment, History, Support
              // ==============================================================
              _buildQuickActionsRow(context),
              const SizedBox(height: 24),

              // ==============================================================
              // 6. PROMOTIONAL BANNER: "Fill empty miles."
              // ==============================================================
              _buildEmptyMilesBanner(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Top Navigation Bar
  // --------------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context, UserProfile? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand Logo
        const ReDoLogo(size: 36, fontSize: 24),

        // Right Actions: AI Assistant + Notification Bell + Avatar
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI Logistics Assistant Button
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AiAssistantScreen(
                      onTabChangeRequested: onTabChangeRequested,
                    ),
                  ),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brandYellow.withValues(alpha: isDark ? 0.6 : 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandYellow.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: AppColors.brandYellow,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Notification Bell with Unread Badge
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.darkBorder : ReDoColors.cardBorder),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 24,
                      color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                    ),
                    Positioned(
                      top: 10,
                      right: 11,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.darkCard : Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Profile Avatar
            GestureDetector(
              onTap: () => onTabChangeRequested?.call(4),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.darkBorder : Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildAvatarImage(user),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarImage(UserProfile? user) {
    final avatar = user?.avatarUrl;
    if (avatar == null || avatar.isEmpty) {
      return _buildAvatarFallback(user);
    }
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return Image.network(
        avatar,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildAvatarFallback(user),
      );
    }
    if (avatar.startsWith('data:image')) {
      try {
        final comma = avatar.indexOf(',');
        final b64 = comma != -1 ? avatar.substring(comma + 1) : avatar;
        return Image.memory(
          base64Decode(b64),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildAvatarFallback(user),
        );
      } catch (_) {
        return _buildAvatarFallback(user);
      }
    }
    try {
      final file = File(avatar);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildAvatarFallback(user),
        );
      }
    } catch (_) {}
    return _buildAvatarFallback(user);
  }

  Widget _buildAvatarFallback(UserProfile? user) {
    return Container(
      color: const Color(0xFFFFECC4),
      child: Center(
        child: Text(
          user?.fullName.isNotEmpty == true
              ? user!.fullName.substring(0, 1).toUpperCase()
              : 'R',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ReDoColors.darkNavy,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Greeting Section
  // --------------------------------------------------------------------------
  Widget _buildGreetingSection(UserProfile? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Good morning',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ReDoColors.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('☀️', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onTabChangeRequested?.call(3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFECC4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE59C0A).withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 5),
                    Text(
                      'Wallet',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'What are you\nmoving today?',
          style: ReDoTypography.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Reliable logistics for a moving India.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ReDoColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Hero CTA Card: "Send a shipment"
  // --------------------------------------------------------------------------
  Widget _buildSendShipmentCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9EE),
            Color(0xFFFFE8B4),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFE2A3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE59C0A).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: () {
            if (onCreateShipment != null) {
              onCreateShipment!();
            } else {
              onTabChangeRequested?.call(2);
            }
          },
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                // Left Column: Text + Yellow Action Button
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Send a shipment',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: ReDoColors.darkNavy,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fast pickup. Reliable delivery.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5A626C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Circular Action Button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ReDoColors.primaryYellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ReDoColors.primaryYellow.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 22,
                            color: ReDoColors.darkNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Column: 3D Isometric Cardboard Box
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 110,
                    child: Center(
                      child: _HeroCardboardBoxGraphic(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Live Shipment Section: Map + Floating Information Card
  // --------------------------------------------------------------------------
  Widget _buildLiveShipmentCard(BuildContext context, BookingItem? activeShipment) {
    final fromCity = activeShipment?.origin ?? 'Delhi';
    final toCity = activeShipment?.destination ?? 'Patna';
    final itemName = activeShipment?.cargoType ?? 'Mac Mini M4 Pro';
    final eta = '4h 20m';
    final status = activeShipment?.status ?? 'In Transit';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ReDoColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Map Visualization Layer
            Positioned.fill(
              child: ReDoMapOverlay(
                fromCity: fromCity,
                toCity: toCity,
                height: 250,
              ),
            ),

            // Top Floating Info Card Overlay
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrackingScreen(
                        onTabChangeRequested: onTabChangeRequested,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFE6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.devices_other_rounded,
                            size: 24,
                            color: Color(0xFF555C65),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              itemName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: ReDoColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$fromCity → $toCity',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: ReDoColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: ReDoColors.secondaryText,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'ETA $eta',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: ReDoColors.secondaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // In Transit Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ReDoColors.greenLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_shipping_rounded,
                              size: 13,
                              color: ReDoColors.successGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ReDoColors.successGreen,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: ReDoColors.successGreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Quick Actions: Track Shipment, Wallet, History, Support
  // --------------------------------------------------------------------------
  Widget _buildQuickActionsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // 1. Track Shipment
        Expanded(
          child: _buildActionTile(
            context: context,
            title: 'Track',
            icon: Icons.inventory_2_outlined,
            backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFFFF8EC),
            borderColor: isDark ? AppColors.darkBorder : const Color(0xFFFFECC4),
            iconColor: AppColors.brandYellow,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrackingScreen(
                    onTabChangeRequested: onTabChangeRequested,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // 2. Wallet
        Expanded(
          child: _buildActionTile(
            context: context,
            title: 'Wallet',
            icon: Icons.account_balance_wallet_outlined,
            backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF0FDF4),
            borderColor: isDark ? AppColors.darkBorder : const Color(0xFFBBF7D0),
            iconColor: const Color(0xFF16A34A),
            onTap: () => onTabChangeRequested?.call(3),
          ),
        ),
        const SizedBox(width: 8),

        // 3. History
        Expanded(
          child: _buildActionTile(
            context: context,
            title: 'History',
            icon: Icons.description_outlined,
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            borderColor: isDark ? AppColors.darkBorder : ReDoColors.cardBorder,
            iconColor: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
            onTap: () => onTabChangeRequested?.call(1),
          ),
        ),
        const SizedBox(width: 8),

        // 4. Support
        Expanded(
          child: _buildActionTile(
            context: context,
            title: 'Support',
            icon: Icons.headset_mic_outlined,
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            borderColor: isDark ? AppColors.darkBorder : ReDoColors.cardBorder,
            iconColor: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon container
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263342) : (backgroundColor == Colors.white ? const Color(0xFFF8FAFC) : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor ?? (isDark ? AppColors.darkInk : ReDoColors.darkNavy),
                ),
              ),
              const SizedBox(width: 8),

              // Title with FittedBox to prevent any awkward text wrap
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Promotional Banner: "Fill empty miles."
  // --------------------------------------------------------------------------
  Widget _buildEmptyMilesBanner(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ReDoColors.cardBorder),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFFF9F0),
              Color(0xFFFFEFCE),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Text & Button
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fill empty miles.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ReDoColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Turn unused truck space\ninto extra earnings.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Learn more button
                  ReDoSecondaryButton(
                    text: 'Learn more',
                    showChevron: true,
                    backgroundColor: Colors.white,
                    textColor: ReDoColors.darkNavy,
                    onPressed: () {
                      _showEmptyMilesDialog(context);
                    },
                  ),
                ],
              ),
            ),

            // Right Truck Graphic
            Expanded(
              flex: 4,
              child: Center(
                child: SizedBox(
                  height: 90,
                  child: Image.asset(
                    'assets/images/redo_truck_3d.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallbackTruck(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackTruck() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: ReDoColors.primaryYellow.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.local_shipping_rounded,
        size: 38,
        color: ReDoColors.primaryYellow,
      ),
    );
  }

  void _showEmptyMilesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ReDoColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'How Empty Miles Matching Works',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ReDoColors.darkNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Over 40% of commercial freight vehicles return with partial loads or empty containers. '
                'ReDo dynamically indexes return routes across India and matches shippers with available backhaul space at up to 35% reduced freight tariffs.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: ReDoColors.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ReDoButton(
                text: 'Book Empty Miles Load',
                onPressed: () {
                  Navigator.pop(ctx);
                  if (onCreateShipment != null) {
                    onCreateShipment!();
                  } else {
                    onTabChangeRequested?.call(2);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Native 3D Cardboard Package Graphic (Custom Painter)
// ============================================================================
class _HeroCardboardBoxGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 100),
      painter: _CardboardBoxPainter(),
    );
  }
}

class _CardboardBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.52;

    // 1. Dark Glossy Pedestal / Stand
    final pedestalPath = Path()
      ..moveTo(cx - 52, cy + 24)
      ..lineTo(cx, cy + 38)
      ..lineTo(cx + 52, cy + 24)
      ..lineTo(cx, cy + 10)
      ..close();

    final pedestalGlow = Paint()
      ..color = const Color(0xFFFFB21A).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(pedestalPath, pedestalGlow);

    final pedestalPaint = Paint()
      ..color = const Color(0xFF1E2833)
      ..style = PaintingStyle.fill;
    canvas.drawPath(pedestalPath, pedestalPaint);

    final pedestalEdge = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(pedestalPath, pedestalEdge);

    // 2. Isometric 3D Box Geometry
    const boxW = 38.0;
    const boxH = 40.0;
    final boxCenter = Offset(cx, cy + 2);

    // Top Face
    final topFace = Path()
      ..moveTo(boxCenter.dx, boxCenter.dy - boxH)
      ..lineTo(boxCenter.dx + boxW, boxCenter.dy - boxH + 18)
      ..lineTo(boxCenter.dx, boxCenter.dy - boxH + 34)
      ..lineTo(boxCenter.dx - boxW, boxCenter.dy - boxH + 18)
      ..close();

    final topPaint = Paint()
      ..color = const Color(0xFFE2B276)
      ..style = PaintingStyle.fill;
    canvas.drawPath(topFace, topPaint);

    // Right Face
    final rightFace = Path()
      ..moveTo(boxCenter.dx, boxCenter.dy - boxH + 34)
      ..lineTo(boxCenter.dx + boxW, boxCenter.dy - boxH + 18)
      ..lineTo(boxCenter.dx + boxW, boxCenter.dy + 18)
      ..lineTo(boxCenter.dx, boxCenter.dy + 34)
      ..close();

    final rightPaint = Paint()
      ..color = const Color(0xFFC78E4E)
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightFace, rightPaint);

    // Left Face
    final leftFace = Path()
      ..moveTo(boxCenter.dx, boxCenter.dy - boxH + 34)
      ..lineTo(boxCenter.dx - boxW, boxCenter.dy - boxH + 18)
      ..lineTo(boxCenter.dx - boxW, boxCenter.dy + 18)
      ..lineTo(boxCenter.dx, boxCenter.dy + 34)
      ..close();

    final leftPaint = Paint()
      ..color = const Color(0xFFD8A05F)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftFace, leftPaint);

    // 3. Packaging Tape across the top & sides
    final tapeTop = Path()
      ..moveTo(boxCenter.dx - 6, boxCenter.dy - boxH + 9)
      ..lineTo(boxCenter.dx + 6, boxCenter.dy - boxH + 9)
      ..lineTo(boxCenter.dx + 6, boxCenter.dy - boxH + 25)
      ..lineTo(boxCenter.dx - 6, boxCenter.dy - boxH + 25)
      ..close();

    final tapePaint = Paint()
      ..color = const Color(0xFFFFB21A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(tapeTop, tapePaint);

    // 4. ReDo Brand Mark on Right Box Face
    final logoText = TextSpan(
      text: 'ReDo',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF111820),
      ),
    );
    final logoPainter = TextPainter(
      text: logoText,
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(boxCenter.dx + 6, boxCenter.dy + 4);
    // Skew for isometric right plane
    final matrix = Matrix4.identity()
      ..setEntry(0, 1, 0.45);
    canvas.transform(matrix.storage);
    logoPainter.paint(canvas, Offset.zero);
    canvas.restore();

    // 5. Handling label / barcode on left face
    final labelPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxCenter.dx - 26, boxCenter.dy + 6, 14, 10),
        const Radius.circular(2),
      ),
      labelPaint,
    );
    final barcodePaint = Paint()
      ..color = const Color(0xFF222B35)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(boxCenter.dx - 24 + i * 3.0, boxCenter.dy + 8),
        Offset(boxCenter.dx - 24 + i * 3.0, boxCenter.dy + 14),
        barcodePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
