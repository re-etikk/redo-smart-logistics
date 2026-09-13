import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class BrandStoryIntroScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const BrandStoryIntroScreen({super.key, required this.onComplete});

  @override
  State<BrandStoryIntroScreen> createState() => _BrandStoryIntroScreenState();
}

class _BrandStoryIntroScreenState extends State<BrandStoryIntroScreen> with TickerProviderStateMixin {
  int _currentStep = 0; // 0 to 8 (9 steps total)
  final int _totalSteps = 9;
  Timer? _stepTimer;
  late AnimationController _progressController;
  late AnimationController _blueprintAnimController;
  late AnimationController _pulseController;
  late AnimationController _truckMoveController;

  static const Duration _stepDuration = Duration(milliseconds: 3800);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: _stepDuration);
    _blueprintAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _truckMoveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();

    _startStepTimer();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _progressController.dispose();
    _blueprintAnimController.dispose();
    _pulseController.dispose();
    _truckMoveController.dispose();
    super.dispose();
  }

  void _startStepTimer() {
    _progressController.reset();
    _progressController.forward();
    _stepTimer?.cancel();
    _stepTimer = Timer(_stepDuration, () {
      if (_currentStep < _totalSteps - 1) {
        _nextStep();
      }
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        if (_currentStep == 0) {
          _blueprintAnimController.reset();
          _blueprintAnimController.forward();
        }
      });
      _startStepTimer();
    } else {
      _finishIntro();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _startStepTimer();
    }
  }

  Future<void> _finishIntro() async {
    _stepTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_brand_story_v1', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Interactive gesture zones: Tap left for prev, tap right for next
            GestureDetector(
              onTapUp: (details) {
                final width = MediaQuery.of(context).size.width;
                if (details.localPosition.dx < width * 0.3) {
                  _prevStep();
                } else {
                  _nextStep();
                }
              },
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: _buildStepContent(_currentStep),
                ),
              ),
            ),

            // Top Header: 9-Segment Progress Bars & Skip Button
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Progress Bars
                  Row(
                    children: List.generate(_totalSteps, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              height: 3,
                              child: index < _currentStep
                                  ? Container(color: AppColors.brandYellow)
                                  : (index == _currentStep
                                      ? AnimatedBuilder(
                                          animation: _progressController,
                                          builder: (ctx, child) => LinearProgressIndicator(
                                            value: _progressController.value,
                                            backgroundColor: const Color(0xFFE2E8F0),
                                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
                                          ),
                                        )
                                      : Container(color: const Color(0xFFE2E8F0))),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  // Step Label & Skip Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStepTitle(_currentStep),
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkMuted),
                        ),
                      ),
                      TextButton(
                        onPressed: _finishIntro,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkMuted),
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
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return '1. Logo Forms';
      case 1:
        return '2. Logo Reveal';
      case 2:
        return '3. Connecting Bharat';
      case 3:
        return '4. Moving Forward';
      case 4:
        return '5. National Corridors';
      case 5:
        return '6. Key Features';
      case 6:
        return '7. Logistics Made Simple';
      case 7:
        return '8. Getting Ready...';
      case 8:
        return '9. Welcome to REDO';
      default:
        return '';
    }
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildStep1LogoForms();
      case 1:
        return _buildStep2LogoReveal();
      case 2:
        return _buildStep3TaglineMap();
      case 3:
        return _buildStep4TruckMoves();
      case 4:
        return _buildStep5JourneyContinues();
      case 5:
        return _buildStep6KeyFeatures();
      case 6:
        return _buildStep7FinalBrand();
      case 7:
        return _buildStep8Loading();
      case 8:
        return _buildStep9TransitionHome();
      default:
        return const SizedBox.shrink();
    }
  }

  // ========================================================
  // STEP 1: ANIMATED BLUEPRINT LOGO FORMS (Custom Canvas)
  // ========================================================
  Widget _buildStep1LogoForms() {
    return Column(
      key: const ValueKey(1),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Custom Animated Drafting Blueprint Painter
        Center(
          child: AnimatedBuilder(
            animation: _blueprintAnimController,
            builder: (ctx, child) {
              return SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _BlueprintDraftingPainter(progress: _blueprintAnimController.value),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Building a smarter\nlogistics network...',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
            height: 1.4,
          ),
        ),
        const Spacer(),
        _buildBottomHint(),
      ],
    );
  }

  // ========================================================
  // STEP 2: LOGO REVEAL
  // ========================================================
  Widget _buildStep2LogoReveal() {
    return Column(
      key: const ValueKey(2),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandYellow.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'R',
            style: GoogleFonts.poppins(
              fontSize: 54,
              fontWeight: FontWeight.w900,
              color: AppColors.brandYellow,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'redo',
          style: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.slateDark,
            letterSpacing: -1,
          ),
        ),
        Text(
          'Transport & Logistics',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        _buildBottomHint(),
      ],
    );
  }

  // ========================================================
  // STEP 3: TAGLINE & INDIA NETWORK MAP
  // ========================================================
  Widget _buildStep3TaglineMap() {
    return Column(
      key: const ValueKey(3),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // India map graphic with network nodes
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/onboarding/step3_tagline_map.png',
              height: 240,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandYellow.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.hub_outlined, size: 80, color: AppColors.brandYellow),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Connecting Bharat\nThrough Better Logistics',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.slateDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.brandYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Spacer(),
        _buildBottomHint(),
      ],
    );
  }

  // ========================================================
  // STEP 4: TRUCK MOVES (VISUAL ANIMATION)
  // ========================================================
  Widget _buildStep4TruckMoves() {
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'More Loads\nMore Opportunities\nA Stronger Tomorrow',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slateDark,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.brandYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Animated truck highway visual
        Center(
          child: Image.asset(
            'assets/images/onboarding/step4_truck_moves.png',
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/redo_profile_banner.png',
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const Spacer(),
        _buildBottomHint(),
      ],
    );
  }

  // ========================================================
  // STEP 5: JOURNEY CONTINUES (Highway Signboard)
  // ========================================================
  Widget _buildStep5JourneyContinues() {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moving\nIndia Forward',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slateDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.brandYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Center(
          child: Image.asset(
            'assets/images/onboarding/step5_journey_continues.png',
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/redo_profile_banner.png',
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const Spacer(),
        _buildBottomHint(),
      ],
    );
  }

  // ========================================================
  // STEP 6: KEY FEATURES
  // ========================================================
  Widget _buildStep6KeyFeatures() {
    return Padding(
      key: const ValueKey(6),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          _buildFeatureRow(
            icon: Icons.local_shipping_outlined,
            title: 'Smart Matching',
            desc: 'AI-driven corridor allocation for instant dispatch',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            icon: Icons.location_on_outlined,
            title: 'Real-time Tracking',
            desc: 'Live GPS telemetry and digital milestone pings',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            icon: Icons.shield_outlined,
            title: 'Reliable Partners',
            desc: '100% verified KYC fleet owners and corporate shippers',
          ),
          const SizedBox(height: 40),
          Text(
            'Built for\na Faster, Stronger India',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.slateDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.brandYellow,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          _buildBottomHint(),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.slateDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slateDark),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // STEP 7: FINAL BRAND SCREEN ("Logistics Made Simple")
  // ========================================================
  Widget _buildStep7FinalBrand() {
    return Column(
      key: const ValueKey(7),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Redo Logo
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandYellow.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'R',
            style: GoogleFonts.poppins(
              fontSize: 54,
              fontWeight: FontWeight.w900,
              color: AppColors.brandYellow,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'redo',
          style: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.slateDark,
            letterSpacing: -1,
          ),
        ),
        Text(
          'Transport & Logistics',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 36),
        // Handwritten "Logistics Made Simple"
        Text(
          'Logistics\nMade Simple',
          textAlign: TextAlign.center,
          style: GoogleFonts.caveat(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.slateDark,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.brandYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Spacer(),
        _buildBottomHint(),
      ],
    );
  }

  // ========================================================
  // STEP 8: LOADING (Radar Ripple Circles)
  // ========================================================
  Widget _buildStep8Loading() {
    return Column(
      key: const ValueKey(8),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Concentric Ripple Rings around 'R' Logo
        Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (ctx, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180 + (_pulseController.value * 24),
                    height: 180 + (_pulseController.value * 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandYellow.withValues(alpha: 0.12 * (1.0 - _pulseController.value)),
                    ),
                  ),
                  Container(
                    width: 140 + (_pulseController.value * 16),
                    height: 140 + (_pulseController.value * 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandYellow.withValues(alpha: 0.22 * (1.0 - _pulseController.value * 0.5)),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'R',
                      style: GoogleFonts.poppins(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandYellow,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 36),
        Text(
          'Getting things ready...',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.slateDark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              backgroundColor: Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              minHeight: 4,
            ),
          ),
        ),
        const Spacer(),
        _buildBottomHint(),
      ],
    );
  }

  // ========================================================
  // STEP 9: TRANSITION TO HOME
  // ========================================================
  Widget _buildStep9TransitionHome() {
    return Padding(
      key: const ValueKey(9),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            'Welcome to',
            style: GoogleFonts.caveat(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.slateDark,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandYellow.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'R',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.brandYellow,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'redo',
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.slateDark,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Transport & Logistics',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _finishIntro,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.slateDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                elevation: 4,
                shadowColor: AppColors.brandYellow.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Let's Move",
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBottomHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        'Tap right to continue',
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkFaint, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ========================================================
// CUSTOM BLUEPRINT DRAFTING PAINTER FOR STEP 1
// ========================================================
class _BlueprintDraftingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  _BlueprintDraftingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final gridPaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    final guidePaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final logoPaint = Paint()
      ..color = AppColors.brandYellow
      ..strokeWidth = 12.0 * progress
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final darkPaint = Paint()
      ..color = AppColors.slateDark
      ..strokeWidth = 10.0 * progress
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Grid Background
    const gridStep = 24.0;
    for (double x = 0; x <= w; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y <= h; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Blueprint Circle Arc Guides
    canvas.drawCircle(center, 70, guidePaint);
    canvas.drawCircle(center, 95, guidePaint);

    // Diagonal 45-deg guide lines
    canvas.drawLine(Offset(center.dx - 80, center.dy + 80), Offset(center.dx + 80, center.dy - 80), guidePaint);

    // 3. Draw the animated R symbol
    // Top arch of R
    final rect = Rect.fromCircle(center: Offset(center.dx, center.dy - 20), radius: 35);
    final sweepAngle = math.pi * 1.5 * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, logoPaint);

    // Vertical spine of R
    final spineProgress = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(center.dx - 35, center.dy - 55),
      Offset(center.dx - 35, center.dy - 55 + (85 * spineProgress)),
      logoPaint,
    );

    // Diagonal leg of R (Dark slate)
    if (progress > 0.4) {
      final legProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(center.dx - 5, center.dy + 5),
        Offset(center.dx - 5 + (35 * legProgress), center.dy + 5 + (45 * legProgress)),
        darkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintDraftingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
