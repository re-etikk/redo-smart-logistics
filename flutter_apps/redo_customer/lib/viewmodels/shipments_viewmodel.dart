import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/supabase_service.dart';

class ShipmentsViewModel extends ChangeNotifier {
  List<BookingItem> _shipments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingItem> get shipments => _shipments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchShipments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _shipments = await SupabaseService.getShipments();
      if (_shipments.isEmpty) {
        // Fallback default sample booking for seamless UI demo
        _shipments = [
          BookingItem(
            id: 'BK-89421',
            cargoId: 'CRG-5512',
            truckId: 'TRK-MH04-88',
            origin: 'Mumbai (Bhiwandi Hub)',
            destination: 'Delhi NCR (Gurugram)',
            cargoType: 'Automotive Spare Parts',
            weightTons: 8.5,
            agreedPriceInr: 22100.0,
            status: 'in_transit',
            currentLat: 22.7196,
            currentLng: 75.8577, // near Indore on Mumbai-Delhi corridor
            driverName: 'Harpreet Singh',
            driverPhone: '+91 98765 43210',
            truckReg: 'MH 04 GP 4421',
            createdAt: DateTime.now().subtract(const Duration(hours: 14)).toIso8601String(),
          ),
          BookingItem(
            id: 'BK-77210',
            cargoId: 'CRG-3319',
            truckId: 'TRK-RJ14-63',
            origin: 'Jaipur',
            destination: 'Surat',
            cargoType: 'Textile Fabric Rolls',
            weightTons: 12.0,
            agreedPriceInr: 18500.0,
            status: 'delivered',
            currentLat: 21.1702,
            currentLng: 72.8311,
            driverName: 'Ramesh Kumar',
            driverPhone: '+91 91234 56789',
            truckReg: 'RJ 14 CC 3110',
            createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          ),
        ];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
