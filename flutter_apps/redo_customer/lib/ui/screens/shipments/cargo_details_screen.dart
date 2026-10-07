import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/booking_viewmodel.dart';
import '../../widgets/redo_design_system.dart';
import 'price_estimate_screen.dart';

/// ReDo Customer App — SCREEN 03: CARGO DETAILS
/// Recreated natively in Flutter matching design reference media_1791216690354.png
class CargoDetailsScreen extends StatefulWidget {
  const CargoDetailsScreen({super.key});

  @override
  State<CargoDetailsScreen> createState() => _CargoDetailsScreenState();
}

class _CargoDetailsScreenState extends State<CargoDetailsScreen> {
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _valueController;

  int _packageCount = 2;
  bool _isFragile = false;
  bool _isTemperatureSensitive = false;
  String _weightUnit = 'kg';

  List<double> get _quickWeights {
    switch (_weightUnit) {
      case 'ton':
        return [0.5, 1.0, 2.0, 5.0, 10.0];
      case 'lbs':
        return [25.0, 50.0, 100.0, 250.0, 500.0];
      case 'kg':
      default:
        return [50.0, 100.0, 250.0, 500.0, 1000.0];
    }
  }

  final _currencyFormat = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    final vm = context.read<BookingViewModel>();
    final initialWeight = vm.weightKg.round();
    _weightController = TextEditingController(text: initialWeight > 0 ? '$initialWeight' : '100');
    _lengthController = TextEditingController(text: '${vm.lengthCm.round()}');
    _widthController = TextEditingController(text: '${vm.widthCm.round()}');
    _heightController = TextEditingController(text: '${vm.heightCm.round()}');
    _packageCount = vm.packageCount;
    _isFragile = vm.isFragile;
    _isTemperatureSensitive = vm.isTemperatureSensitive;
    _valueController = TextEditingController(
      text: _currencyFormat.format(vm.declaredValueInr.round()),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _onQuickWeightSelected(double weight) {
    setState(() {
      _weightController.text = weight == weight.roundToDouble()
          ? weight.toInt().toString()
          : weight.toString();
    });
  }

  void _incrementPackages() {
    setState(() {
      _packageCount++;
    });
  }

  void _decrementPackages() {
    if (_packageCount > 1) {
      setState(() {
        _packageCount--;
      });
    }
  }

  void _handleContinue() {
    final rawWeight = double.tryParse(_weightController.text.trim()) ?? 0;
    final length = double.tryParse(_lengthController.text.trim()) ?? 0;
    final width = double.tryParse(_widthController.text.trim()) ?? 0;
    final height = double.tryParse(_heightController.text.trim()) ?? 0;
    final cleanValue = _valueController.text.replaceAll(',', '').trim();
    final cargoValue = double.tryParse(cleanValue) ?? 0;

    if (rawWeight <= 0) {
      _showSnackbar('Please enter a valid weight.');
      return;
    }

    double weightKg = rawWeight;
    if (_weightUnit == 'ton') {
      weightKg = rawWeight * 1000.0;
    } else if (_weightUnit == 'lbs') {
      weightKg = rawWeight * 0.453592;
    }

    if (length <= 0 || width <= 0 || height <= 0) {
      _showSnackbar('Please enter positive package dimensions.');
      return;
    }
    if (_packageCount < 1) {
      _showSnackbar('Please select at least 1 package.');
      return;
    }
    if (cargoValue <= 0) {
      _showSnackbar('Please enter an estimated cargo value.');
      return;
    }

    final vm = context.read<BookingViewModel>();
    vm.setWeightKg(weightKg);
    vm.setDimensions(length: length, width: width, height: height);
    vm.setPackageCount(_packageCount);
    vm.setFragile(_isFragile);
    vm.setTemperatureSensitive(_isTemperatureSensitive);
    vm.setDeclaredValueInr(cargoValue);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PriceEstimateScreen(),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCommonWeightsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Common Weight Guide',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWeightGuideItem('Documents & Envelopes', '0.5 - 1 kg', 1),
            _buildWeightGuideItem('Laptops & Electronics', '2 - 5 kg', 5),
            _buildWeightGuideItem('Small Box / Home Goods', '8 - 12 kg', 12),
            _buildWeightGuideItem('Heavy Machinery Parts', '20 - 50 kg', 20),
            _buildWeightGuideItem('Bulk Commercial Freight', '100+ kg', 50),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightGuideItem(String title, String range, double sampleWeight) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECC4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.scale_rounded, size: 20, color: ReDoColors.darkNavy),
      ),
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(range, style: GoogleFonts.inter(fontSize: 12, color: ReDoColors.secondaryText)),
      trailing: TextButton(
        onPressed: () {
          _onQuickWeightSelected(sampleWeight);
          Navigator.pop(context);
        },
        child: const Text('Use', style: TextStyle(color: Color(0xFFD98800), fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showHowToMeasureSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'How to Measure Your Package',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Measure the longest side as Length (L), the second side as Width (W), and the vertical height as Height (H). If your package is irregular, measure the outer bounding rectangle.',
              style: GoogleFonts.inter(fontSize: 14, color: ReDoColors.secondaryText, height: 1.5),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 140,
                height: 100,
                child: CustomPaint(
                  painter: _IsometricBoxPainter(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final category = vm.cargoType.isNotEmpty ? vm.cargoType : 'Electronics';
    final originCity = vm.origin.isNotEmpty ? vm.origin.split(',').first.trim() : 'Delhi';
    final destCity = vm.destination.isNotEmpty ? vm.destination.split(',').first.trim() : 'Patna';

    final currentWeight = double.tryParse(_weightController.text) ?? 12;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkCanvas : ReDoColors.warmBg;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: const ReDoAppBar(
        title: 'Cargo details',
        currentStep: 2,
        totalSteps: 4,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Category & Route Header Banner
                    _buildTopHeaderCard(category, originCity, destCity),

                    const SizedBox(height: 20),

                    // Section: How heavy is it?
                    _buildSectionTitle(
                      title: 'How heavy is it?',
                      subtitle: 'Enter the total weight of your shipment.',
                      actionText: 'Common weights',
                      actionIcon: Icons.scale_outlined,
                      onActionTap: _showCommonWeightsSheet,
                    ),
                    const SizedBox(height: 12),
                    _buildWeightCard(currentWeight),

                    const SizedBox(height: 24),

                    // Section: Package dimensions
                    _buildSectionTitle(
                      title: 'Package dimensions',
                      subtitle: 'Enter the size of one package.',
                      actionText: 'How to measure?',
                      actionIcon: Icons.info_outline_rounded,
                      onActionTap: _showHowToMeasureSheet,
                    ),
                    const SizedBox(height: 12),
                    _buildDimensionsRow(),

                    const SizedBox(height: 24),

                    // Section: Number of packages
                    _buildSectionTitle(
                      title: 'Number of packages',
                      subtitle: 'Total number of identical packages.',
                    ),
                    const SizedBox(height: 12),
                    _buildPackageCounterCard(),

                    const SizedBox(height: 24),

                    // Section: Special handling
                    _buildSectionTitle(
                      title: 'Special handling',
                      subtitle: 'Let us know if your cargo needs extra care.',
                    ),
                    const SizedBox(height: 12),
                    _buildSpecialHandlingCards(),

                    const SizedBox(height: 24),

                    // Section: Estimated cargo value
                    _buildSectionTitle(
                      title: 'Estimated cargo value',
                      subtitle: 'Helps us provide better protection and pricing.',
                    ),
                    const SizedBox(height: 12),
                    _buildCargoValueInput(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Fixed Section: Summary Card + Continue CTA
            _buildBottomBar(category, currentWeight),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Top Header Card: Category + Route + Vector Illustration
  // --------------------------------------------------------------------------
  Widget _buildTopHeaderCard(String category, String originCity, String destCity) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF8),
            Color(0xFFFFECC4),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFDF9E),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE59C0A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Background Decorative Wave Glow
            Positioned(
              right: -30,
              top: -20,
              bottom: -20,
              width: 180,
              child: CustomPaint(
                painter: _HeaderGlowPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Left: Category Icon Container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECC4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD685)),
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(category),
                        size: 28,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Center: Category and Route
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ReDoColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                originCity,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ReDoColors.secondaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: ReDoColors.secondaryText,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                destCity,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ReDoColors.secondaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right: Illustrated Package Stacks (Native Vector Painter)
                  SizedBox(
                    width: 80,
                    height: 54,
                    child: CustomPaint(
                      painter: _CargoPackagesVectorPainter(),
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.laptop_mac_rounded;
      case 'packages':
        return Icons.inventory_2_outlined;
      case 'documents':
        return Icons.description_outlined;
      case 'fragile':
        return Icons.wine_bar_outlined;
      default:
        return Icons.local_shipping_outlined;
    }
  }

  // --------------------------------------------------------------------------
  // Section Title with Optional Subtitle & Action Pill
  // --------------------------------------------------------------------------
  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    String? actionText,
    IconData? actionIcon,
    VoidCallback? onActionTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ReDoColors.darkNavy,
                ),
              ),
            ),
            if (actionText != null)
              GestureDetector(
                onTap: onActionTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECE0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (actionIcon != null) ...[
                        Icon(actionIcon, size: 13, color: ReDoColors.darkNavy),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        actionText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ReDoColors.darkNavy,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 14, color: ReDoColors.darkNavy),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: ReDoColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Weight Input Card with Dropdown and Quick Chips
  // --------------------------------------------------------------------------
  Widget _buildWeightCard(double currentWeight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Weight Row: Scale Icon + Big Number Input + Unit Dropdown
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F2E9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.scale_rounded,
                    size: 24,
                    color: ReDoColors.darkNavy,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Big Editable Number Field
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ),
              // Unit Dropdown Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F2E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _weightUnit,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: ReDoColors.darkNavy),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ReDoColors.darkNavy,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'ton', child: Text('ton')),
                      DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                    ],
                    onChanged: (val) {
                      if (val != null && val != _weightUnit) {
                        setState(() {
                          _weightUnit = val;
                          if (val == 'ton') {
                            _weightController.text = '2';
                          } else if (val == 'lbs') {
                            _weightController.text = '250';
                          } else {
                            _weightController.text = '100';
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dynamic Quick Selection Chips Row based on unit (kg, ton, lbs)
          Row(
            children: _quickWeights.map((w) {
              final isSelected = (currentWeight - w).abs() < 0.05;
              final chipText = w == w.roundToDouble()
                  ? '${w.toInt()} $_weightUnit'
                  : '$w $_weightUnit';

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _onQuickWeightSelected(w),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFECC4) : const Color(0xFFF6F2E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? ReDoColors.primaryYellow : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          chipText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF8B5500) : ReDoColors.darkNavy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Package Dimensions Row: Length, Width, Height
  // --------------------------------------------------------------------------
  Widget _buildDimensionsRow() {
    return Row(
      children: [
        Expanded(child: _buildDimCard('Length', _lengthController)),
        const SizedBox(width: 8),
        Expanded(child: _buildDimCard('Width', _widthController)),
        const SizedBox(width: 8),
        Expanded(child: _buildDimCard('Height', _heightController)),
      ],
    );
  }

  Widget _buildDimCard(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 14, color: ReDoColors.secondaryText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ReDoColors.secondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                'cm',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ReDoColors.secondaryText,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: ReDoColors.secondaryText),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Number of Packages Stepper Card
  // --------------------------------------------------------------------------
  Widget _buildPackageCounterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minus Button
          GestureDetector(
            onTap: _decrementPackages,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F2E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5DECF)),
              ),
              child: const Center(
                child: Icon(
                  Icons.remove_rounded,
                  size: 22,
                  color: ReDoColors.darkNavy,
                ),
              ),
            ),
          ),

          // Bold Package Count
          Text(
            '$_packageCount',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: ReDoColors.darkNavy,
            ),
          ),

          // Plus Button (Dominant Primary Yellow)
          GestureDetector(
            onTap: _incrementPackages,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ReDoColors.primaryYellow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ReDoColors.primaryYellow.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: ReDoColors.darkNavy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Special Handling Switches
  // --------------------------------------------------------------------------
  Widget _buildSpecialHandlingCards() {
    return Column(
      children: [
        _buildHandlingItem(
          icon: Icons.wine_bar_outlined,
          title: 'Fragile',
          subtitle: 'Protect this shipment carefully',
          value: _isFragile,
          onChanged: (val) => setState(() => _isFragile = val),
        ),
        const SizedBox(height: 10),
        _buildHandlingItem(
          icon: Icons.ac_unit_rounded,
          title: 'Temperature sensitive',
          subtitle: 'Requires controlled handling',
          value: _isTemperatureSensitive,
          onChanged: (val) => setState(() => _isTemperatureSensitive = val),
        ),
      ],
    );
  }

  Widget _buildHandlingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReDoColors.cardBorder),
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
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF6F2E9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 20, color: ReDoColors.darkNavy),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ReDoColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ReDoColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: ReDoColors.primaryYellow,
            activeTrackColor: const Color(0xFFFFECC4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Estimated Cargo Value Input Card
  // --------------------------------------------------------------------------
  Widget _buildCargoValueInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ReDoColors.cardBorder),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3ECE0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '₹',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ReDoColors.darkNavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 14, color: ReDoColors.secondaryText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Used for additional protection and pricing.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: ReDoColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Bottom Fixed Section: Summary Card + Continue CTA
  // --------------------------------------------------------------------------
  Widget _buildBottomBar(String category, double currentWeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppColors.darkCard : ReDoColors.warmBg;
    final stripBg = isDark ? AppColors.darkCanvas : const Color(0xFFFFFDF8);
    final stripBorder = isDark ? AppColors.darkBorder : const Color(0xFFFFE8B4);

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3-Column Summary Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: stripBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: stripBorder),
            ),
            child: Row(
              children: [
                // Cargo
                Expanded(
                  child: _buildSummarySegment(
                    icon: Icons.inventory_2_outlined,
                    label: 'Cargo',
                    value: category,
                  ),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE9DFCE)),
                // Weight
                Expanded(
                  child: _buildSummarySegment(
                    icon: Icons.scale_rounded,
                    label: 'Weight',
                    value: '${currentWeight.round()} $_weightUnit',
                  ),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE9DFCE)),
                // Packages
                Expanded(
                  child: _buildSummarySegment(
                    icon: Icons.all_inbox_rounded,
                    label: 'Packages',
                    value: '$_packageCount',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Primary CTA Button
          ReDoButton(
            text: 'Continue',
            showArrow: true,
            onPressed: _handleContinue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySegment({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFFFECC4),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 16, color: ReDoColors.darkNavy),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: ReDoColors.secondaryText,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ReDoColors.darkNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// Custom Painters for Native Visuals (100% Native Vector, Zero Screenshots)
// ----------------------------------------------------------------------------

class _HeaderGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD685).withValues(alpha: 0.6),
          const Color(0xFFFFD685).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.5), size.width * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CargoPackagesVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Vector illustration representing parcels and gadget package
    final boxPaint = Paint()
      ..color = const Color(0xFFE29B24)
      ..style = PaintingStyle.fill;

    final boxShadow = Paint()
      ..color = const Color(0xFFBF7B12)
      ..style = PaintingStyle.fill;

    final tapePaint = Paint()
      ..color = const Color(0xFFC78415)
      ..style = PaintingStyle.fill;

    // Base package box
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.25, size.width * 0.6, size.height * 0.65),
      const Radius.circular(6),
    );
    canvas.drawRRect(baseRect, boxPaint);

    // Tape across box
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.62, size.height * 0.25, size.width * 0.08, size.height * 0.65),
      tapePaint,
    );

    // Front laptop gadget silhouette
    final devicePaint = Paint()
      ..color = const Color(0xFF2C3440)
      ..style = PaintingStyle.fill;

    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.35, size.width * 0.45, size.height * 0.48),
      const Radius.circular(4),
    );
    canvas.drawRRect(screenRect, devicePaint);

    final screenDisplayPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.39, size.width * 0.39, size.height * 0.4),
        const Radius.circular(2),
      ),
      screenDisplayPaint,
    );

    // Laptop keyboard base
    final basePad = Path()
      ..moveTo(size.width * 0.02, size.height * 0.85)
      ..lineTo(size.width * 0.52, size.height * 0.85)
      ..lineTo(size.width * 0.48, size.height * 0.92)
      ..lineTo(size.width * 0.05, size.height * 0.92)
      ..close();
    canvas.drawPath(basePad, boxShadow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IsometricBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final topPaint = Paint()..color = const Color(0xFFFFD685);
    final leftPaint = Paint()..color = const Color(0xFFE29B24);
    final rightPaint = Paint()..color = const Color(0xFFBF7B12);

    // Top face
    final top = Path()
      ..moveTo(cx, cy - 25)
      ..lineTo(cx + 35, cy - 8)
      ..lineTo(cx, cy + 10)
      ..lineTo(cx - 35, cy - 8)
      ..close();
    canvas.drawPath(top, topPaint);

    // Left face
    final left = Path()
      ..moveTo(cx - 35, cy - 8)
      ..lineTo(cx, cy + 10)
      ..lineTo(cx, cy + 40)
      ..lineTo(cx - 35, cy + 22)
      ..close();
    canvas.drawPath(left, leftPaint);

    // Right face
    final right = Path()
      ..moveTo(cx, cy + 10)
      ..lineTo(cx + 35, cy - 8)
      ..lineTo(cx + 35, cy + 22)
      ..lineTo(cx, cy + 40)
      ..close();
    canvas.drawPath(right, rightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
