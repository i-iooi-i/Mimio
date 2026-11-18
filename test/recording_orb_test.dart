import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakr_app/widgets/recording_orb.dart';
import 'package:speakr_app/widgets/speakr_icons.dart';

void main() {
  Widget host({
    bool recording = false,
    bool reduced = false,
    bool busy = false,
    VoidCallback? onPressed,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: RecordingOrb(
          icon: SpeakrIcon.mic,
          label: 'Start recording',
          recording: recording,
          busy: busy,
          onPressed: onPressed,
        ),
      ),
    ),
  );

  testWidgets('action remains accessible and busy state prevents repeat taps', (
    tester,
  ) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(onPressed: () => taps++));
    expect(find.bySemanticsLabel('Start recording'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 1);
    await tester.pumpWidget(host(busy: true, onPressed: () => taps++));
    await tester.tap(find.byType(FilledButton));
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });

  testWidgets('recording pulses stop on pause and respect reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(host(recording: true, onPressed: () {}));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(host(onPressed: () {}));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(
      host(recording: true, reduced: true, onPressed: () {}),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(host(recording: true, onPressed: () {}));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
