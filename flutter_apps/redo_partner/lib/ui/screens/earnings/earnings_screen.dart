import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/redo_partner_components.dart';
import '../misc/notifications_screen.dart';

/// Screen 09 — Earnings
/// Faithfully recreates the earnings screen matching Reference 09.
/// Shows monthly earnings hero banner with graphic, Today/Week/Month filter,
/// 4 metric cards (Trips, Distance, Average/Trip, Rating),
/// 7-day earnings trend bar chart, and recent completed trip earnings list.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _selectedFilter = 'month'; // 'today', 'week', 'month'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getEarnings();
      if (mounted) setState(() => _data = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final tripsVM = context.watch<PartnerTripsViewModel>();
    final totals = Map<String, dynamic>.from((_data?['totals'] as Map?) ?? {});
    final completedEarnings = (totals['completed_inr'] as num?)?.toDouble() ?? 28450.0;
    final completedTrips = (totals['completed_trips'] as num?)?.toInt() ?? 18;
    final avgPerTrip = (totals['avg_per_trip_inr'] as num?)?.toDouble() ?? 1580.0;

    return Scaffold(
      backgroundColor: ReDoPartnerColors.warmBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: ReDoPartnerColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand Header
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ReDoPartnerColors.brandYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: ReDoPartnerColors.darkNavy,
                        size: 20,
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
                            fontSize: 18,
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
                  ],
                ),
                // Notification Bell
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 24,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
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
              ],
            ),
          ),
        ),
      ),
      body: _loading && _data == null
          ? const Center(
              child: CircularProgressIndicator(color: ReDoPartnerColors.brandYellow),
            )
          : RefreshIndicator(
              color: ReDoPartnerColors.brandYellow,
              onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Page Title & Period Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earnings',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: ReDoPartnerColors.darkNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Track your income and trips',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: ReDoPartnerColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ReDoPartnerColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: ReDoPartnerColors.darkNavy),
                      const SizedBox(width: 6),
                      Text(
                        'This month',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: ReDoPartnerColors.secondary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Hero Total Earnings Banner (Matching Reference 09)
            _buildHeroEarningsBanner(currency, completedEarnings),
            const SizedBox(height: 14),

            // 2. Filter Pills: Today | This week | This month
            _buildFilterPills(),
            const SizedBox(height: 16),

            // 3. Four Metric Cards (2x2 Grid)
            _buildMetricGrid(completedTrips, currency, avgPerTrip),
            const SizedBox(height: 16),

            // 4. Earnings Trend (Last 7 days) Bar Chart
            _buildEarningsTrendChart(),
            const SizedBox(height: 20),

            // 5. Recent Earnings List
            _buildRecentEarningsSection(currency, tripsVM),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroEarningsBanner(NumberFormat currency, double totalEarnings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF3D6),
            Color(0xFFFFE8B0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Stack(
        children: [
          // Background graphic decoration: Golden bars & Truck illustration
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: 140,
              height: 100,
              child: CustomPaint(
                painter: _EarningsIllustrationPainter(),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Total earnings',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ReDoPartnerColors.darkNavy.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: ReDoPartnerColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                currency.format(totalEarnings),
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: ReDoPartnerColors.darkNavy,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'This month',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: ReDoPartnerColors.secondary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward_rounded,
                        size: 13, color: ReDoPartnerColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ReDoPartnerColors.success,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'from last month',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReDoPartnerColors.border),
      ),
      child: Row(
        children: [
          _buildFilterPillItem('Today', 'today'),
          _buildFilterPillItem('This week', 'week'),
          _buildFilterPillItem('This month', 'month'),
        ],
      ),
    );
  }

  Widget _buildFilterPillItem(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? ReDoPartnerColors.brandYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? ReDoPartnerColors.darkNavy : ReDoPartnerColors.secondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricGrid(
    int tripsCount,
    NumberFormat currency,
    double avgPerTrip,
  ) {
    return Row(
      children: [
        // Trips
        Expanded(
          child: _buildMetricTile(
            icon: Icons.local_shipping_outlined,
            title: 'Trips',
            value: '$tripsCount',
            comparison: '↑ 20% vs last month',
            isPositive: true,
          ),
        ),
        const SizedBox(width: 8),
        // Distance
        Expanded(
          child: _buildMetricTile(
            icon: Icons.alt_route_rounded,
            title: 'Distance',
            value: '2,460 km',
            comparison: '↑ 15% vs last month',
            isPositive: true,
          ),
        ),
        const SizedBox(width: 8),
        // Average / trip
        Expanded(
          child: _buildMetricTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Average / trip',
            value: currency.format(avgPerTrip),
            comparison: '↑ 8% vs last month',
            isPositive: true,
          ),
        ),
        const SizedBox(width: 8),
        // Rating
        Expanded(
          child: _buildMetricTile(
            icon: Icons.star_outline_rounded,
            title: 'Rating',
            value: '4.9 ★',
            comparison: '32 reviews',
            isPositive: null,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required String comparison,
    required bool? isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReDoPartnerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ReDoPartnerColors.darkNavy),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: ReDoPartnerColors.secondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: ReDoPartnerColors.darkNavy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            comparison,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isPositive == true
                  ? ReDoPartnerColors.success
                  : ReDoPartnerColors.secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTrendChart() {
    final bars = [
      {'day': 'Mon', 'amount': '₹2.8K', 'height': 0.45},
      {'day': 'Tue', 'amount': '₹3.4K', 'height': 0.55},
      {'day': 'Wed', 'amount': '₹4.1K', 'height': 0.68},
      {'day': 'Thu', 'amount': '₹2.9K', 'height': 0.48},
      {'day': 'Fri', 'amount': '₹5.2K', 'height': 0.90},
      {'day': 'Sat', 'amount': '₹3.1K', 'height': 0.50},
      {'day': 'Sun', 'amount': '₹3.8K', 'height': 0.62},
    ];

    return PartnerCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Earnings trend (Last 7 days)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total ₹18,320',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: ReDoPartnerColors.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bar Chart with guidelines
          SizedBox(
            height: 140,
            child: Stack(
              children: [
                // Guidelines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGuideline('₹6K'),
                    _buildGuideline('₹4K'),
                    _buildGuideline('₹2K'),
                    _buildGuideline('0'),
                  ],
                ),
                // Vertical Bars
                Padding(
                  padding: const EdgeInsets.only(left: 36, right: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: bars.map((b) {
                      final h = (b['height'] as double) * 90;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 20,
                              height: h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFB21A),
                                    Color(0xFFFFD56B),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b['day'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ReDoPartnerColors.secondary,
                              ),
                            ),
                            Text(
                              b['amount'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: ReDoPartnerColors.darkNavy,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideline(String label) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: ReDoPartnerColors.secondary.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: ReDoPartnerColors.border.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentEarningsSection(
    NumberFormat currency,
    PartnerTripsViewModel tripsVM,
  ) {
    final recentItems = [
      {
        'route': 'Delhi → Patna',
        'date': '12 Feb 2026',
        'dist': '1,050 km',
        'cargo': 'Electronics • 12 kg • 2 packages',
        'amount': 4850,
      },
      {
        'route': 'Lucknow → Delhi',
        'date': '10 Feb 2026',
        'dist': '520 km',
        'cargo': 'Automotive Parts • 18 kg • 4 packages',
        'amount': 3920,
      },
      {
        'route': 'Kanpur → Delhi',
        'date': '08 Feb 2026',
        'dist': '480 km',
        'cargo': 'Textiles • 25 kg • 5 packages',
        'amount': 2800,
      },
      {
        'route': 'Patna → Delhi',
        'date': '05 Feb 2026',
        'dist': '1,050 km',
        'cargo': 'Machinery Parts • 30 kg • 3 packages',
        'amount': 4250,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent earnings',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: ReDoPartnerColors.darkNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View all',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentItems.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ReDoPartnerColors.border),
            ),
            child: Row(
              children: [
                // Thumbnail map placeholder
                Container(
                  width: 58,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 22,
                      color: ReDoPartnerColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item['route'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: ReDoPartnerColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Completed',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: ReDoPartnerColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item['date']} • ${item['dist']}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: ReDoPartnerColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 11, color: ReDoPartnerColors.secondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item['cargo'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: ReDoPartnerColors.secondary,
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
                const SizedBox(width: 8),
                Text(
                  currency.format(item['amount'] as int),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: ReDoPartnerColors.secondary),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _EarningsIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Ascending bars
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 90, size.height - 40, 16, 40),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 65, size.height - 60, 16, 60),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 40, size.height - 85, 16, 85),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
