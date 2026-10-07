import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/core/theme.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/data/services/routing_service.dart';
import 'package:redo_customer/ui/screens/shipments/driver_matching_screen.dart';
import 'package:redo_customer/viewmodels/booking_viewmodel.dart';

class TestBookingViewModel extends ChangeNotifier implements BookingViewModel {
  @override
  String get origin => 'Delhi, DL';

  @override
  String get destination => 'Patna, BR';

  @override
  String get cargoType => 'Mac Mini M4 Pro';

  @override
  double get weightKg => 12.0;

  @override
  double get priceTotalInr => 2850.0;

  @override
  List<TruckMatch> get matches => [];

  @override
  LatLng get originLatLng => const LatLng(28.6139, 77.2090);

  @override
  LatLng get destinationLatLng => const LatLng(25.5941, 85.1376);

  @override
  PlaceSuggestion get originPlace => PlaceSuggestion(
        name: 'Delhi, DL',
        description: 'New Delhi Logistics Hub',
        latLng: const LatLng(28.6139, 77.2090),
      );

  @override
  PlaceSuggestion get destPlace => PlaceSuggestion(
        name: 'Patna, BR',
        description: 'Patna Transport Nagar',
        latLng: const LatLng(25.5941, 85.1376),
      );

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
    testWidgets('DriverMatchingScreen renders with 0 errors/overflow at ${size.width}x${size.height}',
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
            home: const DriverMatchingScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Finding your driver'), findsOneWidget);
      expect(find.text('Searching nearby partners'), findsOneWidget);
      expect(find.text('Shipment details'), findsOneWidget);
      expect(find.text('Usually takes less than a minute'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }
}
