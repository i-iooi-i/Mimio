import '../api/speakr_api.dart';

class SettingsSyncException implements Exception {
  const SettingsSyncException(this.message);
  final String message;
}

bool? readAutoSummarization(Map<String, dynamic> data) {
  final user = data['user'] is Map ? data['user'] as Map : data;
  final prefs = user['preferences'];
  final value = prefs is Map ? prefs['auto_summarization'] : null;
  return value is bool ? value : null;
}

Object? normalizedSetting(Object? value) => value == '' ? null : value;

Future<Map<String, dynamic>> saveFolderSettingsVerified(
  SpeakrApi api,
  int id,
  Map<String, dynamic> baseline,
  Map<String, dynamic> changes,
) async {
  final latest = await api.getFolderSettings(id);
  for (final key in changes.keys) {
    if (normalizedSetting(latest[key]) != normalizedSetting(baseline[key])) {
      throw const SettingsSyncException(
        'This setting changed on the server. Reload before saving.',
      );
    }
  }
  await api.updateFolderSettings(id, changes);
  try {
    final saved = await api.getFolderSettings(id);
    for (final key in changes.keys) {
      if (normalizedSetting(saved[key]) != normalizedSetting(changes[key])) {
        throw StateError('verification mismatch');
      }
    }
    return saved;
  } catch (_) {
    throw const SettingsSyncException(
      'The server accepted the update, but verification failed. Reload to check the actual state.',
    );
  }
}
