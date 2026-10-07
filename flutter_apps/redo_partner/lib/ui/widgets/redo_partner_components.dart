import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';

// ============================================================================
// 1. PARTNER APP BAR
// ============================================================================

/// Reusable Partner App Bar matching ReDo Partner design language
class PartnerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? statusChip;
  final VoidCallback? onBack;
  final bool showBrandHeader;
  final String? driverName;
  final double? driverRating;
  final String? driverAvatar;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final int unreadNotifications;

  const PartnerAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.statusChip,
    this.onBack,
    this.showBrandHeader = false,
    this.driverName,
    this.driverRating,
    this.driverAvatar,
    this.onNotificationTap,
    this.onProfileTap,
    this.unreadNotifications = 1,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    if (showBrandHeader) {
      return _buildBrandHeader(context);
    }

    return Container(
      color: Theme.of(context).cardColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              leading ??
                  (onBack != null
                      ? InkWell(
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ReDoPartnerColors.lightGrey,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
                    if (statusChip != null) ...[
                      const SizedBox(width: 8),
                      statusChip!,
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ReDo Partner Brand with Yellow Truck Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: ReDoPartnerColors.brandYellow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: ReDoPartnerColors.darkNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ReDo',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: ReDoPartnerColors.darkNavy,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Partner',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ReDoPartnerColors.secondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Right items: Notification Bell + Driver Avatar and Name + Rating
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Notification Bell with Red Badge Dot
                    InkWell(
                      onTap: onNotificationTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 22,
                                color: ReDoPartnerColors.darkNavy,
                              ),
                            ),
                            if (unreadNotifications > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: ReDoPartnerColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Driver Avatar and Name + Rating
                    Flexible(
                      child: InkWell(
                        onTap: onProfileTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: ReDoPartnerColors.lightGrey,
                              backgroundImage: driverAvatar != null &&
                                      driverAvatar!.isNotEmpty
                                  ? NetworkImage(driverAvatar!)
                                  : const AssetImage('assets/images/driver_avatar_default.png')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    driverName ?? 'Rahul Kumar',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: ReDoPartnerColors.darkNavy,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        (driverRating ?? 4.9).toStringAsFixed(1),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: ReDoPartnerColors.secondary,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. PARTNER BUTTON (PRIMARY ACTION)
// ============================================================================

/// High-visibility primary button for drivers (Accept, Navigate, Confirm)
class PartnerButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double? width;
  final double borderRadius;
  final bool isFullWidth;

  const PartnerButton({
    super.key,
    required this.title,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 54,
    this.width,
    this.borderRadius = 28,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? ReDoPartnerColors.brandYellow;
    final fg = foregroundColor ?? ReDoPartnerColors.darkNavy;

    Widget child = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.6),
        disabledForegroundColor: fg.withValues(alpha: 0.6),
        elevation: 0,
        minimumSize: Size(width ?? (isFullWidth ? double.infinity : 120), height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: fg,
              ),
            )
          : Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 16, color: fg),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
    );

    return child;
  }
}

// ============================================================================
// 3. PARTNER SECONDARY BUTTON (SKIP, CALL, MESSAGE)
// ============================================================================

/// Light warm button for secondary actions (Skip, Call customer, Message)
class PartnerSecondaryButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double borderRadius;
  final bool isFullWidth;

  const PartnerSecondaryButton({
    super.key,
    required this.title,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 52,
    this.borderRadius = 28,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFFF3EFE6);
    final fg = foregroundColor ?? ReDoPartnerColors.darkNavy;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        minimumSize: Size(isFullWidth ? double.infinity : 100, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: Color(0xFFE8E2D5), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. PARTNER CARD (CONTAINER)
// ============================================================================

class PartnerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const PartnerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? ReDoPartnerColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }
    return card;
  }
}

// ============================================================================
// 5. PARTNER STATUS CHIP
// ============================================================================

enum PartnerChipVariant {
  success,
  warning,
  danger,
  neutral,
  amber,
}

class PartnerStatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final PartnerChipVariant variant;
  final bool isSmall;

  const PartnerStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.variant = PartnerChipVariant.neutral,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case PartnerChipVariant.success:
        bg = ReDoPartnerColors.lightGreen;
        fg = ReDoPartnerColors.success;
        break;
      case PartnerChipVariant.warning:
      case PartnerChipVariant.amber:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case PartnerChipVariant.danger:
        bg = ReDoPartnerColors.lightRed;
        fg = ReDoPartnerColors.danger;
        break;
      case PartnerChipVariant.neutral:
        bg = ReDoPartnerColors.lightGrey;
        fg = ReDoPartnerColors.secondary;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 12 : 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. EARNINGS CARD (TODAY'S EARNINGS HERO WIDGET)
// ============================================================================

class EarningsCard extends StatelessWidget {
  final double todayEarnings;
  final int tripCount;
  final double distanceKm;
  final double rating;
  final VoidCallback? onTap;

  const EarningsCard({
    super.key,
    required this.todayEarnings,
    this.tripCount = 4,
    this.distanceKm = 286,
    this.rating = 4.9,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = '₹${todayEarnings.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ReDoPartnerColors.amberCard,
              ReDoPartnerColors.amberCardEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ReDoPartnerColors.amberCardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Truck Graphic illustration on right
            Positioned(
              right: -10,
              top: 10,
              bottom: 10,
              child: Opacity(
                opacity: 0.95,
                child: Image.asset(
                  'assets/images/partner_hero_banner.png',
                  width: 175,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => const Icon(
                    Icons.local_shipping_rounded,
                    size: 80,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Today's earnings",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ReDoPartnerColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.bar_chart_rounded,
                        size: 16,
                        color: ReDoPartnerColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormat,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: ReDoPartnerColors.darkNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 26,
                        color: ReDoPartnerColors.darkNavy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Metrics Row
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildMetric(
                        icon: Icons.alt_route_rounded,
                        label: '$tripCount Trips',
                      ),
                      _buildMetric(
                        icon: Icons.location_on_outlined,
                        label: '${distanceKm.toInt()} km',
                      ),
                      _buildMetric(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: '$rating Rating',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: iconColor ?? ReDoPartnerColors.darkNavy,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: ReDoPartnerColors.darkNavy,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 7. DRIVER STATUS TOGGLE (ONLINE / OFFLINE)
// ============================================================================

class DriverStatusToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onStatusTap;

  const DriverStatusToggle({
    super.key,
    required this.isOnline,
    required this.onToggle,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ReDoPartnerColors.borderMuted),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Left: Online indicator
          Expanded(
            child: InkWell(
              onTap: onStatusTap,
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? ReDoPartnerColors.success
                          : ReDoPartnerColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: isOnline
                          ? [
                              BoxShadow(
                                color: ReDoPartnerColors.success.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOnline ? 'You are ONLINE' : 'You are OFFLINE',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: ReDoPartnerColors.darkNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isOnline ? 'Available for new trips >' : 'Tap to go online >',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
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
          ),
          const SizedBox(width: 8),
          // Right: Toggle button
          InkWell(
            onTap: () => onToggle(!isOnline),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline ? ReDoPartnerColors.lightGrey : ReDoPartnerColors.brandYellow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    size: 14,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'Go Offline' : 'Go Online',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ReDoPartnerColors.darkNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. TRIP ROUTE COMPONENT (DELHI -> PATNA, DISTANCE, LONG HAUL)
// ============================================================================

class TripRoute extends StatelessWidget {
  final String origin;
  final String destination;
  final double distanceKm;
  final String haulType;
  final VoidCallback? onViewRoute;

  const TripRoute({
    super.key,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    this.haulType = 'Long haul',
    this.onViewRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      origin,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ReDoPartnerColors.darkNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: ReDoPartnerColors.secondary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      destination,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ReDoPartnerColors.darkNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ReDoPartnerColors.lightGrey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${distanceKm.toInt()} km',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ReDoPartnerColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_circle_down_rounded,
                          size: 12,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          haulType,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (onViewRoute != null)
          InkWell(
            onTap: onViewRoute,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ReDoPartnerColors.border),
              ),
              child: Row(
                children: [
                  Text(
                    'View route',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ReDoPartnerColors.darkNavy,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// 9. COUNTDOWN TIMER (45-SECOND DISPATCH OFFER)
// ============================================================================

class CountdownTimer extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;

  const CountdownTimer({
    super.key,
    required this.secondsRemaining,
    this.totalSeconds = 45,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF59E0B),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.access_time_filled_rounded,
              color: Color(0xFFF59E0B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            timeStr,
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: ReDoPartnerColors.darkNavy,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 1.5,
            height: 28,
            color: const Color(0xFFE5D5B5),
          ),
          const SizedBox(width: 14),
          Text(
            'to respond',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ReDoPartnerColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 10. DRIVER INFO CARD & VEHICLE INFO CARD
// ============================================================================

class DriverInfoCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isVerified;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  const DriverInfoCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.isVerified = true,
    this.onCall,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: ReDoPartnerColors.lightGrey,
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : const AssetImage('assets/images/driver_avatar_default.png')
                  as ImageProvider,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ReDoPartnerColors.secondary,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ReDoPartnerColors.darkNavy,
                ),
              ),
              if (isVerified)
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: ReDoPartnerColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified customer',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ReDoPartnerColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (onCall != null)
          _buildCircleAction(
            icon: Icons.phone_rounded,
            label: 'Call',
            onTap: onCall!,
          ),
        if (onMessage != null) ...[
          const SizedBox(width: 12),
          _buildCircleAction(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message',
            onTap: onMessage!,
          ),
        ],
      ],
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF3EFE6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: ReDoPartnerColors.darkNavy),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ReDoPartnerColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleInfoCard extends StatelessWidget {
  final String regNumber;
  final double capacityTons;
  final double? requiredCapacityTons;
  final bool isCompatible;

  const VehicleInfoCard({
    super.key,
    required this.regNumber,
    required this.capacityTons,
    this.requiredCapacityTons,
    this.isCompatible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7DC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: ReDoPartnerColors.darkNavy,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your vehicle',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ReDoPartnerColors.secondary,
                ),
              ),
              Text(
                regNumber,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ReDoPartnerColors.darkNavy,
                ),
              ),
              Text(
                '${capacityTons.toStringAsFixed(0)} Ton capacity',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ReDoPartnerColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 11. MAP PANEL (CLEAN MAP ABSTRACTION WITH REAL GOOGLE MAP OR FALLBACK)
// ============================================================================

class MapPanel extends StatefulWidget {
  final LatLng? originLatLng;
  final LatLng? destLatLng;
  final LatLng? driverLatLng;
  final String? originName;
  final String? destName;
  final double height;
  final bool showControls;
  final VoidCallback? onRecenter;
  final VoidCallback? onToggleLayers;

  const MapPanel({
    super.key,
    this.originLatLng,
    this.destLatLng,
    this.driverLatLng,
    this.originName,
    this.destName,
    this.height = 220,
    this.showControls = true,
    this.onRecenter,
    this.onToggleLayers,
  });

  @override
  State<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<MapPanel> {
  GoogleMapController? _controller;
  static const LatLng _indiaCenter = LatLng(28.6139, 77.2090); // Delhi default

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};

    if (widget.originLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: widget.originLatLng!,
          infoWindow: InfoWindow(title: widget.originName ?? 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }
    if (widget.destLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dest'),
          position: widget.destLatLng!,
          infoWindow: InfoWindow(title: widget.destName ?? 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (widget.driverLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: widget.driverLatLng!,
          infoWindow: const InfoWindow(title: 'Driver Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
      );
    }

    final polyline = (widget.originLatLng != null && widget.destLatLng != null)
        ? {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [widget.originLatLng!, widget.destLatLng!],
              color: const Color(0xFFF59E0B),
              width: 5,
            ),
          }
        : <Polyline>{};

    final center = widget.driverLatLng ?? widget.originLatLng ?? _indiaCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: widget.height,
        color: const Color(0xFFE8EEF5),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 11),
              markers: markers,
              polylines: polyline,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              myLocationButtonEnabled: false,
              onMapCreated: (ctrl) {
                _controller = ctrl;
                _fitBounds();
              },
            ),
            // Floating control buttons on right side
            if (widget.showControls)
              Positioned(
                right: 12,
                top: 12,
                child: Column(
                  children: [
                    _buildMapIconButton(
                      icon: Icons.layers_outlined,
                      onTap: widget.onToggleLayers ?? () {},
                    ),
                    const SizedBox(height: 8),
                    _buildMapIconButton(
                      icon: Icons.navigation_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _buildMapIconButton(
                      icon: Icons.my_location_rounded,
                      onTap: () {
                        widget.onRecenter?.call();
                        _fitBounds();
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: ReDoPartnerColors.darkNavy),
      ),
    );
  }

  void _fitBounds() {
    if (_controller == null) return;
    if (widget.originLatLng != null && widget.destLatLng != null) {
      final southwest = LatLng(
        min(widget.originLatLng!.latitude, widget.destLatLng!.latitude),
        min(widget.originLatLng!.longitude, widget.destLatLng!.longitude),
      );
      final northeast = LatLng(
        max(widget.originLatLng!.latitude, widget.destLatLng!.latitude),
        max(widget.originLatLng!.longitude, widget.destLatLng!.longitude),
      );
      _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: southwest, northeast: northeast),
          50,
        ),
      );
    }
  }
}

// ============================================================================
// 12. ACTION BUTTON (FOR QUICK ACTIONS: TRIPS, EARNINGS, MESSAGES)
// ============================================================================

class ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const ActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ReDoPartnerColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20, color: ReDoPartnerColors.darkNavy),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: ReDoPartnerColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: ReDoPartnerColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 13. PARTNER BOTTOM NAVIGATION (5 TABS: HOME, TRIPS, EARNINGS, MESSAGES, PROFILE)
// ============================================================================

class PartnerBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final int unreadMessagesCount;

  const PartnerBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.unreadMessagesCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(
          top: BorderSide(color: ReDoPartnerColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.local_shipping_rounded, Icons.local_shipping_outlined, 'Trips'),
              _buildNavItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Earnings'),
              _buildNavItem(
                3,
                Icons.chat_bubble_rounded,
                Icons.chat_bubble_outline_rounded,
                'Messages',
                badgeCount: unreadMessagesCount,
              ),
              _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label, {
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onItemSelected(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: isSelected
              ? BoxDecoration(
                  color: const Color(0xFFFFF6DE),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    size: 24,
                    color: isSelected ? const Color(0xFFD97706) : ReDoPartnerColors.secondary,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ReDoPartnerColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFFD97706) : ReDoPartnerColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
