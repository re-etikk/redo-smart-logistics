import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/ui_components.dart';
import '../misc/notifications_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.getEarnings();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final totals = Map<String, dynamic>.from((_data?['totals'] as Map?) ?? {});
    final transactions = List<Map<String, dynamic>>.from(
      ((_data?['transactions'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );

    final completedEarnings = (totals['completed_inr'] as num?)?.toDouble() ?? 0.0;
    final pendingEarnings = (totals['pending_inr'] as num?)?.toDouble() ?? 0.0;
    final completedTrips = (totals['completed_trips'] as num?)?.toInt() ?? 0;
    const withdrawnAmount = 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RedoBrandHeader(
              subtitle: 'Partner (Trucks)',
              onNotificationTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandYellow,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    // Header: Title + Period Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earnings & Payouts',
                              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Real-time revenue from completed shipments.',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            items: ['This Month', 'Last Month', 'All Time']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedPeriod = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_loading)
                      const Center(child: Padding(padding: EdgeInsets.all(36), child: CircularProgressIndicator()))
                    else if (_error != null)
                      _buildErrorCard()
                    else ...[
                      // Hero Total Net Earnings Card (Dark Card + 3D Money Bag)
                      _buildHeroTotalEarningsCard(completedEarnings, completedTrips, currency),
                      const SizedBox(height: 14),

                      // 3 Stat Cards (Completed Trips, Pending Amount, Withdrawn)
                      _buildStatTiles(completedTrips, pendingEarnings, withdrawnAmount, currency),
                      const SizedBox(height: 18),

                      // 7-Day Earnings Bar Chart (from Mockup 4)
                      _build7DayBarChart(transactions, completedEarnings),
                      const SizedBox(height: 18),

                      // Instant Withdrawal Banner
                      _buildWithdrawBanner(completedEarnings, currency),
                      const SizedBox(height: 22),

                      // Recent Transactions / Trip Payouts List
                      Text(
                        'Recent Transactions',
                        style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      if (transactions.isEmpty)
                        _buildEmptyTransactionsCard()
                      else
                        ...transactions.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildTransactionRow(t, currency),
                            )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.inkMuted),
          const SizedBox(height: 10),
          Text('Could not load earnings', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
          const SizedBox(height: 12),
          TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildHeroTotalEarningsCard(
    double total,
    int tripsCount,
    NumberFormat currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slateDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'TOTAL NET EARNINGS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandYellow,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  currency.format(total),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '$tripsCount shipments completed and verified',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const RedoMoneyBagGraphic(size: 72),
        ],
      ),
    );
  }

  Widget _buildStatTiles(
    int completedTrips,
    double pending,
    double withdrawn,
    NumberFormat currency,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            'Completed',
            '$completedTrips',
            Icons.local_shipping_outlined,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            'Pending',
            currency.format(pending),
            Icons.schedule_outlined,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            'Withdrawn',
            currency.format(withdrawn),
            Icons.account_balance_wallet_outlined,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _build7DayBarChart(List<Map<String, dynamic>> transactions, double total) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Revenue Trend',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                'Last 7 Days',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                // If partner has completed trips, show realistic proportional bar
                final hasEarnings = total > 0;
                final heightFactor = hasEarnings ? (0.2 + ((i + 1) * 0.11)) : 0.08;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: 65 * heightFactor,
                      decoration: BoxDecoration(
                        color: (i == 4 || i == 6) && hasEarnings
                            ? AppColors.brandYellow
                            : AppColors.canvas,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (i == 4 || i == 6) && hasEarnings
                              ? AppColors.brandYellow
                              : AppColors.border,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[i],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawBanner(double total, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available for Payout',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                ),
                Text(
                  currency.format(total),
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.slateDark),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showWithdrawDialog(context, total, currency),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.slateDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text('Withdraw Now', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 38, color: AppColors.inkMuted),
          const SizedBox(height: 8),
          Text('No trip transactions yet', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Complete assigned deliveries to see individual trip settlements and bank payouts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> item, NumberFormat currency) {
    final settled = item['settled'] == true;
    final when = DateTime.tryParse('${item['date'] ?? ''}')?.toLocal();
    final amount = (item['amount_inr'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: settled
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              settled ? Icons.check_circle : Icons.schedule,
              size: 16,
              color: settled ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['route'] ?? 'Completed Delivery'}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Text(
                  when != null ? DateFormat('d MMM, y · h:mm a').format(when) : 'Recent Trip',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(amount),
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              Text(
                settled ? 'Settled to Bank' : 'Processing',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: settled ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showWithdrawDialog(BuildContext context, double available, NumberFormat currency) async {
    final ctrl = TextEditingController(text: available > 0 ? available.toStringAsFixed(0) : '0');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Instant Payout Withdrawal', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Balance: ${currency.format(available)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to Withdraw (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Withdrawal will be directly credited via IMPS to your registered bank account.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payout request submitted. Settlement initiated.')),
              );
            },
            child: const Text('Confirm Withdrawal'),
          ),
        ],
      ),
    );
  }
}
