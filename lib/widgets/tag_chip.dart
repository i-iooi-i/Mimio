import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/colors.dart';
import '../theme/appearance.dart';
import '../theme/typography.dart';

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.tag});
  final Tag tag;

  @override
  Widget build(BuildContext context) {
    AppearanceScope.watch(context);
    final c = parseHexColor(tag.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: _tagDecoration(c),
      child: Text(
        tag.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SpeakrText.sans(
          size: 11,
          weight: FontWeight.w400,
          color: _tagInk(c, background: _tagBackground(c)),
        ),
      ),
    );
  }
}

class CustomColorTagChip extends StatelessWidget {
  const CustomColorTagChip({
    super.key,
    required this.label,
    required this.color,
    this.trailing,
    this.onTap,
  });
  final String label;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    AppearanceScope.watch(context);
    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: _tagDecoration(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: SpeakrText.sans(
              size: 11,
              weight: FontWeight.w400,
              color: _tagInk(color, background: _tagBackground(color)),
            ),
          ),
          if (trailing != null) const SizedBox(width: 5),
          if (trailing != null) trailing!,
        ],
      ),
    );
    return onTap == null
        ? inner
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(100),
            child: inner,
          );
  }
}

class DashedTagChip extends StatelessWidget {
  const DashedTagChip({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    AppearanceScope.watch(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: color.withValues(alpha: 0.33)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Text(
            '+ ${label.toUpperCase()}',
            style: SpeakrText.sans(size: 11, color: _tagInk(color)),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 3.0;
    const gap = 2.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(size.height / 2),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      var d = 0.0;
      while (d < m.length) {
        final next = d + dash;
        canvas.drawPath(
          m.extractPath(d, next.clamp(0, m.length).toDouble()),
          paint,
        );
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}

// Opaque, softly tinted surfaces keep tag contrast consistent across parents.
Color _tagBackground(Color source) => Color.alphaBlend(
  source.withValues(alpha: SpeakrColors.isDark ? .20 : .13),
  SpeakrColors.surface,
);

BoxDecoration _tagDecoration(Color source) => BoxDecoration(
  color: _tagBackground(source),
  border: Border.all(
    color: source.withValues(alpha: SpeakrColors.isDark ? .22 : .12),
  ),
  borderRadius: BorderRadius.circular(100),
);

// Keep category hues while ensuring readable text on the actual tinted surface.
Color _tagInk(Color source, {Color? background}) {
  var result = source;
  final luminance = (background ?? SpeakrColors.bgAlt).computeLuminance();
  for (var i = 0; i < 24; i++) {
    final l = result.computeLuminance();
    final ratio =
        (l > luminance ? l + .05 : luminance + .05) /
        (l > luminance ? luminance + .05 : l + .05);
    if (ratio >= 4.5) break;
    result = Color.lerp(
      result,
      appAppearance.brightness == Brightness.dark ? Colors.white : Colors.black,
      .08,
    )!;
  }
  return result;
}
