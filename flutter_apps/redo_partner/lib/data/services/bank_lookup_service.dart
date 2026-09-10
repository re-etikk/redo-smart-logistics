import 'dart:convert';
import 'package:http/http.dart' as http;

class BankInfo {
  final String bank;
  final String branch;
  final String city;
  final String state;
  final String ifsc;
  final bool imps;
  final bool neft;

  const BankInfo({
    required this.bank,
    required this.branch,
    required this.city,
    required this.state,
    required this.ifsc,
    this.imps = true,
    this.neft = true,
  });
}

class BankLookupService {
  static final _client = http.Client();

  /// Looks up bank and branch details for any 11-digit Indian IFSC code.
  static Future<BankInfo?> lookupIfsc(String ifsc) async {
    final clean = ifsc.trim().toUpperCase().replaceAll(' ', '');
    if (clean.length != 11) return null;

    try {
      final res = await _client.get(
        Uri.parse('https://ifsc.razorpay.com/$clean'),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return BankInfo(
          bank: (data['BANK'] ?? '').toString(),
          branch: (data['BRANCH'] ?? '').toString(),
          city: (data['CITY'] ?? '').toString(),
          state: (data['STATE'] ?? '').toString(),
          ifsc: clean,
          imps: data['IMPS'] == true,
          neft: data['NEFT'] == true,
        );
      }
    } catch (_) {}

    return null;
  }
}
