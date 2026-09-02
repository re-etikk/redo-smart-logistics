import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => message;
}

/// REST client for the Express backend — the SAME contract the website uses.
/// This is what makes both apps + web truly one platform: ML matching, the
/// booking state machine, notifications, earnings and invoices all live
/// server-side; the app never invents any of it locally.
class ApiService {
  static final _client = http.Client();
  static bool _warmedUp = false;

  static Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Render free tier sleeps after ~15 min idle; first request can take
  /// 30-60s. Call this early (fire-and-forget) so real calls are fast.
  static Future<void> warmup() async {
    if (_warmedUp) return;
    try {
      await _client
          .get(Uri.parse('${AppConfig.apiBaseUrl}/health'))
          .timeout(const Duration(seconds: 70));
      _warmedUp = true;
    } catch (_) {/* real calls will surface the error with context */}
  }

  static Future<dynamic> _call(String method, String path, [Object? body]) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    http.Response res;
    try {
      final req = http.Request(method, uri)..headers.addAll(_headers());
      if (body != null) req.body = jsonEncode(body);
      res = await http.Response.fromStream(await _client
          .send(req)
          .timeout(Duration(seconds: _warmedUp ? 25 : 70)));
      _warmedUp = true;
    } on TimeoutException {
      throw ApiException('NETWORK',
          'Server is waking up (free hosting) — please try again in a few seconds.');
    } catch (_) {
      throw ApiException('NETWORK',
          'Cannot reach the REDO server. Check your internet connection.');
    }
    final json = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw ApiException(
        (json is Map ? json['error'] : null)?.toString() ?? 'UNKNOWN',
        (json is Map ? json['message'] : null)?.toString() ?? 'Something went wrong (${res.statusCode}).',
      );
    }
    return json;
  }

  static Future<dynamic> get(String p) => _call('GET', p);
  static Future<dynamic> post(String p, [Object? b]) => _call('POST', p, b ?? {});
  static Future<dynamic> patch(String p, [Object? b]) => _call('PATCH', p, b ?? {});
}
