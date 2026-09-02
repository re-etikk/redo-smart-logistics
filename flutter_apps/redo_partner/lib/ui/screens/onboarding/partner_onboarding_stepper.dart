import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/driver_onboarding_viewmodel.dart';
import '../../widgets/ui_components.dart';

const List<String> cities = ['Delhi NCR', 'Mumbai', 'Pune', 'Jaipur', 'Surat', 'Ahmedabad'];
const List<String> truckTypes = ['14FT', '17FT', '22FT Multi-Axle', '32FT High Deck'];
const List<String> bodyTypes = ['Closed container', 'Open body', 'Refrigerated', 'Flatbed'];

class PartnerOnboardingStepper extends StatefulWidget {
  const PartnerOnboardingStepper({super.key});

  @override
  State<PartnerOnboardingStepper> createState() => _PartnerOnboardingStepperState();
}

class _PartnerOnboardingStepperState extends State<PartnerOnboardingStepper> {
  final _nameController = TextEditingController(text: 'Harpreet Singh');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  String _selectedCity = 'Delhi NCR';

  final _regController = TextEditingController(text: 'DL 01 AB 4321');
  String _selectedTruckType = '22FT Multi-Axle';
  String _selectedBodyType = 'Closed container';
  final _capacityController = TextEditingController(text: '9.0');
  String _returnFromCity = 'Mumbai';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _regController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _pickDoc(String docType) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (img != null && mounted) {
      final bytes = await img.readAsBytes();
      context.read<DriverOnboardingViewModel>().uploadDoc(docType, bytes);
    } else if (mounted) {
      // simulate quick upload for testing
      context.read<DriverOnboardingViewModel>().uploadDoc(docType, Uint8List(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DriverOnboardingViewModel(),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Consumer<DriverOnboardingViewModel>(
            builder: (context, onboardingVM, _) {
              final step = onboardingVM.currentStep;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const RedoPartnerLogo(),
                    const SizedBox(height: 20),

                    // Stepper Progress Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final active = i <= step;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: active ? 28 : 12,
                          decoration: BoxDecoration(
                            color: active ? AppColors.brandYellow : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'STEP ${step + 1} OF 3',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 20),

                    // STEP 0: Driver Details
                    if (step == 0)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Driver Registration', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text('Your commercial driving identity on the REDO network.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Driver Full Name', prefixIcon: Icon(Icons.person_outline)),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Mobile Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                              ),
                              const SizedBox(height: 16),
                              Text('HOME BASE CITY', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: cities.map((c) {
                                  final sel = _selectedCity == c;
                                  return ChoiceChip(
                                    label: Text(c, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                                    selected: sel,
                                    selectedColor: AppColors.brandYellow,
                                    backgroundColor: AppColors.cardBg,
                                    onSelected: (_) => setState(() => _selectedCity = c),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              RedoButton(
                                title: 'Save & Continue to Truck',
                                isLoading: onboardingVM.isLoading,
                                onPressed: () {
                                  onboardingVM.setDriverInfo(_nameController.text, _phoneController.text, _selectedCity);
                                  onboardingVM.saveDriverStep();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    // STEP 1: Truck Details & Empty Return Trip
                    if (step == 1)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Truck Registration', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text('Register your vehicle & set your regular return corridor.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _regController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(labelText: 'Registration Number', hintText: 'DL 01 AB 4321', prefixIcon: Icon(Icons.local_shipping_outlined)),
                              ),
                              const SizedBox(height: 14),
                              Text('TRUCK TYPE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: truckTypes.map((t) {
                                  final sel = _selectedTruckType == t;
                                  return ChoiceChip(
                                    label: Text(t, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                                    selected: sel,
                                    selectedColor: AppColors.brandYellow,
                                    backgroundColor: AppColors.cardBg,
                                    onSelected: (_) => setState(() => _selectedTruckType = t),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                              Text('BODY TYPE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: bodyTypes.map((b) {
                                  final sel = _selectedBodyType == b;
                                  return ChoiceChip(
                                    label: Text(b, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                                    selected: sel,
                                    selectedColor: AppColors.brandYellow,
                                    backgroundColor: AppColors.cardBg,
                                    onSelected: (_) => setState(() => _selectedBodyType = b),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 14),
                              Text('NEXT EMPTY RETURN TRIP', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slateDark)),
                              Text('Shippers looking for backhauls to ${_selectedCity} will match this trip.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: cities.where((c) => c != _selectedCity).map((c) {
                                  final sel = _returnFromCity == c;
                                  return ChoiceChip(
                                    label: Text('From $c', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                                    selected: sel,
                                    selectedColor: AppColors.brandYellow,
                                    backgroundColor: AppColors.cardBg,
                                    onSelected: (_) => setState(() => _returnFromCity = c),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              RedoButton(
                                title: 'Save & Continue to Docs',
                                isLoading: onboardingVM.isLoading,
                                onPressed: () {
                                  onboardingVM.setTruckInfo(
                                    reg: _regController.text,
                                    type: _selectedTruckType,
                                    body: _selectedBodyType,
                                    capacity: double.tryParse(_capacityController.text) ?? 9.0,
                                    returnFrom: _returnFromCity,
                                  );
                                  onboardingVM.saveTruckStep();
                                },
                              ),
                              const SizedBox(height: 8),
                              RedoButton(
                                title: 'Back',
                                isSecondary: true,
                                onPressed: () => onboardingVM.previousStep(),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // STEP 2: Documents Verification
                    if (step == 2)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Documents & KYC', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text('Upload vehicle and identity proofs for verified instant loads.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _DocItem(
                            label: 'Commercial Driving Licence (DL)',
                            isDone: onboardingVM.uploadedDocs['driving_licence'] ?? false,
                            onUpload: () => _pickDoc('driving_licence'),
                          ),
                          _DocItem(
                            label: 'Vehicle RC Certificate',
                            isDone: onboardingVM.uploadedDocs['vehicle_rc'] ?? false,
                            onUpload: () => _pickDoc('vehicle_rc'),
                          ),
                          _DocItem(
                            label: 'Owner Identity (Aadhaar / PAN)',
                            isDone: onboardingVM.uploadedDocs['aadhaar_card'] ?? false,
                            onUpload: () => _pickDoc('aadhaar_card'),
                          ),

                          const SizedBox(height: 20),
                          RedoButton(
                            title: 'Complete Onboarding & Go Live',
                            isLoading: onboardingVM.isLoading,
                            onPressed: () async {
                              final done = await onboardingVM.finishOnboarding();
                              if (done && context.mounted) {
                                context.read<AuthViewModel>().onOnboardingCompleted();
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final String label;
  final bool isDone;
  final VoidCallback onUpload;

  const _DocItem({required this.label, required this.isDone, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.upload_file_outlined,
              color: isDone ? AppColors.success : AppColors.inkMuted,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            SizedBox(
              height: 36,
              child: RedoButton(
                title: isDone ? 'Uploaded' : 'Upload',
                isSecondary: isDone,
                onPressed: onUpload,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
