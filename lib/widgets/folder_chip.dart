import '../theme/appearance.dart';
import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Looks up a folder's color in the cached `foldersProvider` list.
/// Recording payloads carry only `{id, name}` for `folder` — color must be
/// resolved against the full folder list at render time.
Color resolveFolderColor(int? folderId, List<Folder> all) {
  if (folderId == null) return SpeakrColors.muted;
  for (final f in all) {
    if (f.id == folderId) return parseHexColor(f.color);
  }
  return SpeakrColors.muted;
}

/// Chip used on Detail / Live screens to show the assigned folder. Visually
/// distinct from [TagChip] thanks to the leading colored swatch and the
/// faint background fill that reads as a "container", not a label.
class FolderChip extends StatelessWidget {
  const FolderChip({
    super.key,
    required this.label,
    required this.color,
    this.filled = true,
  });
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    AppearanceScope.watch(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.06) : null,
        border: Border.all(color: color.withValues(alpha: 0.33)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: SpeakrText.mono(size: 10, color: color, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

/// Pill chip for the folder filter row at the top of the Library, plus the
/// inline picker on the Live capture screen. Mirrors the existing status
/// filter pill layout — colored swatch on the left, label on the right.
class FolderFilterChip extends StatelessWidget {
  const FolderFilterChip({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.showSwatch = true,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool showSwatch;

  @override
  Widget build(BuildContext context) {
    AppearanceScope.watch(context);
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? SpeakrColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: selected ? null : Border.all(color: SpeakrColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSwatch) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  border: selected
                      ? Border.all(color: SpeakrColors.bg, width: 1)
                      : null,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: SpeakrText.sans(
                size: 13,
                color: selected ? SpeakrColors.onAccent : SpeakrColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
