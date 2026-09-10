import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class RedoLogo extends StatelessWidget {
  const RedoLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const RedoBrandHeader(subtitle: 'Transport & Logistics', showProfile: false);
  }
}

class RedoBrandHeader extends StatelessWidget {
  final String subtitle;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool showProfile;

  const RedoBrandHeader({
    super.key,
    this.subtitle = 'Transport & Logistics',
    this.onNotificationTap,
    this.onProfileTap,
    this.showProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Exact REDO Logo Asset
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/customer_logo.png',
                height: 38,
                width: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'R',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandYellow,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'redo',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkInk : AppColors.slateDark,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Notification Bell with Red Dot
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onNotificationTap,
              child: Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCanvas : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkInk : AppColors.slateDark,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.darkCard : Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showProfile) ...[
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onProfileTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCanvas : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 22,
                    color: isDark ? AppColors.darkInk : AppColors.slateDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 3D Styled Redo Truck Illustration for Customer Banners
class RedoTruckHeroGraphic extends StatelessWidget {
  final double height;
  const RedoTruckHeroGraphic({super.key, this.height = 95});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/redo_truck_3d.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        height: height,
        width: height * 1.55,
        child: CustomPaint(
          painter: _CustomerTruckPainter(),
        ),
      ),
    );
  }
}

class _CustomerTruckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Road shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.92), width: w * 0.9, height: h * 0.14),
      shadowPaint,
    );

    // Trailer (White Container with Redo Logo)
    final trailerPaint = Paint()..color = const Color(0xFFFAFBFD);
    final trailerBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final trailerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.32, h * 0.15, w * 0.65, h * 0.62),
      const Radius.circular(5),
    );
    canvas.drawRRect(trailerRect, trailerPaint);
    canvas.drawRRect(trailerRect, trailerBorder);

    // Redo text on trailer
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'redo',
        style: GoogleFonts.inter(
          fontSize: h * 0.18,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(w * 0.55, h * 0.44));

    // Small black R icon mark before text
    final markPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.45, h * 0.16, h * 0.16),
        const Radius.circular(3),
      ),
      markPaint,
    );

    // Cabin (Bright Redo Yellow)
    final cabPaint = Paint()..color = const Color(0xFFFFB800);
    final cabPath = Path()
      ..moveTo(w * 0.35, h * 0.28)
      ..lineTo(w * 0.18, h * 0.28)
      ..quadraticBezierTo(w * 0.10, h * 0.29, w * 0.08, h * 0.42)
      ..lineTo(w * 0.04, h * 0.62)
      ..quadraticBezierTo(w * 0.03, h * 0.77, w * 0.08, h * 0.77)
      ..lineTo(w * 0.35, h * 0.77)
      ..close();
    canvas.drawPath(cabPath, cabPaint);

    // Windshield (dark slate tint)
    final glassPaint = Paint()..color = const Color(0xFF1E293B);
    final glassPath = Path()
      ..moveTo(w * 0.17, h * 0.32)
      ..lineTo(w * 0.28, h * 0.32)
      ..lineTo(w * 0.28, h * 0.50)
      ..lineTo(w * 0.10, h * 0.50)
      ..quadraticBezierTo(w * 0.12, h * 0.38, w * 0.17, h * 0.32)
      ..close();
    canvas.drawPath(glassPath, glassPaint);

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF1E293B);
    final rimPaint = Paint()..color = const Color(0xFF94A3B8);

    void drawWheel(double cx, double cy, double r) {
      canvas.drawCircle(Offset(cx, cy), r, wheelPaint);
      canvas.drawCircle(Offset(cx, cy), r * 0.45, rimPaint);
    }

    drawWheel(w * 0.18, h * 0.78, h * 0.14);
    drawWheel(w * 0.72, h * 0.78, h * 0.14);
    drawWheel(w * 0.88, h * 0.78, h * 0.14);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Standard Redo Button
class RedoButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double height;

  const RedoButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return SizedBox(
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor: AppColors.slateDark,
          ),
          child: isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
                    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: AppColors.brandYellow,
          foregroundColor: AppColors.slateDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slateDark),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AppColors.slateDark),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.slateDark,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.replaceAll('_', ' ').toUpperCase();

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case 'in_transit':
      case 'in transit':
      case 'picked_up':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case 'delivered':
      case 'completed':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
