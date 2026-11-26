import 'dart:convert';

import 'package:http/http.dart' as http;

/// Talks to the free Cloudflare Worker that emails a 6-digit reset code
/// (valid 5 minutes) and applies the new password after the code matches.
class ResetCodeException implements Exception {
  ResetCodeException(this.code);
  final String
  code; // invalid_code, expired, rate_limited, network, weak_password, unknown
  @override
  String toString() => 'ResetCodeException($code)';
}

class ResetCodeService {
  ResetCodeService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _base =
          baseUrl ??
          const String.fromEnvironment(
            'SUFRA_RESET_URL',
            defaultValue: 'https://sufra-reset.moos456456.workers.dev',
          ) {
    // Reset codes and new passwords only travel over HTTPS.
    if (!Uri.parse(_base).isScheme('https')) {
      throw ArgumentError.value(_base, 'baseUrl', 'must use https');
    }
  }

  final http.Client _client;
  final String _base;
  static const Duration codeLifetime = Duration(minutes: 5);

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final r = await _client
          .post(
            Uri.parse('$_base$path'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      final data = r.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode == 200) return data;
      throw ResetCodeException((data['error'] as String?) ?? 'unknown');
    } on ResetCodeException {
      rethrow;
    } catch (_) {
      throw ResetCodeException('network');
    }
  }

  /// Sends (or re-sends) a fresh code. Returns seconds the code stays valid.
  Future<int> requestCode(String email) async {
    final d = await _post('/request', {'email': email.trim().toLowerCase()});
    return (d['expiresIn'] as num?)?.toInt() ?? codeLifetime.inSeconds;
  }

  Future<void> confirm({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _post('/confirm', {
      'email': email.trim().toLowerCase(),
      'code': code,
      'newPassword': newPassword,
    });
  }
}
