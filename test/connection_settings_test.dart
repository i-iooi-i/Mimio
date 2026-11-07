import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakr_app/features/live/live_controller.dart';
import 'package:speakr_app/features/live/recording_state.dart';
import 'package:speakr_app/services/connection_settings.dart';
import 'package:speakr_app/services/credentials_store.dart';
import 'package:speakr_app/widgets/server_connection_settings.dart';
import 'package:speakr_app/l10n/strings.dart';
import 'live_preparation_test.dart' show TestRecorder;

class MemoryCredentials extends CredentialsStore {
  SpeakrCredentials saved = const SpeakrCredentials(
    baseUrl: 'https://old.example',
    token: 'old-token',
  );
  int writes = 0;
  @override
  Future<SpeakrCredentials?> read() async => saved;
  @override
  Future<void> write(SpeakrCredentials value) async {
    saved = value;
    writes++;
  }
}

void main() {
  test(
    'URL validation excludes embedded credentials, query and unsafe schemes',
    () {
      expect(
        ConnectionSettings.normalizeUrl(' https://example.com/base/// '),
        'https://example.com/base',
      );
      for (final url in [
        'file:///tmp',
        'https://user:pass@example.com',
        'https://example.com?token=x',
        'example.com',
      ]) {
        expect(
          () => ConnectionSettings.normalizeUrl(url),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'probe rejects HTML and does not follow credential-bearing redirects',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.followRedirects, false);
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: '<html>login</html>',
              ),
            );
          },
        ),
      );
      await expectLater(
        ConnectionSettings.verify(
          const SpeakrCredentials(
            baseUrl: 'https://example.com',
            token: 'test',
          ),
          client: dio,
        ),
        throwsFormatException,
      );
      dio.close();
    },
  );
  test(
    'secure store migrates legacy credentials and clears both formats',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'speakr.baseUrl': 'https://old.example',
        'speakr.token': 'old',
      });
      final store = CredentialsStore();
      expect((await store.read())!.token, 'old');
      await store.write(
        const SpeakrCredentials(baseUrl: 'https://new.example', token: 'new'),
      );
      expect((await store.read())!.baseUrl, 'https://new.example');
      expect((await store.read())!.token, 'new');
      await store.clear();
      expect(await store.read(), null);
    },
  );
  testWidgets(
    'draft test never saves, failed verification preserves old credentials, successful save replaces them',
    (tester) async {
      appLanguage.value = 'en';
      final store = MemoryCredentials();
      var fail = false, probes = 0, savedCallbacks = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialsStoreProvider.overrideWithValue(store),
            recordingControllerProvider.overrideWith(
              (ref) => TestRecorder(const RecordingState()),
            ),
            connectionVerifierProvider.overrideWithValue((value) async {
              probes++;
              if (fail) throw const FormatException('failed');
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ServerConnectionSettings(
                  onSaved: () async {
                    savedCallbacks++;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('server-url')),
        'https://new.example',
      );
      await tester.tap(find.text('Test and save'));
      await tester.pumpAndSettle();
      expect(probes, 0);
      expect(store.writes, 0);
      await tester.enterText(
        find.byKey(const Key('server-token')),
        'new-token',
      );
      await tester.tap(find.text('Test connection'));
      await tester.pumpAndSettle();
      expect(probes, 1);
      expect(store.writes, 0);
      fail = true;
      await tester.tap(find.text('Test and save'));
      await tester.pumpAndSettle();
      expect(store.saved.baseUrl, 'https://old.example');
      expect(store.writes, 0);
      fail = false;
      await tester.tap(find.text('Test and save'));
      await tester.pumpAndSettle();
      expect(store.saved.baseUrl, 'https://new.example');
      expect(store.saved.token, 'new-token');
      expect(store.writes, 1);
      expect(savedCallbacks, 1);
    },
  );
  testWidgets('active recording blocks connection changes before probing', (
    tester,
  ) async {
    appLanguage.value = 'en';
    final store = MemoryCredentials();
    var probes = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          credentialsStoreProvider.overrideWithValue(store),
          recordingControllerProvider.overrideWith(
            (ref) => TestRecorder(const RecordingState(started: true)),
          ),
          connectionVerifierProvider.overrideWithValue((value) async {
            probes++;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(body: ServerConnectionSettings(onSaved: () async {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test and save'));
    await tester.pumpAndSettle();
    expect(probes, 0);
    expect(store.writes, 0);
  });
}
