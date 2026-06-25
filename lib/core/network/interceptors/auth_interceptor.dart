import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interceptor that attaches the current Supabase JWT to every request
/// and handles automatic token refresh on 401 responses.
class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 Unauthorized
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Attempt to refresh the session
    try {
      final response = await Supabase.instance.client.auth.refreshSession();
      final newSession = response.session;

      if (newSession == null) {
        return handler.next(err);
      }

      // Retry the original request with the refreshed token
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer ${newSession.accessToken}';

      final dio = Dio();
      final retryResponse = await dio.fetch(opts);
      return handler.resolve(retryResponse);
    } catch (_) {
      // Refresh failed — propagate the original 401 error
      return handler.next(err);
    }
  }
}
