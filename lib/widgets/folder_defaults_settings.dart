import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/providers.dart';
import '../features/library/library_controller.dart';
import '../l10n/strings.dart';
import '../services/server_settings_sync.dart';
import '../theme/appearance.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'mimio_menu.dart';
import 'settings_field.dart';

class FolderDefaultsSettings extends ConsumerStatefulWidget {
  const FolderDefaultsSettings({super.key});
  @override
  ConsumerState<FolderDefaultsSettings> createState() =>
      _FolderDefaultsSettingsState();
}

class _FolderDefaultsSettingsState
    extends ConsumerState<FolderDefaultsSettings> {
  final _fields = {
    for (final key in [
      'default_language',
      'default_min_speakers',
      'default_max_speakers',
      'custom_prompt',
    ])
      key: TextEditingController(),
  };
  int? _id;
  Map<String, dynamic>? _baseline;
  bool _busy = false, _error = false;
  String? _message;
  bool get _dirty =>
      _baseline != null &&
      _fields.entries.any(
        (e) => e.value.text != (_baseline![e.key]?.toString() ?? ''),
      );
  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Map<String, dynamic> data) {
    _baseline = data;
    for (final e in _fields.entries) {
      e.value.text = data[e.key]?.toString() ?? '';
    }
  }

  Future<void> _load(int id) async {
    if (_busy) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Discard unsaved changes?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Discard')),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _id = id;
      _baseline = null;
    });
    try {
      final data = await ref.read(speakrApiProvider).getFolderSettings(id);
      if (mounted) setState(() => _fill(data));
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _message =
              'Could not load server information. Check connection and read permission.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _baseline == null || _id == null) return;
    final changes = <String, dynamic>{};
    try {
      for (final e in _fields.entries) {
        if (!_baseline!.containsKey(e.key)) continue;
        final raw = e.value.text.trim();
        if (raw == (_baseline![e.key]?.toString() ?? '')) continue;
        if (e.key.endsWith('_speakers')) {
          final number = int.tryParse(raw);
          if (number == null || number < 1 || number > 100) {
            throw const FormatException(
              'Speaker counts must be whole numbers between 1 and 100.',
            );
          }
          changes[e.key] = number;
        } else {
          if (e.key == 'default_language' &&
              raw.isNotEmpty &&
              !RegExp(r'^[a-z]{2,3}(-[A-Za-z]{2,4})?$').hasMatch(raw)) {
            throw const FormatException(
              'Use a language code such as zh or en, or leave it blank.',
            );
          }
          changes[e.key] = raw;
        }
      }
      final min =
          changes['default_min_speakers'] ?? _baseline!['default_min_speakers'];
      final max =
          changes['default_max_speakers'] ?? _baseline!['default_max_speakers'];
      if (min is num && max is num && min > max) {
        throw const FormatException(
          'Minimum speakers cannot exceed maximum speakers.',
        );
      }
      if (changes.isEmpty) return;
      setState(() {
        _busy = true;
        _message = null;
      });
      final saved = await saveFolderSettingsVerified(
        ref.read(speakrApiProvider),
        _id!,
        _baseline!,
        changes,
      );
      if (mounted) {
        ref.invalidate(foldersProvider);
        setState(() {
          _fill(saved);
          _error = false;
          _message = 'Saved and verified with Speakr.';
        });
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = e.message;
        });
      }
    } on SettingsSyncException catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _message =
              'Could not save folder defaults. Check write permission and folder ownership.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    String key,
    String label, {
    String? hint,
    bool multiline = false,
  }) => SettingsField(
    label: tr(label),
    hint: hint == null ? null : tr(hint),
    child: _baseline?.containsKey(key) != true
        ? Text(
            tr('Not available'),
            style: SpeakrText.sans(size: 13, color: SpeakrColors.muted),
          )
        : key == 'default_language' && !_busy && _baseline?['can_edit'] != false
        ? MimioSelect<String>(
            value: _fields[key]!.text,
            expanded: true,
            options: [
              for (final item in const [
                ('', 'Server default'),
                ('zh', 'Chinese'),
                ('en', 'English'),
                ('ja', 'Japanese'),
                ('ko', 'Korean'),
                ('fr', 'French'),
                ('de', 'German'),
                ('es', 'Spanish'),
                ('ru', 'Russian'),
              ])
                MimioSelectOption(value: item.$1, label: tr(item.$2)),
              if (!const [
                '',
                'zh',
                'en',
                'ja',
                'ko',
                'fr',
                'de',
                'es',
                'ru',
              ].contains(_fields[key]!.text))
                MimioSelectOption(
                  value: _fields[key]!.text,
                  label: _fields[key]!.text,
                ),
            ],
            onChanged: (value) => setState(() {
              _fields[key]!.text = value;
              _message = null;
            }),
          )
        : TextField(
            key: Key('folder-$key'),
            controller: _fields[key],
            enabled: !_busy && _baseline?['can_edit'] != false,
            minLines: multiline ? 3 : 1,
            maxLines: multiline ? 6 : 1,
            keyboardType: key.endsWith('_speakers')
                ? TextInputType.number
                : TextInputType.text,
            textAlignVertical: TextAlignVertical.center,
            style: SpeakrText.sans(size: 14),
            decoration: settingsInputDecoration(),
            onChanged: (_) => setState(() => _message = null),
          ),
  );
  @override
  Widget build(BuildContext context) {
    LanguageScope.watch(context);
    AppearanceScope.watch(context);
    final folders = ref.watch(foldersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(
            'Saved directly to Speakr. Defaults apply when the server processes recordings in this folder; existing transcripts are not rewritten.',
          ),
          style: SpeakrText.sans(size: 13, color: SpeakrColors.muted),
        ),
        SettingsField(
          label: tr('Folder'),
          child: _busy
              ? const LinearProgressIndicator()
              : MimioSelect<int>(
                  value: _id,
                  options: [
                    for (final folder in folders.value ?? [])
                      MimioSelectOption(value: folder.id, label: folder.name),
                  ],
                  onChanged: _load,
                  expanded: true,
                  placeholder: tr('Choose a folder'),
                  icon: Icons.folder_outlined,
                ),
        ),
        if (folders.isLoading) const LinearProgressIndicator(),
        if (folders.hasError)
          Text(
            tr(
              'Could not load server information. Check connection and read permission.',
            ),
          ),
        if (folders.hasValue && folders.value!.isEmpty)
          Text(
            tr('No folders available. Create a folder in the library first.'),
          ),
        if (_baseline != null) ...[
          if (_baseline!['can_edit'] == false)
            Text(
              tr('This folder is read-only for your account.'),
              style: SpeakrText.sans(size: 13, color: SpeakrColors.muted),
            ),
          _field(
            'default_language',
            'Default transcription language',
            hint:
                'Choose the default language for new transcription in this folder.',
          ),
          _field(
            'default_min_speakers',
            'Minimum speakers',
            hint:
                'Leave an unset value unchanged to inherit the server default.',
          ),
          _field(
            'default_max_speakers',
            'Maximum speakers',
            hint:
                'Leave an unset value unchanged to inherit the server default.',
          ),
          _field(
            'custom_prompt',
            'Summary instructions',
            hint: 'Describe the summary format or points to focus on.',
            multiline: true,
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(
              onPressed: !_busy && _dirty && _baseline?['can_edit'] != false
                  ? _save
                  : null,
              child: Text(tr('Save to Speakr')),
            ),
            OutlinedButton(
              onPressed: !_busy && _id != null ? () => _load(_id!) : null,
              child: Text(tr('Reload from server')),
            ),
          ],
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              tr(_message!),
              style: SpeakrText.sans(
                size: 13,
                color: _error ? SpeakrColors.danger : SpeakrColors.ok,
              ),
            ),
          ),
      ],
    );
  }
}
