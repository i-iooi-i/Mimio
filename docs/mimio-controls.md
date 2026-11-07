# Mimio controls

Use the shared widgets instead of adding independent popup implementations.

- `MimioMenuButton` and `MimioMenuItem`: action menus, folder/tag menus and selectors. Surface geometry comes from `PopupMenuThemeData` and `SpeakrRadius.menu` (12 px). Popup contents clip to that shape. The selected check occupies a fixed trailing column.
- `MimioSelect`: language, model and other value selectors. Pass already-localized interface labels; preserve server-provided names. Native popup routes provide focus, keyboard dismissal and screen-edge positioning.
- Child-based menu triggers use `SpeakrRadius.control` for capsule hover/press effects. Icon-only menu triggers and regular `IconButton`s use circles.
- Compact icon buttons must have equal width/height. The search clear button is 28 × 28 inside the 38 px capsule; do not constrain only its width.
- `DesktopDropdown` is a compatibility wrapper around `MimioSelect`. The unused independent overlay action menu was removed.

Visible interface copy goes through `tr()` and `zh_cn.dart`. Subscribe to `LanguageScope` when resolving text and `AppearanceScope` when resolving colors outside a theme rebuild. Keep recording titles, tags, folders, model identifiers, API wire values and diagnostic details unchanged. Language names are localized in the current interface language.

Relevant regression coverage: `language_menu_test.dart`, `mimio_menu_test.dart`, `desktop_library_test.dart`, `localization_test.dart`.

`MimioPanel` paints its rounded outline in `foregroundDecoration`, above child backgrounds. Use it for shell/detail surfaces so footer Material backgrounds cannot obscure the bottom corners.

`UserAvatar` shares the device-local URL from `LocalAvatarController`; use `AvatarSettings` to edit/reset it. Only HTTP(S) links without embedded credentials are accepted. Requests use Flutter's image loader without Speakr authentication headers. Loading/error states show initials. Never send this preference to the Speakr API.

The visible app version is the release version only; the `+N` in pubspec remains an internal build number. Generate the Windows M icon with `flutter test tools/build_icon_sources.dart`, which reuses `MimioLogoPainter` instead of maintaining another drawing.

The Windows floating recorder uses the approved A concept: a white 320 × 56 DIP capsule, recording dot, tabular timer and icon-only pause, stop/save, return and overflow controls. Targets remain 40 DIPs. Discard lives inside overflow and requires confirmation; Escape, Cancel or 8 seconds dismisses it. The native white alpha surface renders the full semicircular outline and soft shadow underneath the clipped Flutter interior, follows its position/DPI, ignores pointer input, and is destroyed with it.

Only one recording surface is visible: after successfully creating/configuring the capsule, the main window minimizes. Returning via the arrow restores the main window and disposes the capsule without stopping capture. Restoring the main window via the taskbar also hides/disposes the capsule; reopening it preserves recording state. Stop/discard returns to the main window. `tools/preview_mini_recorder.dart` exercises these transitions with simulated recording state, without microphone or server access. It is never the production entry point.

The capsule is sized and rounded while hidden, then shown by the native helper; Dart must not call show before applying chrome. Application text uses upright fonts; Markdown emphasis uses medium weight instead of synthetic italics.

Main recording pause/resume controls use the shared accent surface and onAccent icon colors, without a raised shadow. Record/start uses accent/onAccent; stop/save icons use accent in both main and capsule controls.

Capsule pause/resume uses the same accent/onAccent pair and observes appearance changes.

Discard/delete confirmation actions and sign-out actions follow accent/onAccent, including the recording sheet and capsule. Destructive wording and confirmation behavior remain intact; error messages retain semantic error colors.
