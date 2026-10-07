import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/core/theme.dart';
import 'package:redo_customer/ui/screens/shipments/cargo_details_screen.dart';
import 'package:redo_customer/viewmodels/booking_viewmodel.dart';

class TestBookingViewModel extends ChangeNotifier implements BookingViewModel {
  @override
  String get origin => 'Delhi, DL';

  @override
  String get destination => 'Patna, BR';

  @override
  String get cargoType => 'Electronics';

  @override
  double get weightKg => 12.0;

  @override
  int get packageCount => 2;

  @override
  double get lengthCm => 30.0;

  @override
  double get widthCm => 20.0;

  @override
  double get heightCm => 15.0;

  @override
  bool get isFragile => false;

  @override
  bool get isTemperatureSensitive => false;

  @override
  double get declaredValueInr => 50000.0;

  @override
  void setWeightKg(double kg) {}

  @override
  void setPackageCount(int count) {}

  @override
  void setDimensions({required double length, required double width, required double height}) {}

  @override
  void setFragile(bool val) {}

  @override
  void setTemperatureSensitive(bool val) {}

  @override
  void setDeclaredValueInr(double val) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final screenSizes = [
    const Size(360, 640),
    const Size(375, 667),
    const Size(390, 844),
    const Size(393, 852),
    const Size(412, 915),
    const Size(428, 926),
  ];

  for (final size in screenSizes) {
    testWidgets('CargoDetailsScreen renders with 0 errors/overflow at ${size.width}x${size.height}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingViewModel>(
              create: (_) => TestBookingViewModel(),
            ),
          ],
          child: MaterialApp(
            theme: ReDoTheme.lightTheme,
            home: const CargoDetailsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cargo details'), findsOneWidget);
      expect(find.text('How heavy is it?'), findsOneWidget);
      expect(find.text('Package dimensions'), findsOneWidget);
      expect(find.text('Number of packages'), findsOneWidget);
      expect(find.text('Special handling'), findsOneWidget);
      expect(find.text('Estimated cargo value'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }
}
