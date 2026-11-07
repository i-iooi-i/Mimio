import 'package:dio/dio.dart';
import 'credentials_store.dart';

/// Tests draft credentials without changing the active connection.
class ConnectionSettings {
  static String normalizeUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Enter a valid HTTP or HTTPS server URL.');
    }
    return uri.toString().replaceFirst(RegExp(r'/+$'), '');
  }

  static Future<void> verify(
    SpeakrCredentials credentials, {
    Dio? client,
  }) async {
    final dio =
        client ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
          ),
        );
    try {
      final response = await dio.get<dynamic>(
        '${credentials.baseUrl}/api/v1/tokens/current',
        options: Options(
          followRedirects: false,
          headers: {
            'X-API-Token': credentials.token,
            'Authorization': 'Bearer ${credentials.token}',
            'Accept': 'application/json',
          },
        ),
      );
      final data = response.data;
      if (response.statusCode != 200 ||
          data is! Map ||
          data['id'] is! num ||
          data['scopes'] is! List) {
        throw const FormatException(
          'The server did not return a valid token response.',
        );
      }
    } finally {
      if (client == null) dio.close(force: true);
    }
  }
}
