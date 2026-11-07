import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/appearance.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class SettingsField extends StatelessWidget {
  const SettingsField({
    super.key,
    required this.label,
    this.hint,
    required this.child,
  });
  final String label;
  final String? hint;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    LanguageScope.watch(context);
    AppearanceScope.watch(context);
    final caption = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SpeakrText.sans(size: 14, weight: FontWeight.w500)),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: SpeakrText.sans(size: 12, color: SpeakrColors.muted),
          ),
        ],
      ],
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: SpeakrColors.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 600
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [caption, const SizedBox(height: 12), child],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 200, child: caption),
                  const SizedBox(width: 28),
                  Expanded(child: child),
                ],
              ),
      ),
    );
  }
}

InputDecoration settingsInputDecoration({String? hintText}) => InputDecoration(
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  hintText: hintText,
);
