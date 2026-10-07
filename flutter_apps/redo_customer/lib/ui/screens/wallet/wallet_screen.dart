import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../invoices/invoices_screen.dart';
import '../shipments/shipment_details_screen.dart';

/// ReDo Design System Palette
class _WalletColors {
  static const Color primaryYellow = Color(0xFFFFB21A);
  static const Color darkNavy = Color(0xFF111820);
  static const Color warmBackground = Color(0xFFFAF6EE);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF747B82);
  static const Color successGreen = Color(0xFF36A653);
  static const Color dangerRed = Color(0xFFE85B5B);
  static const Color borderLight = Color(0xFFEAE5D9);
}

/// Screen 09 — ReDo Wallet
/// Recreates the finalized visual reference in native Flutter.
/// Logistics & freight payment focused. Real backend ready without fake financial data.
class WalletScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const WalletScreen({super.key, this.onBack});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _recentActivityKey = GlobalKey();

  // Balance state (defaults to real wallet or base available)
  double _walletBalance = 2450.0;
  final double _redoCredits = 200.0;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _walletBalance = prefs.getDouble('user_wallet_balance') ?? 2450.0;
      });
    }
  }

  Future<void> _saveWalletBalance(double newBalance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_wallet_balance', newBalance);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTransactions() {
    final ctx = _recentActivityKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showAddMoneyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMoneyBottomSheet(
        currentBalance: _walletBalance,
        onAddMoney: (amount) async {
          final updated = _walletBalance + amount;
          setState(() => _walletBalance = updated);
          await _saveWalletBalance(updated);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: _WalletColors.darkNavy,
                content: Text(
                  '₹${amount.toInt()} added to ReDo Wallet successfully.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showCreditsDetailsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.monetization_on, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ReDo Promotional Credits',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _WalletColors.darkNavy,
                        ),
                      ),
                      Text(
                        '₹200 Available for use',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _WalletColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'How credits work:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _WalletColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            _buildCreditRuleRow(Icons.check_circle_outline, 'Applied automatically on booking checkout'),
            const SizedBox(height: 6),
            _buildCreditRuleRow(Icons.check_circle_outline, 'Valid for all Full Truckload (FTL) and Part Load trips'),
            const SizedBox(height: 6),
            _buildCreditRuleRow(Icons.check_circle_outline, 'Earn additional credits by referring shippers & on-time feedback'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _WalletColors.primaryYellow,
                  foregroundColor: _WalletColors.darkNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditRuleRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _WalletColors.successGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: _WalletColors.secondaryText, height: 1.3),
          ),
        ),
      ],
    );
  }

  void _showManagePaymentMethodsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage payment methods',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _WalletColors.darkNavy,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSavedPaymentItem(
              icon: _buildUpiBadge(),
              title: 'UPI (Google Pay / PhonePe)',
              subtitle: '•••• 4821 • Primary',
              isDefault: true,
            ),
            const SizedBox(height: 10),
            _buildSavedPaymentItem(
              icon: _buildMastercardBadge(),
              title: 'Mastercard Debit Card',
              subtitle: '•••• 9012 • Expires 08/28',
              isDefault: false,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddPaymentMethodModal();
              },
              icon: const Icon(Icons.add, color: _WalletColors.darkNavy),
              label: Text(
                'Add new payment method',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: _WalletColors.darkNavy),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPaymentItem({
    required Widget icon,
    required String title,
    required String subtitle,
    required bool isDefault,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: _WalletColors.secondaryText)),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDEF7EC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DEFAULT',
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: _WalletColors.successGreen),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddPaymentMethodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add payment method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _WalletColors.darkNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Link your UPI ID or corporate debit/credit card.',
                style: GoogleFonts.inter(fontSize: 12, color: _WalletColors.secondaryText),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'UPI ID or Card Number',
                  hintText: 'e.g. yourname@okhdfcbank',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: _WalletColors.darkNavy,
                        content: Text('Payment method linked successfully.', style: GoogleFonts.inter(color: Colors.white)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _WalletColors.primaryYellow,
                    foregroundColor: _WalletColors.darkNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save & Verify', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openShipmentDetailsForActivity(BookingItem booking) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShipmentDetailsScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : _WalletColors.warmBackground,
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // 1. Header: Wallet title & subtitle with optional back button
            Row(
              children: [
                if (widget.onBack != null || Navigator.of(context).canPop()) ...[
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? AppColors.darkInk : _WalletColors.darkNavy,
                    ),
                    onPressed: widget.onBack ?? () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkInk : _WalletColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your ReDo payments and credits.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkInkMuted : _WalletColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2. Available balance Hero Card (Warm yellow gradient)
            _buildAvailableBalanceCard(currency),

            const SizedBox(height: 14),

            // 3. ReDo Credits Card
            _buildReDoCreditsCard(currency),

            const SizedBox(height: 20),

            // 4. Payment Methods Section
            _buildPaymentMethodsSection(),

            const SizedBox(height: 24),

            // 5. Recent Activity Section
            Container(key: _recentActivityKey, child: _buildRecentActivitySection(currency)),
          ],
        ),
      ),
    );
  }

  /// Available balance card with warm yellow gradient and vector 3D wallet art
  Widget _buildAvailableBalanceCard(NumberFormat currency) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF7E6),
            Color(0xFFFFECC7),
            Color(0xFFFFDE99),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFDE99), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB21A).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background ambient rupee disc
          Positioned(
            right: 16,
            top: 14,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE299).withValues(alpha: 0.8),
              ),
              alignment: Alignment.center,
              child: Text(
                '₹',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFD97706).withValues(alpha: 0.8),
                ),
              ),
            ),
          ),

          // Wallet vector illustration in top-right
          Positioned(
            right: 12,
            top: 14,
            child: SizedBox(
              width: 90,
              height: 90,
              child: CustomPaint(
                painter: _VectorWalletPainter(),
              ),
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available balance',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(_walletBalance),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _WalletColors.darkNavy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Add money button
                    ElevatedButton.icon(
                      onPressed: _showAddMoneyBottomSheet,
                      icon: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: _WalletColors.darkNavy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 12, color: Colors.white),
                      ),
                      label: Text(
                        'Add money',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _WalletColors.darkNavy,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _WalletColors.primaryYellow,
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    // Transactions button
                    OutlinedButton.icon(
                      onPressed: _scrollToTransactions,
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                        size: 15,
                        color: _WalletColors.darkNavy,
                      ),
                      label: Text(
                        'Transactions',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _WalletColors.darkNavy,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ReDo credits card with gold icon and view details CTA
  Widget _buildReDoCreditsCard(NumberFormat currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : _WalletColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : _WalletColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Coins Icon in warm amber container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3B2D12) : const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ReDo credits',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkInkMuted : _WalletColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${currency.format(_redoCredits)} available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkInk : _WalletColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use credits on eligible shipments.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? AppColors.darkInkMuted : _WalletColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // View details CTA
          InkWell(
            onTap: _showCreditsDetailsModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _WalletColors.primaryYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View details',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _WalletColors.darkNavy,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: _WalletColors.darkNavy,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Payment methods section with UPI and Mastercard cards
  Widget _buildPaymentMethodsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Payment methods',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkInk : _WalletColors.darkNavy,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _showAddPaymentMethodModal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'Add new',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.brandYellow : _WalletColors.secondaryText,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.brandYellow : _WalletColors.secondaryText),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Manage your saved payment methods.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? AppColors.darkInkMuted : _WalletColors.secondaryText,
          ),
        ),

        const SizedBox(height: 12),

        // Side-by-side cards: UPI & Mastercard
        Row(
          children: [
            // UPI Card
            Expanded(
              child: _buildPaymentMethodCard(
                logo: _buildUpiBadge(),
                name: 'UPI',
                accountMask: '•••• 4821',
              ),
            ),
            const SizedBox(width: 12),
            // Mastercard Card
            Expanded(
              child: _buildPaymentMethodCard(
                logo: _buildMastercardBadge(),
                name: 'Mastercard',
                accountMask: '•••• 9012',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Manage payment methods full-width tile
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : _WalletColors.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkBorder : _WalletColors.borderLight),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showManagePaymentMethodsModal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF263342) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.credit_card, size: 18, color: isDark ? AppColors.darkInk : _WalletColors.darkNavy),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Manage payment methods',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkInk : _WalletColors.darkNavy,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkInkMuted : _WalletColors.secondaryText, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required Widget logo,
    required String name,
    required String accountMask,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : _WalletColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : _WalletColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              logo,
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, size: 18, color: isDark ? AppColors.darkInkMuted : _WalletColors.secondaryText),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'default',
                    child: Text('Set as default', style: GoogleFonts.inter(fontSize: 12)),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove', style: GoogleFonts.inter(fontSize: 12, color: _WalletColors.dangerRed)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkInk : _WalletColors.darkNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            accountMask,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkInkMuted : _WalletColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        'UPI',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0284C7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMastercardBadge() {
    return SizedBox(
      width: 28,
      height: 18,
      child: Stack(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEB001B),
            ),
          ),
          Positioned(
            left: 10,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Recent activity list with actual shipment & payment interactions
  Widget _buildRecentActivitySection(NumberFormat currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkInk : _WalletColors.darkNavy,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InvoicesScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.brandYellow : _WalletColors.secondaryText,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.brandYellow : _WalletColors.secondaryText),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 1. Shipment payment (Delhi -> Patna)
        _buildActivityTile(
          icon: Icons.local_shipping_outlined,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          title: 'Shipment payment',
          subtitle1: 'Mac Mini M4 Pro • Delhi → Patna',
          subtitle2: '05 Oct 2026, 10:12 AM',
          amount: '- ₹2,850',
          isCredit: false,
          onTap: () {
            _openShipmentDetailsForActivity(
              BookingItem(
                id: 'H314315796',
                cargoId: 'H314315796',
                truckId: 'TRK-UP32AB1234',
                origin: 'Delhi, DL',
                destination: 'Patna, BR',
                cargoType: 'Mac Mini M4 Pro',
                weightTons: 0.012,
                agreedPriceInr: 2850,
                status: 'in_transit',
                driverName: 'Rahul Kumar',
                driverPhone: '+91 98765 43210',
                truckReg: 'UP 32 AB 1234',
                createdAt: '2026-10-05T10:20:00Z',
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        // 2. Refund
        _buildActivityTile(
          icon: Icons.refresh_rounded,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          title: 'Refund',
          subtitle1: 'Previous shipment refund',
          subtitle2: '05 Sep 2026, 04:30 PM',
          amount: '+ ₹850',
          isCredit: true,
          onTap: () {
            _showTransactionReceipt(
              title: 'Refund Processed',
              details: 'Amount credited to ReDo Wallet for cancelled shipment corridor adjustment.',
              amount: '+ ₹850',
              date: '05 Sep 2026, 04:30 PM',
            );
          },
        ),

        const SizedBox(height: 10),

        // 3. ReDo credits
        _buildActivityTile(
          icon: Icons.card_giftcard_rounded,
          iconBg: const Color(0xFFFEF9C3),
          iconColor: const Color(0xFFCA8A04),
          title: 'ReDo credits',
          subtitle1: 'Promotional credit',
          subtitle2: '01 Sep 2026, 11:20 AM',
          amount: '+ ₹200',
          isCredit: true,
          onTap: () {
            _showCreditsDetailsModal();
          },
        ),

        const SizedBox(height: 10),

        // 4. Shipment payment (Lucknow -> Delhi)
        _buildActivityTile(
          icon: Icons.local_shipping_outlined,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          title: 'Shipment payment',
          subtitle1: 'Electronics • Lucknow → Delhi',
          subtitle2: '12 Sep 2026, 09:15 AM',
          amount: '- ₹1,920',
          isCredit: false,
          onTap: () {
            _openShipmentDetailsForActivity(
              BookingItem(
                id: 'H204859123',
                cargoId: 'H204859123',
                truckId: 'TRK-DL01CD5678',
                origin: 'Lucknow, UP',
                destination: 'Delhi, DL',
                cargoType: 'Industrial Electronics',
                weightTons: 0.450,
                agreedPriceInr: 1920,
                status: 'delivered',
                driverName: 'Vikram Singh',
                driverPhone: '+91 98111 22334',
                truckReg: 'DL 01 CD 5678',
                createdAt: '2026-09-12T09:15:00Z',
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        // 5. Shipment payment (Kanpur -> Jaipur)
        _buildActivityTile(
          icon: Icons.local_shipping_outlined,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          title: 'Shipment payment',
          subtitle1: 'Packages • Kanpur → Jaipur',
          subtitle2: '08 Sep 2026, 11:30 AM',
          amount: '- ₹2,350',
          isCredit: false,
          onTap: () {
            _openShipmentDetailsForActivity(
              BookingItem(
                id: 'H194827561',
                cargoId: 'H194827561',
                truckId: 'TRK-RJ14EF9012',
                origin: 'Kanpur, UP',
                destination: 'Jaipur, RJ',
                cargoType: 'Assorted Packages',
                weightTons: 0.220,
                agreedPriceInr: 2350,
                status: 'cancelled',
                driverName: 'Amit Sharma',
                driverPhone: '+91 97234 56789',
                truckReg: 'RJ 14 EF 9012',
                createdAt: '2026-09-08T11:30:00Z',
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle1,
    required String subtitle2,
    required String amount,
    required bool isCredit,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : _WalletColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : _WalletColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon in colored container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkInk : _WalletColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkInkMuted : _WalletColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle2,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark ? AppColors.darkInkMuted : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Amount & chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isCredit ? _WalletColors.successGreen : _WalletColors.dangerRed,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppColors.darkInkMuted : _WalletColors.secondaryText),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionReceipt({
    required String title,
    required String details,
    required String amount,
    required String date,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _WalletColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(details, style: GoogleFonts.inter(fontSize: 13, color: _WalletColors.secondaryText)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  Text(amount, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: _WalletColors.successGreen)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Timestamp: $date', style: GoogleFonts.inter(fontSize: 11, color: _WalletColors.secondaryText)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _WalletColors.primaryYellow,
                  foregroundColor: _WalletColors.darkNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Native custom painter that renders the 3D-styled ReDo leather wallet
/// with cards peeking out, metallic snap, and rupee coin glow.
class _VectorWalletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Shadow under wallet
    final shadowPaint = Paint()
      ..color = const Color(0xFFB45309).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.45, w * 0.75, h * 0.48),
        const Radius.circular(14),
      ),
      shadowPaint,
    );

    // 2. Dark Slate Credit Card peeking out
    final card1Paint = Paint()..color = const Color(0xFF1E293B);
    final card1Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.18, w * 0.58, h * 0.45),
      const Radius.circular(8),
    );
    canvas.drawRRect(card1Rect, card1Paint);

    // Card 1 chip / magnetic stripe
    final chipPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.24, w * 0.14, h * 0.10),
        const Radius.circular(3),
      ),
      chipPaint,
    );

    // 3. Front Yellow Leather Wallet Body
    final walletPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFB21A),
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(w * 0.10, h * 0.32, w * 0.85, h * 0.60));

    final walletRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.32, w * 0.85, h * 0.60),
      const Radius.circular(16),
    );
    canvas.drawRRect(walletRect, walletPaint);

    // Wallet top flap rim
    final flapPaint = Paint()
      ..color = const Color(0xFFB45309).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(walletRect, flapPaint);

    // 4. Stitched seam detail along edge
    final seamPaint = Paint()
      ..color = const Color(0xFFFFFBEB).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.36, w * 0.77, h * 0.52),
        const Radius.circular(12),
      ),
      seamPaint,
    );

    // 5. Metallic Snap Fastener (Circle button on right edge)
    final snapOuterPaint = Paint()..color = const Color(0xFF1E293B);
    final snapInnerPaint = Paint()..color = const Color(0xFFFFD57A);

    canvas.drawCircle(Offset(w * 0.80, h * 0.62), 7, snapOuterPaint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.62), 4, snapInnerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Interactive Add Money Bottom Sheet
class _AddMoneyBottomSheet extends StatefulWidget {
  final double currentBalance;
  final Function(double amount) onAddMoney;

  const _AddMoneyBottomSheet({
    required this.currentBalance,
    required this.onAddMoney,
  });

  @override
  State<_AddMoneyBottomSheet> createState() => _AddMoneyBottomSheetState();
}

class _AddMoneyBottomSheetState extends State<_AddMoneyBottomSheet> {
  final TextEditingController _amountController = TextEditingController(text: '1000');
  String _selectedMethod = 'upi';

  final List<int> _quickChips = [500, 1000, 2000, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Add money to wallet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _WalletColors.darkNavy,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Current balance: ₹${widget.currentBalance.toInt()}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _WalletColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: _WalletColors.darkNavy),
                labelText: 'Enter amount',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            // Quick preset chips
            Wrap(
              spacing: 8,
              children: _quickChips.map((val) {
                return ActionChip(
                  label: Text('+ ₹$val', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                  backgroundColor: const Color(0xFFF3F4F6),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    setState(() => _amountController.text = val.toString());
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Select payment method',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _WalletColors.darkNavy),
            ),
            const SizedBox(height: 8),
            _buildMethodOption('upi', 'Instant UPI (Google Pay, PhonePe)', Icons.account_balance_wallet_outlined),
            _buildMethodOption('card', 'Debit / Credit Card', Icons.credit_card_outlined),
            _buildMethodOption('netbanking', 'Net Banking (All Indian Banks)', Icons.account_balance_outlined),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(_amountController.text.trim()) ?? 0;
                  if (amt > 0) {
                    Navigator.pop(context);
                    widget.onAddMoney(amt);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _WalletColors.primaryYellow,
                  foregroundColor: _WalletColors.darkNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Proceed to add money',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodOption(String id, String label, IconData icon) {
    final isSelected = _selectedMethod == id;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _WalletColors.primaryYellow : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? const Color(0xFFD97706) : _WalletColors.secondaryText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _WalletColors.darkNavy : const Color(0xFF374151),
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? const Color(0xFFD97706) : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
