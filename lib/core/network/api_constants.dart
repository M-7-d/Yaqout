import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API configuration constants.
///
/// All network-layer settings (base URLs, timeouts, headers)
/// live here so they can be changed in one place.
class ApiConstants {
  ApiConstants._();

  // ── Base URLs ───────────────────────────────────────────────────────────────
  /// Supabase REST base URL derived from the project URL in `.env`.
  static String get baseUrl =>
      '${dotenv.env['SUPABASE_URL'] ?? ''}/rest/v1';

  /// Supabase Edge Functions base URL.
  static String get functionsUrl =>
      '${dotenv.env['SUPABASE_URL'] ?? ''}/functions/v1';

  /// Raw Supabase project URL (useful for storage, auth, etc.).
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  // ── Timeouts ────────────────────────────────────────────────────────────────
  /// How long to wait for the TCP handshake.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// How long to wait for the server to start sending data.
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// How long to wait while uploading data.
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Headers ─────────────────────────────────────────────────────────────────
  /// Default headers attached to every request.
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'apikey': dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      };

  // ── Retry ───────────────────────────────────────────────────────────────────
  /// Maximum number of automatic retries for transient failures.
  static const int maxRetries = 3;

  /// Initial delay before the first retry (doubled each subsequent attempt).
  static const Duration retryBaseDelay = Duration(seconds: 1);
}
