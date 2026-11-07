import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakr_app/features/live/mini/mini_recorder_screen.dart';
import 'package:speakr_app/features/live/recording_state.dart';
import 'package:speakr_app/l10n/strings.dart';
import 'package:speakr_app/theme/appearance.dart';
import 'package:speakr_app/theme/typography.dart';
import 'package:speakr_app/widgets/speakr_icons.dart';

void main() {
  Future<void> noop() async {}
  Widget controls(
    RecordingState state, {
    Future<void> Function()? pause,
    Future<void> Function()? stop,
    Future<void> Function()? discard,
  }) => MaterialApp(
    theme: buildSpeakrTheme(),
    home: MiniRecorderControls(
      state: state,
      onDrag: noop,
      onPause: pause ?? noop,
      onStop: stop ?? noop,
      onDiscard: discard ?? noop,
      onOpenMain: noop,
      onResumeAutoStop: noop,
    ),
  );
  setUp(() => applyLanguage('en'));
  testWidgets('all actions fit at multiple DPI scales, locales and states', (
    tester,
  ) async {
    for (final scale in [1.0, 1.25, 1.5, 2.0]) {
      tester.view.devicePixelRatio = scale;
      tester.view.physicalSize = Size(320 * scale, 56 * scale);
      for (final language in ['en', 'zh']) {
        applyLanguage(language);
        for (final state in [
          const RecordingState(started: true, elapsedSeconds: 360001),
          const RecordingState(started: true, paused: true),
          const RecordingState(uploading: true),
          const RecordingState(started: true, autoStopSecondsLeft: 12),
          const RecordingState(error: 'unavailable'),
        ]) {
          await tester.pumpWidget(controls(state));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byType(TextButton), findsNWidgets(4));
          for (final element in find.byType(TextButton).evaluate()) {
            final r = tester.getRect(find.byWidget(element.widget));
            expect(r.right, lessThanOrEqualTo(320));
            expect(r.bottom, lessThanOrEqualTo(56));
          }
        }
      }
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
  testWidgets(
    'discard needs explicit confirmation, Escape and timeout cancel it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 56));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var discarded = 0;
      await tester.pumpWidget(
        controls(
          const RecordingState(started: true),
          discard: () async {
            discarded++;
          },
        ),
      );
      if (find
          .byWidgetPredicate(
            (w) => w is SpeakrIconView && w.icon == SpeakrIcon.more,
          )
          .evaluate()
          .isNotEmpty) {
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is SpeakrIconView && w.icon == SpeakrIcon.more,
          ),
        );
        await tester.pump();
      }
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is SpeakrIconView && w.icon == SpeakrIcon.trash,
        ),
      );
      await tester.pump();
      expect(discarded, 0);
      expect(find.text('Discard?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Discard?'), findsNothing);
      if (find
          .byWidgetPredicate(
            (w) => w is SpeakrIconView && w.icon == SpeakrIcon.more,
          )
          .evaluate()
          .isNotEmpty) {
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is SpeakrIconView && w.icon == SpeakrIcon.more,
          ),
        );
        await tester.pump();
      }
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is SpeakrIconView && w.icon == SpeakrIcon.trash,
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is SpeakrIconView && w.icon == SpeakrIcon.close,
        ),
      );
      await tester.pump();
      expect(discarded, 0);
      if (find
          .byWidgetPredicate(
            (w) => w is SpeakrIconView && w.icon == SpeakrIcon.more,
          )
          .evaluate()
          .isNotEmpty) {
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is SpeakrIconView && w.icon == SpeakrIcon.more,
          ),
        );
        await tester.pump();
      }
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is SpeakrIconView && w.icon == SpeakrIcon.trash,
        ),
      );
      await tester.pump(const Duration(seconds: 9));
      expect(find.text('Discard?'), findsNothing);
      if (find
          .byWidgetPredicate(
            (w) => w is SpeakrIconView && w.icon == SpeakrIcon.more,
          )
          .evaluate()
          .isNotEmpty) {
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is SpeakrIconView && w.icon == SpeakrIcon.more,
          ),
        );
        await tester.pump();
      }
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is SpeakrIconView && w.icon == SpeakrIcon.trash,
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is SpeakrIconView && w.icon == SpeakrIcon.trash,
        ),
      );
      await tester.pump();
      expect(discarded, 1);
    },
  );
  testWidgets(
    'pending commands cannot be repeated; saving disables destructive actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 56));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final pending = Completer<void>();
      var stops = 0;
      await tester.pumpWidget(
        controls(
          const RecordingState(started: true),
          stop: () {
            stops++;
            return pending.future;
          },
        ),
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is SpeakrIconView && w.icon == SpeakrIcon.stop,
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is SpeakrIconView && w.icon == SpeakrIcon.stop,
        ),
      );
      await tester.pump();
      expect(stops, 1);
      pending.complete();
      await tester.pump();
      await tester.pumpWidget(controls(const RecordingState(uploading: true)));
      final buttons = tester
          .widgetList<TextButton>(find.byType(TextButton))
          .toList();
      expect(buttons.where((b) => b.onPressed != null).length, 2);
    },
  );
  testWidgets('render light and dark previews', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 56));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    applyLanguage('zh');
    for (final mode in ['light', 'dark']) {
      appAppearance.apply({'mode': mode, 'palette': 'green'});
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: controls(
            const RecordingState(
              started: true,
              elapsedSeconds: 384,
              systemMode: SystemAudioMode.allSystem,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}
