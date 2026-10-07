import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

// ============================================================================
// 1. ReDoLogo: Native Isometric 3D Cube & Bold Brand Typography
// ============================================================================
class ReDoLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;

  const ReDoLogo({
    super.key,
    this.size = 36,
    this.showText = true,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _IsometricCubePainter(),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Re',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: ReDoColors.darkNavy,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Do',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: ReDoColors.primaryYellow,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _IsometricCubePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;
    final r = w * 0.46;

    // Isometric 3D Hexagonal Cube Vertices
    // Top face
    final topPath = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.866, cy - r * 0.5)
      ..lineTo(cx, cy)
      ..lineTo(cx - r * 0.866, cy - r * 0.5)
      ..close();

    // Right face
    final rightPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r * 0.866, cy - r * 0.5)
      ..lineTo(cx + r * 0.866, cy + r * 0.5)
      ..lineTo(cx, cy + r)
      ..close();

    // Left face
    final leftPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - r * 0.866, cy - r * 0.5)
      ..lineTo(cx - r * 0.866, cy + r * 0.5)
      ..lineTo(cx, cy + r)
      ..close();

    // Paint Top: Bright Yellow
    final topPaint = Paint()
      ..color = const Color(0xFFFFC033)
      ..style = PaintingStyle.fill;
    canvas.drawPath(topPath, topPaint);

    // Paint Left Face: Dark Navy
    final leftPaint = Paint()
      ..color = const Color(0xFF131B24)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftPath, leftPaint);

    // Paint Right Face: Golden Amber
    final rightPaint = Paint()
      ..color = const Color(0xFFE59C0A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightPath, rightPaint);

    // Inner subtle isometric accent lines
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy), strokePaint);
    canvas.drawLine(Offset(cx, cy), Offset(cx + r * 0.866, cy - r * 0.5), strokePaint);
    canvas.drawLine(Offset(cx, cy), Offset(cx - r * 0.866, cy - r * 0.5), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 2. ReDoCard: Base Card with 24px Radius & Soft Elevation
// ============================================================================
class ReDoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool showShadow;

  const ReDoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 24,
    this.onTap,
    this.gradient,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? ReDoColors.darkCard : ReDoColors.white;
    final defaultBorder = isDark ? ReDoColors.darkBorder : ReDoColors.cardBorder;

    final border = Border.all(
      color: borderColor ?? defaultBorder,
      width: 1,
    );

    final shadows = showShadow && !isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ]
        : null;

    final decoration = BoxDecoration(
      color: gradient == null ? (backgroundColor ?? defaultBg) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: shadows,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

// ============================================================================
// 3. ReDoButton: Primary Golden Amber Action Button
// ============================================================================
class ReDoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showArrow;
  final IconData? leadingIcon;
  final double height;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;

  const ReDoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.showArrow = true,
    this.leadingIcon,
    this.height = 56,
    this.width,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? ReDoColors.primaryYellow;
    final fg = textColor ?? ReDoColors.darkNavy;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20, color: fg),
                  ],
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// 4. ReDoSecondaryButton: Outline / Ghost Pill Button
// ============================================================================
class ReDoSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool showChevron;
  final Color? backgroundColor;
  final Color? textColor;

  const ReDoSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.showChevron = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? ReDoColors.darkCard : Colors.white;
    final defaultBorder = isDark ? ReDoColors.darkBorder : ReDoColors.cardBorder;
    final defaultText = isDark ? ReDoColors.darkInk : ReDoColors.darkNavy;

    return Material(
      color: backgroundColor ?? defaultBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: defaultBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: textColor ?? defaultText),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor ?? defaultText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 3),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 15,
                  color: textColor ?? ReDoColors.darkNavy,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 5. ReDoIconButton: Circular Icon Buttons
// ============================================================================
class ReDoIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool hasBorder;

  const ReDoIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.backgroundColor,
    this.iconColor,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? ReDoColors.primaryYellow,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: hasBorder
                ? Border.all(color: ReDoColors.cardBorder, width: 1)
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.48,
              color: iconColor ?? ReDoColors.darkNavy,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 6. ReDoStatusChip: Visual Status Badge
// ============================================================================
enum ReDoStatusType { success, warning, danger, neutral }

class ReDoStatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ReDoStatusType type;
  final bool showChevron;
  final VoidCallback? onTap;

  const ReDoStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.type = ReDoStatusType.success,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case ReDoStatusType.success:
        bg = ReDoColors.greenLight;
        fg = ReDoColors.successGreen;
        break;
      case ReDoStatusType.warning:
        bg = ReDoColors.yellowLight;
        fg = const Color(0xFFC77800);
        break;
      case ReDoStatusType.danger:
        bg = ReDoColors.redLight;
        fg = ReDoColors.danger;
        break;
      case ReDoStatusType.neutral:
        bg = ReDoColors.pillBg;
        fg = ReDoColors.secondaryText;
        break;
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 16, color: fg),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ============================================================================
// 7. ReDoSectionHeader: Section Title + Optional "View all >" Action
// ============================================================================
class ReDoSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const ReDoSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? ReDoColors.darkInk : ReDoColors.darkNavy;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionText != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionText!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ReDoColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: ReDoColors.secondaryText,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// 8. ReDoProgressIndicator: Segmented Step Header ("1 of 4")
// ============================================================================
class ReDoProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ReDoProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$currentStep of $totalSteps',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ReDoColors.darkNavy,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            return Container(
              margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted
                    ? ReDoColors.primaryYellow
                    : ReDoColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ============================================================================
// 9. ReDoAppBar: Top Bar with Back Navigation & Step Counter
// ============================================================================
class ReDoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final int? currentStep;
  final int totalSteps;
  final List<Widget>? actions;

  const ReDoAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.currentStep,
    this.totalSteps = 4,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? ReDoColors.darkInk : ReDoColors.darkNavy;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: fgColor),
        onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: fgColor,
        ),
      ),
      actions: [
        if (currentStep != null)
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: ReDoProgressIndicator(
                currentStep: currentStep!,
                totalSteps: totalSteps,
              ),
            ),
          ),
        if (actions != null) ...actions!,
      ],
    );
  }
}

// ============================================================================
// 10. ReDoInput: Modern Logistics Text Field
// ============================================================================
class ReDoInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;

  const ReDoInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? ReDoColors.darkCard : const Color(0xFFF7F4EC);
    final borderCol = isDark ? ReDoColors.darkBorder : ReDoColors.border;
    final textCol = isDark ? ReDoColors.darkInk : ReDoColors.darkNavy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ReDoColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, size: 20, color: ReDoColors.secondaryText),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: readOnly
                      ? Text(
                          controller?.text.isNotEmpty == true
                              ? controller!.text
                              : (hint ?? ''),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: controller?.text.isNotEmpty == true
                                ? textCol
                                : ReDoColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : TextField(
                          controller: controller,
                          onChanged: onChanged,
                          keyboardType: keyboardType,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textCol,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintText: hint,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: ReDoColors.secondaryText,
                            ),
                          ),
                        ),
                ),
                ?suffix,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 11. ReDoCargoCard: Cargo Category Selection Tile
// ============================================================================
class ReDoCargoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ReDoCargoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9EE) : ReDoColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? ReDoColors.primaryYellow
                : ReDoColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFECC4)
                        : const Color(0xFFF6F2E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: ReDoColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ReDoColors.darkNavy,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: ReDoColors.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 13,
                    color: ReDoColors.darkNavy,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 12. ReDoRouteTimeline: Pickup to Destination Route Card
// ============================================================================
class ReDoRouteTimeline extends StatelessWidget {
  final String pickupCity;
  final String pickupAddress;
  final String deliveryCity;
  final String deliveryAddress;
  final VoidCallback? onSwap;
  final VoidCallback? onPickupTap;
  final VoidCallback? onDeliveryTap;

  const ReDoRouteTimeline({
    super.key,
    required this.pickupCity,
    required this.pickupAddress,
    required this.deliveryCity,
    required this.deliveryAddress,
    this.onSwap,
    this.onPickupTap,
    this.onDeliveryTap,
  });

  @override
  Widget build(BuildContext context) {
    return ReDoCard(
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Indicator column (circle -> dashed line -> pin)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ReDoColors.primaryYellow.withValues(alpha: 0.25),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: ReDoColors.primaryYellow,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 38,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Flex(
                          direction: Axis.vertical,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (_) {
                            return const SizedBox(
                              width: 2,
                              height: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFB21A),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: ReDoColors.primaryYellow,
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Addresses
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onPickupTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4EC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 18, color: ReDoColors.secondaryText),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pickupCity.isNotEmpty ? pickupCity : 'Select pickup',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ReDoColors.darkNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: ReDoColors.secondaryText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onDeliveryTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4EC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 18, color: ReDoColors.primaryYellow),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                deliveryCity.isNotEmpty ? deliveryCity : 'Select destination',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ReDoColors.darkNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: ReDoColors.secondaryText),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          if (onSwap != null)
            Positioned(
              right: 0,
              child: GestureDetector(
                onTap: onSwap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAE0),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: ReDoColors.darkNavy,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 13. ReDoShipmentCard: Floating / Embed Summary (Item, Route, ETA, Status)
// ============================================================================
class ReDoShipmentCard extends StatelessWidget {
  final String itemName;
  final String fromCity;
  final String toCity;
  final String eta;
  final String status;
  final VoidCallback? onTap;

  const ReDoShipmentCard({
    super.key,
    required this.itemName,
    required this.fromCity,
    required this.toCity,
    required this.eta,
    this.status = 'In Transit',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ReDoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 20,
      onTap: onTap,
      child: Row(
        children: [
          // Cargo hardware/box icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFE6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.computer_rounded,
                size: 26,
                color: Color(0xFF555C65),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  itemName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$fromCity → $toCity',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ReDoColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: ReDoColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ETA $eta',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ReDoColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status Chip
          ReDoStatusChip(
            label: status,
            icon: Icons.local_shipping_rounded,
            type: ReDoStatusType.success,
            showChevron: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 14. ReDoPriceBreakdown: Transparent Logistics Pricing Table
// ============================================================================
class ReDoPriceBreakdown extends StatelessWidget {
  final double baseFare;
  final double distanceFare;
  final double cargoHandling;
  final double serviceFee;
  final double total;
  final String distanceText;

  const ReDoPriceBreakdown({
    super.key,
    required this.baseFare,
    required this.distanceFare,
    required this.cargoHandling,
    required this.serviceFee,
    required this.total,
    this.distanceText = '1,050 km',
  });

  @override
  Widget build(BuildContext context) {
    return ReDoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ReDoColors.darkNavy,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(Icons.local_shipping_outlined, 'Base fare', '₹${baseFare.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _buildRow(Icons.route_outlined, 'Distance ($distanceText)', '₹${distanceFare.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _buildRow(Icons.inventory_2_outlined, 'Cargo handling', '₹${cargoHandling.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _buildRow(Icons.receipt_long_outlined, 'Service fee', '₹${serviceFee.toStringAsFixed(0)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: ReDoColors.border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECC4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      size: 18,
                      color: Color(0xFFC77800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: ReDoColors.darkNavy,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: ReDoColors.darkNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: ReDoColors.secondaryText),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ReDoColors.darkNavy,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ReDoColors.darkNavy,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 15. ReDoDriverCard: Compatible Driver Profile
// ============================================================================
class ReDoDriverCard extends StatelessWidget {
  final String driverName;
  final String truckModel;
  final double rating;
  final String plateNumber;
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  const ReDoDriverCard({
    super.key,
    required this.driverName,
    required this.truckModel,
    this.rating = 4.9,
    required this.plateNumber,
    this.onCall,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return ReDoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFFFECC4),
            child: const Icon(Icons.person, color: ReDoColors.darkNavy, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$truckModel • $plateNumber',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ReDoColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB21A)),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onChat != null)
            ReDoIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onChat,
              size: 40,
              backgroundColor: const Color(0xFFF0EAE0),
              iconColor: ReDoColors.darkNavy,
            ),
          const SizedBox(width: 8),
          if (onCall != null)
            ReDoIconButton(
              icon: Icons.phone_rounded,
              onTap: onCall,
              size: 40,
              backgroundColor: ReDoColors.primaryYellow,
              iconColor: ReDoColors.darkNavy,
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 16. ReDoCargoCard: Cargo Specification Summary Box (Weight, Dimensions)
// ============================================================================
class ReDoCargoSummaryCard extends StatelessWidget {
  final String category;
  final String weight;
  final String packages;

  const ReDoCargoSummaryCard({
    super.key,
    required this.category,
    required this.weight,
    required this.packages,
  });

  @override
  Widget build(BuildContext context) {
    return ReDoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      backgroundColor: const Color(0xFFFFFBF4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(Icons.inventory_2_outlined, 'Cargo', category),
          Container(width: 1, height: 32, color: ReDoColors.border),
          _buildItem(Icons.scale_outlined, 'Weight', weight),
          Container(width: 1, height: 32, color: ReDoColors.border),
          _buildItem(Icons.grid_view_rounded, 'Packages', packages),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFFFECC4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFC77800)),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: ReDoColors.secondaryText,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: ReDoColors.darkNavy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 17. ReDoBottomNavigation: 5-Tab Bar with Visually Dominant Center Action
// ============================================================================
class ReDoBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreatePressed;

  const ReDoBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildTab(
                  index: 0,
                  icon: Icons.home_rounded,
                  inactiveIcon: Icons.home_outlined,
                  label: 'Home',
                ),
              ),
              Expanded(
                child: _buildTab(
                  index: 1,
                  icon: Icons.inventory_2_rounded,
                  inactiveIcon: Icons.inventory_2_outlined,
                  label: 'Shipments',
                ),
              ),
              // Dominant Center Create Action
              Expanded(
                child: GestureDetector(
                  onTap: onCreatePressed,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ReDoColors.primaryYellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ReDoColors.primaryYellow.withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 28,
                            color: ReDoColors.darkNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Create',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: currentIndex == 2
                              ? ReDoColors.primaryYellow
                              : ReDoColors.darkNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _buildTab(
                  index: 3,
                  icon: Icons.account_balance_wallet_rounded,
                  inactiveIcon: Icons.account_balance_wallet_outlined,
                  label: 'Wallet',
                ),
              ),
              Expanded(
                child: _buildTab(
                  index: 4,
                  icon: Icons.person_rounded,
                  inactiveIcon: Icons.person_outline_rounded,
                  label: 'Profile',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFECC4).withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? icon : inactiveIcon,
              size: 24,
              color: isSelected ? ReDoColors.primaryYellow : ReDoColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? ReDoColors.darkNavy : ReDoColors.secondaryText,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 14,
              height: 2.5,
              decoration: BoxDecoration(
                color: ReDoColors.primaryYellow,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 5.5),
        ],
      ),
    );
  }
}

// ============================================================================
// 18. Native Stylized Route Map Component (Replaceable / GoogleMap compatible)
// ============================================================================
class ReDoMapOverlay extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final double height;
  final Widget? floatingCard;

  const ReDoMapOverlay({
    super.key,
    this.fromCity = 'Delhi',
    this.toCity = 'Patna',
    this.height = 240,
    this.floatingCard,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE4DFD3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ReDoColors.cardBorder),
        ),
        child: Stack(
          children: [
            // Custom Painter rendering isometric stylized highway and landscape
            Positioned.fill(
              child: CustomPaint(
                painter: _StylizedMapRoutePainter(),
              ),
            ),
            // Floating Shipment Card Overlay at the top
            if (floatingCard != null)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: floatingCard!,
              ),
          ],
        ),
      ),
    );
  }
}

class _StylizedMapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background terrain
    final terrainPaint = Paint()
      ..color = const Color(0xFFEFE8DA)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), terrainPaint);

    // Subtle river / waterway
    final riverPath = Path()
      ..moveTo(w * 0.45, 0)
      ..cubicTo(w * 0.5, h * 0.35, w * 0.55, h * 0.65, w * 0.6, h)
      ..lineTo(w * 0.8, h)
      ..cubicTo(w * 0.75, h * 0.65, w * 0.7, h * 0.35, w * 0.65, 0)
      ..close();

    final riverPaint = Paint()
      ..color = const Color(0xFFC7DEE5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(riverPath, riverPaint);

    // Urban blocks / grid patterns
    final blockPaint = Paint()
      ..color = const Color(0xFFE5DDD0)
      ..style = PaintingStyle.fill;

    // Draw some subtle city building outlines
    for (int i = 0; i < 6; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(16 + i * 28.0, h * 0.65 + (i % 2) * 12.0, 22, 18),
          const Radius.circular(4),
        ),
        blockPaint,
      );
    }

    // Glowing Golden Highway Corridor
    final highwayPath = Path()
      ..moveTo(w * 0.12, h * 0.52)
      ..cubicTo(w * 0.28, h * 0.62, w * 0.38, h * 0.68, w * 0.52, h * 0.65)
      ..cubicTo(w * 0.68, h * 0.62, w * 0.8, h * 0.76, w * 0.88, h * 0.84);

    // Glow under highway
    final glowPaint = Paint()
      ..color = ReDoColors.primaryYellow.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(highwayPath, glowPaint);

    // Highway road surface
    final roadPaint = Paint()
      ..color = const Color(0xFF323B44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highwayPath, roadPaint);

    // Yellow highway center line
    final centerLinePaint = Paint()
      ..color = ReDoColors.primaryYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highwayPath, centerLinePaint);

    // Moving truck on the highway (middle)
    final truckOffset = Offset(w * 0.52, h * 0.65);
    final truckBgPaint = Paint()
      ..color = ReDoColors.primaryYellow
      ..style = PaintingStyle.fill;
    final truckShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawOval(
      Rect.fromCenter(center: truckOffset.translate(0, 4), width: 36, height: 16),
      truckShadowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: truckOffset, width: 34, height: 16),
        const Radius.circular(5),
      ),
      truckBgPaint,
    );

    // Delhi Pin (Start)
    final startPin = Offset(w * 0.12, h * 0.52);
    _drawLocationPin(canvas, startPin, 'Delhi', isStart: true);

    // Patna Pin (End)
    final endPin = Offset(w * 0.88, h * 0.84);
    _drawLocationPin(canvas, endPin, 'Patna', isStart: false);
  }

  void _drawLocationPin(Canvas canvas, Offset pos, String city, {required bool isStart}) {
    // Pulse outer ring
    final pulsePaint = Paint()
      ..color = ReDoColors.primaryYellow.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 16, pulsePaint);

    // Inner pin circle
    final pinPaint = Paint()
      ..color = isStart ? const Color(0xFF111820) : ReDoColors.primaryYellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 9, pinPaint);

    final innerDot = Paint()
      ..color = isStart ? ReDoColors.primaryYellow : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 4, innerDot);

    // City Pill Label
    final textSpan = TextSpan(
      text: city,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: pos.translate(0, -22),
        width: textPainter.width + 14,
        height: 18,
      ),
      const Radius.circular(9),
    );

    final labelPaint = Paint()..color = ReDoColors.darkNavy;
    canvas.drawRRect(labelRect, labelPaint);

    textPainter.paint(
      canvas,
      pos.translate(-textPainter.width / 2, -22 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
