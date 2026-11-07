import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/providers.dart';
import '../l10n/strings.dart';
import '../services/server_settings_sync.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class AutoSummarySettings extends ConsumerStatefulWidget {
  const AutoSummarySettings({super.key});
  @override
  ConsumerState<AutoSummarySettings> createState() =>
      _AutoSummarySettingsState();
}

class _AutoSummarySettingsState extends ConsumerState<AutoSummarySettings> {
  bool _saving = false, _error = false;
  String? _message;
  Future<void> _save(bool value) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    bool accepted = false;
    try {
      await ref.read(speakrApiProvider).setAutoSummarization(value);
      accepted = true;
      if (!mounted) return;
      ref.invalidate(currentUserInfoProvider);
      final actual = readAutoSummarization(
        await ref.read(currentUserInfoProvider.future),
      );
      if (actual != value) throw StateError('not verified');
      if (mounted) {
        setState(() {
          _error = false;
          _message = 'Saved and verified with Speakr.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = accepted
              ? 'The server accepted the update, but verification failed. Reload to check the actual state.'
              : 'Could not update the server setting. Check account permission.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserInfoProvider);
    final value = profile.value == null
        ? null
        : readAutoSummarization(profile.value!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (value == null)
              Text(
                tr(profile.isLoading ? 'Loading…' : 'Not available'),
                style: SpeakrText.sans(size: 12, color: SpeakrColors.muted),
              ),
            ChoiceChip(
              label: Text(tr('Enabled')),
              selected: value == true,
              onSelected: _saving || profile.isLoading || value == null
                  ? null
                  : (_) => _save(true),
            ),
            ChoiceChip(
              label: Text(tr('Disabled')),
              selected: value == false,
              onSelected: _saving || profile.isLoading || value == null
                  ? null
                  : (_) => _save(false),
            ),
            IconButton(
              tooltip: tr('Refresh'),
              onPressed: _saving
                  ? null
                  : () {
                      ref.invalidate(currentUserInfoProvider);
                      setState(() => _message = null);
                    },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (profile.hasError)
          Text(
            tr(
              'Could not load server information. Check connection and read permission.',
            ),
            style: SpeakrText.sans(size: 12, color: SpeakrColors.danger),
          ),
        if (_message != null)
          Text(
            tr(_message!),
            style: SpeakrText.sans(
              size: 12,
              color: _error ? SpeakrColors.danger : SpeakrColors.ok,
            ),
          ),
      ],
    );
  }
}
