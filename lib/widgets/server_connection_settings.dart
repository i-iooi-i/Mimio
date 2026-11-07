import 'settings_field.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/providers.dart';
import '../features/live/live_controller.dart';
import '../l10n/strings.dart';
import '../services/connection_settings.dart';
import '../services/credentials_store.dart';
import '../theme/appearance.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

final connectionVerifierProvider =
    Provider<Future<void> Function(SpeakrCredentials)>(
      (ref) =>
          (credentials) => ConnectionSettings.verify(credentials),
    );

class ServerConnectionSettings extends ConsumerStatefulWidget {
  const ServerConnectionSettings({super.key, required this.onSaved});
  final Future<void> Function() onSaved;
  @override
  ConsumerState<ServerConnectionSettings> createState() =>
      _ServerConnectionSettingsState();
}

class _ServerConnectionSettingsState
    extends ConsumerState<ServerConnectionSettings> {
  final _url = TextEditingController();
  final _token = TextEditingController();
  SpeakrCredentials? _saved;
  bool _loaded = false, _busy = false;
  String? _message;
  bool _error = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await ref.read(credentialsStoreProvider).read();
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _url.text = saved?.baseUrl ?? '';
        _loaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = 'Could not load connection settings.';
        });
      }
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  bool get _recordingBusy {
    final state = ref.read(recordingControllerProvider);
    return state.started || state.uploading;
  }

  Future<void> _submit(bool save) async {
    if (_busy) return;
    if (save && _recordingBusy) {
      setState(() {
        _error = true;
        _message = 'Finish recording or uploading before changing servers.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final url = ConnectionSettings.normalizeUrl(_url.text);
      final supplied = _token.text.trim();
      if (supplied.isEmpty && url != _saved?.baseUrl) {
        throw const FormatException(
          'Enter an API token for the new server address.',
        );
      }
      final token = supplied.isNotEmpty ? supplied : _saved?.token ?? '';
      if (token.isEmpty) {
        throw const FormatException('Server URL and API token are required.');
      }
      final draft = SpeakrCredentials(baseUrl: url, token: token);
      await ref.read(connectionVerifierProvider)(draft);
      if (!mounted) return;
      if (save) {
        if (_recordingBusy) {
          throw const FormatException(
            'Finish recording or uploading before changing servers.',
          );
        }
        final container = ProviderScope.containerOf(context, listen: false);
        await ref.read(credentialsStoreProvider).write(draft);
        container.invalidate(currentCredentialsProvider);
        container.invalidate(speakrApiProvider);
        if (!mounted) return;
        _saved = draft;
        _token.clear();
        await widget.onSaved();
      }
      if (mounted) {
        setState(() {
          _error = false;
          _message = save
              ? 'Connection settings saved.'
              : 'Connection verified. Changes have not been saved.';
        });
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = e.message;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _message =
              (e.response?.statusCode == 401 || e.response?.statusCode == 403)
              ? 'API token rejected or permission denied.'
              : 'Connection test failed. Check the address, token and network.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = 'Could not save connection settings. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    LanguageScope.watch(context);
    AppearanceScope.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Connection settings are stored only on this device.'),
          style: SpeakrText.sans(size: 13, color: SpeakrColors.muted),
        ),
        const SizedBox(height: 20),
        SettingsField(
          label: tr('Server URL'),
          child: TextField(
            key: const Key('server-url'),
            controller: _url,
            enabled: _loaded && !_busy,
            autocorrect: false,
            style: SpeakrText.sans(size: 14),
            onChanged: (_) => setState(() => _message = null),
            textAlignVertical: TextAlignVertical.center,
            decoration: settingsInputDecoration(),
          ),
        ),
        SettingsField(
          label: tr('API token'),
          hint: tr('Generated in Settings → API Tokens on your server.'),
          child: TextField(
            key: const Key('server-token'),
            controller: _token,
            enabled: _loaded && !_busy,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            style: SpeakrText.sans(size: 14),
            onChanged: (_) => setState(() => _message = null),
            textAlignVertical: TextAlignVertical.center,
            decoration: settingsInputDecoration(
              hintText: tr(
                'Leave blank to keep the token for the unchanged address.',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tr(
            'A new address requires its API token. Saving tests the connection first.',
          ),
          style: SpeakrText.sans(size: 12, color: SpeakrColors.muted),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: _loaded && !_busy ? () => _submit(true) : null,
              child: Text(tr(_busy ? 'Checking…' : 'Test and save')),
            ),
            OutlinedButton(
              onPressed: _loaded && !_busy ? () => _submit(false) : null,
              child: Text(tr('Test connection')),
            ),
            TextButton(
              onPressed: _loaded && !_busy
                  ? () => setState(() {
                      _url.text = _saved?.baseUrl ?? '';
                      _token.clear();
                      _message = null;
                    })
                  : null,
              child: Text(tr('Reset changes')),
            ),
          ],
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
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
