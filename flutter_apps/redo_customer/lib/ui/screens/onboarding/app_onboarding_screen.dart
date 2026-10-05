import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingSlide {
  final String titleDark;
  final String titleYellow;
  final String subtitle;
  final String imagePath;

  const OnboardingSlide({
    required this.titleDark,
    required this.titleYellow,
    required this.subtitle,
    required this.imagePath,
  });
}

class AppOnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const AppOnboardingScreen({super.key, required this.onFinish});

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      titleDark: 'Move More',
      titleYellow: 'Together',
      subtitle: 'Smarter trucks. Higher opportunities.',
      imagePath: 'assets/images/onboarding_1_faded.png',
    ),
    OnboardingSlide(
      titleDark: 'Ship',
      titleYellow: 'Anything',
      subtitle: 'From small parcels to heavy cargo.',
      imagePath: 'assets/images/onboarding_2_faded.png',
    ),
    OnboardingSlide(
      titleDark: 'Track',
      titleYellow: 'in Real Time',
      subtitle: 'Full visibility, from pickup to delivery.',
      imagePath: 'assets/images/onboarding_3_faded.png',
    ),
  ];

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinish();
    }
  }

  void _skip() {
    HapticFeedback.mediumImpact();
    widget.onFinish();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Exactly matches the warm yellowish-white background from the design
    const canvasBg = Color(0xFFFDF8EE);

    return Scaffold(
      backgroundColor: canvasBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar: Minimalist ReDo Logo & Skip Button
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 12, 26, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Re',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.8,
                              ),
                            ),
                            TextSpan(
                              text: 'Do',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF5A623),
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5A623),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _skip,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE8DA),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. PageView with Smooth Transitions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  HapticFeedback.selectionClick();
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clean Minimal Headline
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.titleDark,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                height: 1.05,
                                letterSpacing: -1.0,
                              ),
                            ),
                            Text(
                              slide.titleYellow,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF5A623),
                                height: 1.05,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Seamless Edge-to-Edge Artwork (Faded boundaries, no hard box)
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            slide.imagePath,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. Apple-Grade Bottom Bar: Worm Dots & Action Capsule
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 6, 28, 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Worm Dots
                  Row(
                    children: List.generate(_slides.length, (index) {
                      final isCurrent = _currentIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 6),
                        width: isCurrent ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFF5A623) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFF5A623).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                      );
                    }),
                  ),

                  // Action Capsule Button
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentIndex == _slides.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 18, right: 10),
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 44),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5A623),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF0F172A),
                              size: 22,
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
    );
  }
}
