import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakr_app/api/auth_interceptor.dart';
import 'package:speakr_app/services/credentials_store.dart';

class _MemoryCredentials extends CredentialsStore {
  _MemoryCredentials(this.credentials);
  final SpeakrCredentials credentials;
  @override
  Future<SpeakrCredentials?> read() async => credentials;
}

void main() {
  test('credential diagnostics never expose connection or token', () {
    const credentials = SpeakrCredentials(
      baseUrl: 'https://private.example',
      token: 'test-secret-do-not-print',
    );
    for (final value in [credentials, credentials.copyWith()]) {
      expect(value.toString(), 'SpeakrCredentials([redacted])');
      expect(value.toJson()['token'], credentials.token);
    }
  });

  test('authenticated redirects never reach the second server', () async {
    final source = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var targetRequests = 0;
    String? receivedToken;
    target.listen((request) {
      targetRequests++;
      request.response.write('{}');
      request.response.close();
    });
    source.listen((request) {
      receivedToken = request.headers.value('X-API-Token');
      request.response.statusCode = HttpStatus.temporaryRedirect;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        'http://127.0.0.1:${target.port}/target',
      );
      request.response.close();
    });
    final client = Dio();
    client.interceptors.add(
      AuthInterceptor(
        _MemoryCredentials(
          SpeakrCredentials(
            baseUrl: 'http://127.0.0.1:${source.port}',
            token: 'fake-redirect-test-token',
          ),
        ),
      ),
    );
    try {
      await expectLater(
        client.get<dynamic>('/probe'),
        throwsA(isA<DioException>()),
      );
      expect(receivedToken, 'fake-redirect-test-token');
      expect(targetRequests, 0);
    } finally {
      client.close(force: true);
      await source.close(force: true);
      await target.close(force: true);
    }
  });
}
