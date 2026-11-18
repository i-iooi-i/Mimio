import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/appearance.dart';
import '../theme/colors.dart';
import 'speakr_icons.dart';

/// Recording action with a quiet rim and a broad, outward-fading recording halo.
/// The pulses indicate capture state, not a measured sound-pressure waveform.
class RecordingOrb extends StatefulWidget {
  const RecordingOrb({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.recording = false,
    this.busy = false,
  });

  final SpeakrIcon icon;
  final String label;
  final VoidCallback? onPressed;
  final bool recording;
  final bool busy;

  @override
  State<RecordingOrb> createState() => _RecordingOrbState();
}

class _RecordingOrbState extends State<RecordingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  void _syncMotion() {
    final animate =
        widget.recording &&
        !widget.busy &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant RecordingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppearanceScope.watch(context);
    final enabled = widget.onPressed != null && !widget.busy;
    final accent = enabled || widget.busy
        ? SpeakrColors.accent
        : SpeakrColors.muted;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RecordingRings(
                    pulse: _pulse,
                    color: accent,
                    active:
                        widget.recording &&
                        !widget.busy &&
                        !MediaQuery.disableAnimationsOf(context),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: widget.label,
              excludeFromSemantics: true,
              child: SizedBox.square(
                dimension: 108,
                child: FilledButton(
                  onPressed: enabled ? widget.onPressed : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: SpeakrColors.accent,
                    foregroundColor: SpeakrColors.onAccent,
                    disabledBackgroundColor: SpeakrColors.line,
                    disabledForegroundColor: SpeakrColors.muted,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: Semantics(
                    label: widget.label,
                    child: widget.busy
                        ? SizedBox.square(
                            dimension: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SpeakrColors.muted,
                            ),
                          )
                        : SpeakrIconView(
                            widget.icon,
                            size: 36,
                            color: enabled
                                ? SpeakrColors.onAccent
                                : SpeakrColors.muted,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingRings extends CustomPainter {
  _RecordingRings({
    required this.pulse,
    required this.color,
    required this.active,
  }) : super(repaint: pulse);

  final Animation<double> pulse;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint();
    if (!active) {
      canvas.drawCircle(
        center,
        60,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: .24),
      );
      return;
    }

    // A filled disc behind the opaque button creates a broad, attached halo.
    // It starts at the button edge, expands outwards and fades monotonically;
    // at the loop boundary it is hidden underneath the button again.
    final t = pulse.value;
    final expansion = Curves.easeOutCubic.transform(t);
    final radius = 54 + 25 * expansion;
    final opacity = .60 * math.pow(1 - t, 1.4).toDouble();
    canvas.drawCircle(
      center,
      radius,
      paint..color = color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _RecordingRings oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.active != active ||
      oldDelegate.pulse != pulse;
}
