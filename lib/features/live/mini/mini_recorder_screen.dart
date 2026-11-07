import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/strings.dart';
import '../../../theme/typography.dart';
import '../../../theme/colors.dart';
import '../../../theme/appearance.dart';
import '../../../widgets/speakr_icons.dart';
import '../recording_state.dart';
import 'recording_mirror.dart';

/// A desktop transport. Native window dimensions are logical pixels; see
/// MiniWindowNative for monitor scaling and the antialiased capsule surface.
class MiniRecorderScreen extends ConsumerWidget {
  const MiniRecorderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingMirrorProvider);
    final mirror = ref.read(recordingMirrorProvider.notifier);
    return MiniRecorderControls(
      state: state,
      onDrag: mirror.beginDrag,
      onPause: mirror.togglePause,
      onStop: mirror.stop,
      onDiscard: mirror.cancel,
      onOpenMain: mirror.showMain,
      onResumeAutoStop: mirror.resumeAutoStop,
    );
  }
}

/// Separated from IPC so all visible states and commands can be exercised
/// without opening a microphone or connecting to a server.
class MiniRecorderControls extends StatefulWidget {
  const MiniRecorderControls({
    super.key,
    required this.state,
    required this.onDrag,
    required this.onPause,
    required this.onStop,
    required this.onDiscard,
    required this.onOpenMain,
    required this.onResumeAutoStop,
  });
  final RecordingState state;
  final Future<void> Function() onDrag;
  final Future<void> Function() onPause;
  final Future<void> Function() onStop;
  final Future<void> Function() onDiscard;
  final Future<void> Function() onOpenMain;
  final Future<void> Function() onResumeAutoStop;

  @override
  State<MiniRecorderControls> createState() => _MiniRecorderControlsState();
}

class _MiniRecorderControlsState extends State<MiniRecorderControls> {
  bool _confirmDiscard = false;
  bool _busy = false;
  Timer? _confirmationTimer;

  void _dismissDiscard() {
    _confirmationTimer?.cancel();
    setState(() => _confirmDiscard = false);
  }

  void _armDiscard() {
    setState(() {
      _confirmDiscard = true;
    });
    _confirmationTimer?.cancel();
    _confirmationTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) _dismissDiscard();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _confirmationTimer?.cancel();
    setState(() {
      _busy = true;
      _confirmDiscard = false;
    });
    try {
      await action();
    } catch (_) {
      await widget.onOpenMain();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didUpdateWidget(covariant MiniRecorderControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.state.started ||
        widget.state.uploading ||
        widget.state.autoStopSecondsLeft != null) {
      _confirmationTimer?.cancel();
      _confirmDiscard = false;
    }
  }

  @override
  void dispose() {
    _confirmationTimer?.cancel();
    super.dispose();
  }

  bool _more = false;
  static const _ink = Color(0xFF1B2328);

  @override
  Widget build(BuildContext context) {
    LanguageScope.watch(context);
    AppearanceScope.watch(context);
    final s = widget.state;
    final enabled = s.started && !s.uploading && !_busy;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _dismissDiscard();
          setState(() => _more = false);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                if (_confirmDiscard) ...[
                  Expanded(
                    child: Text(
                      tr('Discard?'),
                      style: SpeakrText.sans(
                        size: 14,
                        color: SpeakrColors.accent,
                      ),
                    ),
                  ),
                  _button(tr('Cancel'), SpeakrIcon.close, _dismissDiscard),
                  const SizedBox(width: 8),
                  _button(
                    tr('Discard recording'),
                    SpeakrIcon.trash,
                    enabled ? () => _run(widget.onDiscard) : null,
                    danger: true,
                  ),
                ] else ...[
                  Expanded(
                    child: _DragArea(
                      onDrag: widget.onDrag,
                      child: Row(
                        children: [
                          Semantics(
                            label: s.paused
                                ? tr('Paused')
                                : tr('Recording in progress'),
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: s.paused
                                    ? const Color(0xFF949CA1)
                                    : const Color(0xFFF0806E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                s.autoStopSecondsLeft != null
                                    ? '00:${s.autoStopSecondsLeft!.toString().padLeft(2, '0')}'
                                    : s.formattedElapsed,
                                style: SpeakrText.mono(size: 19, color: _ink)
                                    .copyWith(
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFD9DFE3),
                  ),
                  const SizedBox(width: 10),
                  if (_more) ...[
                    _button(
                      tr('Discard recording'),
                      SpeakrIcon.trash,
                      enabled ? _armDiscard : null,
                    ),
                    const SizedBox(width: 6),
                    _button(
                      tr('Back'),
                      SpeakrIcon.back,
                      () => setState(() => _more = false),
                    ),
                  ] else ...[
                    _button(
                      s.autoStopSecondsLeft != null
                          ? tr('Keep recording')
                          : s.paused
                          ? tr('Resume')
                          : tr('Pause'),
                      s.paused || s.autoStopSecondsLeft != null
                          ? SpeakrIcon.play
                          : SpeakrIcon.pause,
                      enabled
                          ? () => _run(
                              s.autoStopSecondsLeft != null
                                  ? widget.onResumeAutoStop
                                  : widget.onPause,
                            )
                          : null,
                      filled: true,
                    ),
                    const SizedBox(width: 6),
                    _button(
                      tr('Stop & save'),
                      SpeakrIcon.stop,
                      enabled ? () => _run(widget.onStop) : null,
                      loading: s.uploading,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _button(
                    tr('Open recording window'),
                    SpeakrIcon.expand,
                    () => widget.onOpenMain(),
                  ),
                  if (!_more) ...[
                    const SizedBox(width: 6),
                    _button(
                      tr('More'),
                      SpeakrIcon.more,
                      () => setState(() => _more = true),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(
    String label,
    SpeakrIcon icon,
    VoidCallback? onPressed, {
    bool filled = false,
    bool danger = false,
    bool loading = false,
  }) {
    final color = danger
        ? SpeakrColors.accent
        : filled
        ? SpeakrColors.onAccent
        : _ink;
    return Semantics(
      label: label,
      button: true,
      onTap: onPressed,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: SizedBox(
        width: 40,
        height: 40,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(40),
            backgroundColor: filled ? SpeakrColors.accent : Colors.transparent,
            foregroundColor: color,
            shape: const CircleBorder(),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                )
              : SpeakrIconView(
                  icon,
                  size: 20,
                  color: onPressed == null ? const Color(0xFF949CA1) : color,
                ),
        ),
      ),
    );
  }
}

class _DragArea extends StatelessWidget {
  const _DragArea({required this.onDrag, required this.child});
  final Future<void> Function() onDrag;
  final Widget child;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.move,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        if (e.buttons == kPrimaryMouseButton) onDrag();
      },
      child: child,
    ),
  );
}
