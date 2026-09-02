import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/models.dart';
import '../data/services/supabase_service.dart';

class ShipmentsViewModel extends ChangeNotifier {
  List<BookingItem> _shipments = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _channel;

  List<BookingItem> get shipments => _shipments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ShipmentsViewModel() {
    // LIVE: the partner advancing a trip on their app updates this list
    // instantly - no refresh button needed. (RLS scopes rows to this user.)
    _channel = SupabaseService.subscribeBookings(() => fetchShipments(silent: true));
  }

  @override
  void dispose() {
    if (_channel != null) SupabaseService.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> fetchShipments({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _shipments = await SupabaseService.getShipments();
      _errorMessage = null;
    } catch (e) {
      // Honest empty/error state - no fake sample shipments.
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// accepted -> confirmed (SME locks in the truck the owner offered).
  Future<String?> confirmBooking(BookingItem b) async {
    try {
      await SupabaseService.confirmBooking(b.id);
      await fetchShipments(silent: true);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// delivered -> completed (settles the trip: earnings + GST invoice).
  Future<String?> completeBooking(BookingItem b) async {
    try {
      await SupabaseService.completeBooking(b.id);
      await fetchShipments(silent: true);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> rate(BookingItem b, int stars) async {
    try {
      await SupabaseService.submitRating(b.id, stars);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}
