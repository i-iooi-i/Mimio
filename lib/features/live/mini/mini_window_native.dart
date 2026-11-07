import 'package:flutter/services.dart';

/// Dart-side wrapper around the native Win32 helper registered in
/// `windows/runner/mini_window_native.cpp`. The helper applies always-on-top,
/// `WS_EX_TOOLWINDOW`, and a fixed compact frame to whichever top-level
/// window in this process is *not* the main app window.
///
/// All methods are no-ops on non-Windows platforms.
class MiniWindowNative {
  MiniWindowNative._();

  static const _channel = MethodChannel('speakr/mini_window_native');

  static void setMainRestoreHandler(Future<void> Function()? handler) {
    _channel.setMethodCallHandler(
      handler == null
          ? null
          : (call) async {
              if (call.method == 'mainRestored') await handler();
            },
    );
  }

  /// Apply always-on-top, no-taskbar, fixed size, and place the window in
  /// the top-right of the primary monitor. Safe to call multiple times.
  static Future<void> applyMiniChrome({
    int width = 320,
    int height = 56,
    bool previewTaskbar = false,
  }) async {
    try {
      await _channel.invokeMethod('applyMiniChrome', {
        'width': width,
        'height': height,
        'previewTaskbar': previewTaskbar,
      });
    } on MissingPluginException {
      // Helper not registered (non-Windows or older runner build) — silent.
    } catch (_) {
      // Don't let a chrome failure break recording.
    }
  }

  /// Send WM_CLOSE to the mini window. Safe if the window is already gone.
  static Future<void> closeMini() async {
    try {
      await _channel.invokeMethod('closeMini');
    } on MissingPluginException {
      // ignore
    } catch (_) {}
  }

  /// Hand the mini window over to Windows' move loop. Call while the LMB
  /// is still held by the user — the OS picks the drag up from the
  /// current cursor position.
  static Future<void> beginMiniDrag() async {
    try {
      await _channel.invokeMethod('beginMiniDrag');
    } on MissingPluginException {
      // ignore
    } catch (_) {}
  }

  /// Bring the main app window to the foreground. Used by the mini pill's
  /// "Open in main window" button.
  static Future<void> focusMain() async {
    try {
      await _channel.invokeMethod('focusMain');
    } on MissingPluginException {
      // ignore
    } catch (_) {}
  }

  /// Rewrite the caption of the main HWND. Used in dev mode so simultaneous
  /// worktree instances are distinguishable in the taskbar.
  static Future<void> setMainWindowTitle(String title) async {
    try {
      await _channel.invokeMethod('setMainWindowTitle', {'title': title});
    } on MissingPluginException {
      // Non-Windows or older runner build — silent.
    } catch (_) {
      // Title is cosmetic; never let it break startup.
    }
  }
}
