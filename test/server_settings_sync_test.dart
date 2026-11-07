import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakr_app/api/models.dart';
import 'package:speakr_app/api/providers.dart';
import 'package:speakr_app/api/speakr_api.dart';
import 'package:speakr_app/features/library/library_controller.dart';
import 'package:speakr_app/l10n/strings.dart';
import 'package:speakr_app/services/server_settings_sync.dart';
import 'package:speakr_app/widgets/folder_defaults_settings.dart';
import 'package:speakr_app/widgets/auto_summary_settings.dart';

class FakeSettingsApi extends SpeakrApi {
  FakeSettingsApi() : super(Dio());
  Map<String, dynamic> folder = {
    'id': 1,
    'name': 'Meetings',
    'can_edit': true,
    'default_language': 'zh',
    'default_min_speakers': 1,
    'default_max_speakers': 5,
    'custom_prompt': 'old',
    'retention_days': 90,
  };
  List<Map<String, dynamic>> writes = [];
  bool ignoreWrite = false;
  bool autoSummary = false;
  @override
  Future<Map<String, dynamic>> getFolderSettings(int id) async =>
      Map.of(folder);
  @override
  Future<void> updateFolderSettings(
    int id,
    Map<String, dynamic> changes,
  ) async {
    writes.add(Map.of(changes));
    if (!ignoreWrite) folder.addAll(changes);
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async => {
    'preferences': {'auto_summarization': autoSummary},
  };
  @override
  Future<void> setAutoSummarization(bool enabled) async {
    if (!ignoreWrite) autoSummary = enabled;
  }
}

void main() {
  setUp(() {
    appLanguage.value = 'en';
  });
  test(
    'partial folder save preserves unrelated settings and reads back',
    () async {
      final api = FakeSettingsApi();
      final saved = await saveFolderSettingsVerified(
        api,
        1,
        Map.of(api.folder),
        {'custom_prompt': 'new'},
      );
      expect(saved['custom_prompt'], 'new');
      expect(saved['retention_days'], 90);
      expect(api.writes.single, {'custom_prompt': 'new'});
    },
  );
  test(
    'server-side conflict blocks overwrite; unchanged response is not success',
    () async {
      final api = FakeSettingsApi();
      final baseline = Map<String, dynamic>.of(api.folder);
      api.folder['custom_prompt'] = 'edited on web';
      await expectLater(
        saveFolderSettingsVerified(api, 1, baseline, {
          'custom_prompt': 'desktop',
        }),
        throwsA(isA<SettingsSyncException>()),
      );
      expect(api.writes, isEmpty);
      api.ignoreWrite = true;
      await expectLater(
        saveFolderSettingsVerified(api, 1, Map.of(api.folder), {
          'custom_prompt': 'desktop',
        }),
        throwsA(isA<SettingsSyncException>()),
      );
    },
  );
  testWidgets(
    'folder editor validates ranges and saves actual changed field only',
    (tester) async {
      final api = FakeSettingsApi();
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            speakrApiProvider.overrideWithValue(api),
            foldersProvider.overrideWith(
              (ref) async => [const Folder(id: 1, name: 'Meetings')],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: FolderDefaultsSettings()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meetings'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('folder-default_min_speakers')),
        '10',
      );
      await tester.pump();
      await tester.tap(find.text('Save to Speakr'));
      await tester.pumpAndSettle();
      expect(api.writes, isEmpty);
      expect(
        find.text('Minimum speakers cannot exceed maximum speakers.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('folder-default_min_speakers')),
        '1',
      );
      await tester.enterText(
        find.byKey(const Key('folder-custom_prompt')),
        'Action items',
      );
      await tester.pump();
      await tester.tap(find.text('Save to Speakr'));
      await tester.pumpAndSettle();
      expect(api.writes.single, {'custom_prompt': 'Action items'});
      expect(find.text('Saved and verified with Speakr.'), findsOneWidget);
    },
  );
  testWidgets(
    'auto-summary reads server state and does not claim success on mismatch',
    (tester) async {
      final api = FakeSettingsApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [speakrApiProvider.overrideWithValue(api)],
          child: const MaterialApp(home: Scaffold(body: AutoSummarySettings())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Disabled'))
            .selected,
        true,
      );
      await tester.tap(find.text('Enabled'));
      await tester.pumpAndSettle();
      expect(api.autoSummary, true);
      expect(find.text('Saved and verified with Speakr.'), findsOneWidget);
      api.ignoreWrite = true;
      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();
      expect(find.text('Saved and verified with Speakr.'), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Enabled'))
            .selected,
        true,
      );
    },
  );
}
