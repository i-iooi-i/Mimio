import 'package:dio/dio.dart';

import '../services/credentials_store.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._creds);

  final CredentialsStore _creds;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Custom authentication headers must not follow redirects to other hosts.
    options.followRedirects = false;
    final c = await _creds.read();
    if (c != null) {
      // Always rewrite the base URL — secure storage is the source of truth.
      // Default: /api/v1 (standard versioned endpoints).
      // extra['useRootApi'] = true → /api (the unofficial detail endpoint).
      // extra['noApiPrefix'] = true → bare host (some endpoints sit at root).
      final useRoot = options.extra['useRootApi'] == true;
      final noPrefix = options.extra['noApiPrefix'] == true;
      options.baseUrl = noPrefix
          ? c.baseUrl
          : '${c.baseUrl}/api${useRoot ? '' : '/v1'}';
      options.headers['X-API-Token'] = c.token;
      options.headers['Authorization'] = 'Bearer ${c.token}';
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }
}
