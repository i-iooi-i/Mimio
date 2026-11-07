// Isolated native preview: fake recording state, no microphone or server access.
// flutter build windows --release -t tools/preview_mini_recorder.dart
import 'dart:async';
import 'dart:convert';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakr_app/features/live/mini/mini_ipc.dart';
import 'package:speakr_app/features/live/mini/mini_recorder_app.dart';
import 'package:speakr_app/features/live/mini/mini_window_native.dart';
import 'package:speakr_app/features/live/recording_state.dart';
import 'package:speakr_app/l10n/strings.dart';
import 'package:speakr_app/theme/appearance.dart';
import 'package:speakr_app/theme/typography.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  applyLanguage('zh');
  appAppearance.apply({'mode': 'light', 'palette': 'green'});
  if (args.isNotEmpty && args.first == 'multi_window') {
    runApp(
      ProviderScope(
        child: AppearanceApp(
          builder: () => MiniRecorderApp(windowId: int.parse(args[1])),
        ),
      ),
    );
    return;
  }
  Future<void> Function()? reopen;
  runApp(
    MaterialApp(
      theme: buildSpeakrTheme(),
      home: Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => reopen?.call(),
            child: const Text('再次显示胶囊（模拟，无录音）'),
          ),
        ),
      ),
    ),
  );
  await MiniWindowNative.setMainWindowTitle('Mimio · Mini preview');
  var state = const RecordingState(
    started: true,
    elapsedSeconds: 384,
    systemMode: SystemAudioMode.allSystem,
  );
  final mini = await DesktopMultiWindow.createWindow(
    jsonEncode({'role': MiniIpc.argRoleMini}),
  );
  Future<void> push() async {
    await DesktopMultiWindow.invokeMethod(
      mini.windowId,
      MiniIpc.stateUpdate,
      jsonEncode({
        ...state.toJson(),
        '_uiLanguage': appLanguage.value,
        '_appearance': appAppearance.toJson(),
      }),
    );
  }

  DesktopMultiWindow.setMethodHandler((call, from) async {
    switch (call.method) {
      case MiniIpc.cmdBeginDrag:
        await MiniWindowNative.beginMiniDrag();
      case MiniIpc.cmdTogglePause:
        state = state.copyWith(paused: !state.paused);
        await push();
      case MiniIpc.cmdStop:
        state = state.copyWith(started: false, uploading: true);
        await push();
      case MiniIpc.cmdCancel:
        state = state.copyWith(started: false, elapsedSeconds: 0);
        await push();
      case MiniIpc.cmdShowMain:
        await MiniWindowNative.focusMain();
        await mini.hide();
    }
    return null;
  });
  await mini.setTitle('Mimio · Mini preview controls');
  reopen = () async {
    await MiniWindowNative.applyMiniChrome(previewTaskbar: true);
  };
  await reopen();
  // Initial child-engine startup can race the first IPC snapshot.
  Timer.periodic(const Duration(seconds: 1), (_) async {
    await push();
  });
}
