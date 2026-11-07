#include "mini_window_native.h"

#include <flutter/encodable_value.h>

#include <dwmapi.h>
#include <algorithm>
#include <cmath>
#include <string>
#include <variant>

namespace {

// Custom timer id used on the main HWND to drive the retry-apply loop.
constexpr UINT_PTR kApplyTimerId = 0x53504B41;  // 'SPKA'

int IntFromEncodable(const flutter::EncodableValue& v, int fallback) {
  if (const auto* i = std::get_if<int32_t>(&v)) return *i;
  if (const auto* l = std::get_if<int64_t>(&v)) return static_cast<int>(*l);
  if (const auto* d = std::get_if<double>(&v)) return static_cast<int>(*d);
  return fallback;
}

}  // namespace

MiniWindowNative::MiniWindowNative(flutter::FlutterEngine* engine,
                                     HWND main_hwnd)
    : main_hwnd_(main_hwnd) {
  channel_ = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(),
      "speakr/mini_window_native",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });
}

MiniWindowNative::~MiniWindowNative() {
  if (capsule_surface_) ::DestroyWindow(capsule_surface_);
  if (mini_hwnd_ && ::IsWindow(mini_hwnd_)) {
    ::RemoveWindowSubclass(mini_hwnd_, MiniSubclassProc, kApplyTimerId);
  }
  if (apply_in_progress_) {
    ::KillTimer(main_hwnd_, kApplyTimerId);
    apply_in_progress_ = false;
  }
}

void MiniWindowNative::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();
  if (method == "applyMiniChrome") {
    int width = 320;
    int height = 56;
    if (const auto* args =
            std::get_if<flutter::EncodableMap>(call.arguments())) {
      auto wit = args->find(flutter::EncodableValue("width"));
      if (wit != args->end()) width = IntFromEncodable(wit->second, width);
      auto hit = args->find(flutter::EncodableValue("height"));
      if (hit != args->end()) height = IntFromEncodable(hit->second, height);
    }
    preview_taskbar_ = false;
    if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
      auto it = args->find(flutter::EncodableValue("previewTaskbar"));
      if (it != args->end()) {
        if (const auto* value = std::get_if<bool>(&it->second)) preview_taskbar_ = *value;
      }
    }
    ScheduleApply(width, height);
    result->Success();
    return;
  }
  if (method == "closeMini") {
    HWND mini = FindMiniHwnd();
    if (mini != nullptr) {
      ::PostMessage(mini, WM_CLOSE, 0, 0);
    }
    result->Success();
    return;
  }
  if (method == "focusMain") {
    if (mini_hwnd_) ::ShowWindow(mini_hwnd_, SW_HIDE);
    if (capsule_surface_) ::ShowWindow(capsule_surface_, SW_HIDE);
    // Main window may be hidden (close-to-tray) or minimized. SW_SHOW
    // brings a hidden window back; SW_RESTORE unminimizes. Mirrors
    // BringWindowToForegroundImpl in flutter_window.cpp.
    if (main_hwnd_ != nullptr) {
      ::ShowWindow(main_hwnd_, SW_SHOW);
      if (::IsIconic(main_hwnd_)) {
        ::ShowWindow(main_hwnd_, SW_RESTORE);
      }
      ::SetForegroundWindow(main_hwnd_);
    }
    result->Success();
    return;
  }
  if (method == "beginMiniDrag") {
    // Hand the mini window over to Windows' built-in title-bar move loop.
    // Requires the LMB to currently be down on the user's side; the IPC
    // round-trip is sub-ms, so a click-drag from the in-app top bar
    // reaches here while the button is still pressed.
    HWND mini = FindMiniHwnd();
    if (mini != nullptr) {
      ::ReleaseCapture();
      ::PostMessage(mini, WM_NCLBUTTONDOWN, HTCAPTION, 0);
    }
    result->Success();
    return;
  }
  if (method == "setMainWindowTitle") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args == nullptr) {
      result->Error("bad_args", "expected map with 'title'");
      return;
    }
    auto it = args->find(flutter::EncodableValue("title"));
    if (it == args->end()) {
      result->Error("bad_args", "missing 'title'");
      return;
    }
    const auto* title_utf8 = std::get_if<std::string>(&it->second);
    if (title_utf8 == nullptr) {
      result->Error("bad_args", "'title' must be a string");
      return;
    }
    int wide_len = ::MultiByteToWideChar(CP_UTF8, 0, title_utf8->c_str(),
                                         static_cast<int>(title_utf8->size()),
                                         nullptr, 0);
    std::wstring wide(wide_len, L'\0');
    if (wide_len > 0) {
      ::MultiByteToWideChar(CP_UTF8, 0, title_utf8->c_str(),
                            static_cast<int>(title_utf8->size()), wide.data(),
                            wide_len);
    }
    ::SetWindowTextW(main_hwnd_, wide.c_str());
    result->Success();
    return;
  }
  result->NotImplemented();
}

void MiniWindowNative::ScheduleApply(int width, int height) {
  pending_width_ = width;
  pending_height_ = height;
  apply_attempts_ = 0;
  apply_in_progress_ = true;
  TryApplyOnce();
  if (apply_in_progress_) {
    ::SetTimer(main_hwnd_, kApplyTimerId, 50, nullptr);
  }
}

bool MiniWindowNative::HandleWindowMessage(HWND /*hwnd*/, UINT message,
                                            WPARAM wparam, LPARAM /*lparam*/) {
  if (message == WM_ACTIVATE && LOWORD(wparam) != WA_INACTIVE &&
      !::IsIconic(main_hwnd_) && mini_hwnd_ && ::IsWindowVisible(mini_hwnd_)) {
    ::ShowWindow(mini_hwnd_, SW_HIDE);
    if (capsule_surface_) ::ShowWindow(capsule_surface_, SW_HIDE);
    channel_->InvokeMethod("mainRestored", nullptr);
  }
  if (message == WM_TIMER && wparam == kApplyTimerId) {
    TryApplyOnce();
    if (!apply_in_progress_) {
      ::KillTimer(main_hwnd_, kApplyTimerId);
    }
    return true;
  }
  return false;
}

void MiniWindowNative::TryApplyOnce() {
  if (!apply_in_progress_) return;
  apply_attempts_++;
  HWND mini = FindMiniHwnd();
  if (mini == nullptr) {
    if (apply_attempts_ > 60) {  // ~3 seconds total
      apply_in_progress_ = false;
    }
    return;
  }

  mini_hwnd_ = mini;
  ::SetWindowSubclass(mini, MiniSubclassProc, kApplyTimerId,
                      reinterpret_cast<DWORD_PTR>(this));
  // Borderless Flutter interior; the companion alpha surface supplies
  // the smooth semicircular outline and shadow.
  LONG style = ::GetWindowLong(mini, GWL_STYLE);
  style &= ~(WS_MAXIMIZEBOX | WS_MINIMIZEBOX | WS_CAPTION |
             WS_SYSMENU | WS_BORDER | WS_DLGFRAME);
  style &= ~WS_THICKFRAME;
  style |= WS_POPUP;
  ::SetWindowLong(mini, GWL_STYLE, style);
  LONG ex = ::GetWindowLong(mini, GWL_EXSTYLE);
  ex |= WS_EX_TOPMOST;
  if (preview_taskbar_) {
    ex |= WS_EX_APPWINDOW;
    ex &= ~WS_EX_TOOLWINDOW;
  } else {
    ex |= WS_EX_TOOLWINDOW;
    ex &= ~WS_EX_APPWINDOW;
  }
  ::SetWindowLong(mini, GWL_EXSTYLE, ex);

  HMONITOR mon = ::MonitorFromWindow(main_hwnd_, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO mi{sizeof(MONITORINFO)};
  ::GetMonitorInfo(mon, &mi);
  // Dart layout uses DIPs, whereas SetWindowPos consumes physical pixels.
  // Scaling these together prevents controls being cropped at 125-200%.
  UINT dpi = ::GetDpiForWindow(main_hwnd_);
  if (!dpi) dpi = 96;
  const int width = ::MulDiv(pending_width_, dpi, 96);
  const int height = ::MulDiv(pending_height_, dpi, 96);
  const int margin = ::MulDiv(24, dpi, 96);
  const int x = std::max(mi.rcWork.left, mi.rcWork.right - width - margin);
  const int y = mi.rcWork.top + margin;
  // Configure the hidden window before its first visible frame.
  ::SetWindowPos(mini, HWND_TOPMOST, x, y, width, height,
                 SWP_NOACTIVATE | SWP_FRAMECHANGED);
  ApplyCorners(mini, dpi);
  ::ShowWindow(mini, SW_SHOWNOACTIVATE);
  UpdateCapsuleSurface(mini);
  // Only hand off after a real, visible recorder window has been configured.
  ::ShowWindow(main_hwnd_, SW_MINIMIZE);
  apply_in_progress_ = false;
}

void MiniWindowNative::ApplyCorners(HWND hwnd, UINT dpi) {
  const int width = ::MulDiv(pending_width_, dpi, 96);
  const int height = ::MulDiv(pending_height_, dpi, 96);
  // Flutter owns the opaque interior. A per-pixel-alpha surface underneath
  // owns the outer two pixels and soft shadow, avoiding a jagged HRGN edge.
  HRGN region = ::CreateRoundRectRgn(2, 2, width - 1, height - 1,
                                     height - 4, height - 4);
  if (!::SetWindowRgn(hwnd, region, TRUE)) ::DeleteObject(region);
  UpdateCapsuleSurface(hwnd);
}

void MiniWindowNative::UpdateCapsuleSurface(HWND hwnd) {
  if (!::IsWindowVisible(hwnd)) {
    if (capsule_surface_) ::ShowWindow(capsule_surface_, SW_HIDE);
    return;
  }
  RECT rect{};
  ::GetWindowRect(hwnd, &rect);
  const int width = rect.right - rect.left;
  const int height = rect.bottom - rect.top;
  if (width <= 0 || height <= 0) return;
  const int pad = std::max(8, ::MulDiv(8, ::GetDpiForWindow(hwnd), 96));
  const int w = width + 2 * pad, h = height + 2 * pad;
  if (!capsule_surface_) {
    capsule_surface_ = ::CreateWindowExW(
        WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW |
        WS_EX_NOACTIVATE | WS_EX_TOPMOST,
        L"STATIC", L"Mimio capsule surface", WS_POPUP,
        0, 0, w, h, nullptr, nullptr, ::GetModuleHandle(nullptr), nullptr);
  }
  if (!capsule_surface_) return;
  BITMAPINFO info{};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = w;
  info.bmiHeader.biHeight = -h;
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  info.bmiHeader.biCompression = BI_RGB;
  void* pixels = nullptr;
  HDC screen = ::GetDC(nullptr);
  HDC memory = ::CreateCompatibleDC(screen);
  HBITMAP bitmap = ::CreateDIBSection(screen, &info, DIB_RGB_COLORS,
                                     &pixels, nullptr, 0);
  if (bitmap && pixels && memory) {
    HGDIOBJ previous = ::SelectObject(memory, bitmap);
    auto* out = static_cast<DWORD*>(pixels);
    const double radius = height / 2.0;
    const double straight = (width - height) / 2.0;
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        const double dx = std::max(std::abs(x + .5 - pad - width / 2.0) - straight, 0.0);
        const double dy = y + .5 - pad - radius;
        const double distance = std::hypot(dx, dy) - radius;
        const double fill = std::clamp(.5 - distance, 0.0, 1.0);
        const double shadowDistance = std::max(std::hypot(dx, dy - 2.0) - radius, 0.0);
        const double shadow = .16 * std::exp(-shadowDistance * shadowDistance / 18.0);
        const DWORD alpha = static_cast<DWORD>(255 * (fill + shadow * (1 - fill)));
        const DWORD white = static_cast<DWORD>(255 * fill);
        out[y * w + x] = (alpha << 24) | (white << 16) | (white << 8) | white;
      }
    }
    POINT position{rect.left - pad, rect.top - pad}, source{0, 0};
    SIZE size{w, h};
    BLENDFUNCTION blend{AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
    ::UpdateLayeredWindow(capsule_surface_, screen, &position, &size,
                         memory, &source, 0, &blend, ULW_ALPHA);
    ::SetWindowPos(capsule_surface_, hwnd, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
    ::SelectObject(memory, previous);
  }
  if (bitmap) ::DeleteObject(bitmap);
  if (memory) ::DeleteDC(memory);
  ::ReleaseDC(nullptr, screen);
}

LRESULT CALLBACK MiniWindowNative::MiniSubclassProc(HWND hwnd, UINT message,
    WPARAM wparam, LPARAM lparam, UINT_PTR id, DWORD_PTR data) {
  auto* self = reinterpret_cast<MiniWindowNative*>(data);
  if (message == WM_NCCALCSIZE && wparam) return 0;
  if (message == WM_NCHITTEST) {
    const LRESULT hit = ::DefSubclassProc(hwnd, message, wparam, lparam);
    // Fixed-size transport: Windows must not expose resize handles.
    if (hit >= HTLEFT && hit <= HTBOTTOMRIGHT) return HTCLIENT;
    return hit;
  }
  if (message == WM_DPICHANGED) {
    const UINT dpi = HIWORD(wparam);
    ::DefSubclassProc(hwnd, message, wparam, lparam);
    const auto* rect = reinterpret_cast<RECT*>(lparam);
    ::SetWindowPos(hwnd, nullptr, rect->left, rect->top,
        ::MulDiv(self->pending_width_, dpi, 96),
        ::MulDiv(self->pending_height_, dpi, 96), SWP_NOZORDER | SWP_NOACTIVATE);
    self->ApplyCorners(hwnd, dpi);
    return 0;
  }
  if (message == WM_WINDOWPOSCHANGED || message == WM_SHOWWINDOW) {
    const LRESULT result = ::DefSubclassProc(hwnd, message, wparam, lparam);
    self->UpdateCapsuleSurface(hwnd);
    return result;
  }
  if (message == WM_NCDESTROY) {
    if (self->capsule_surface_) ::DestroyWindow(self->capsule_surface_);
    self->capsule_surface_ = nullptr;
    self->mini_hwnd_ = nullptr;
    ::RemoveWindowSubclass(hwnd, MiniSubclassProc, id);
  }
  return ::DefSubclassProc(hwnd, message, wparam, lparam);
}

HWND MiniWindowNative::FindMiniHwnd() {
  struct EnumCtx {
    DWORD pid;
    HWND main;
    HWND result;
  };
  EnumCtx ctx{::GetCurrentProcessId(), main_hwnd_, nullptr};
  ::EnumWindows(
      [](HWND hwnd, LPARAM lp) -> BOOL {
        auto& c = *reinterpret_cast<EnumCtx*>(lp);
        if (hwnd == c.main) return TRUE;
        wchar_t name[64]{};
        ::GetClassNameW(hwnd, name, 64);
        if (::wcscmp(name, L"FlutterMultiWindow") != 0) return TRUE;
        DWORD wpid = 0;
        ::GetWindowThreadProcessId(hwnd, &wpid);
        if (wpid != c.pid) return TRUE;
        // Skip owned windows (tooltips, menus, dialogs); we want only
        // top-level application windows.
        if (::GetWindow(hwnd, GW_OWNER) != nullptr) return TRUE;
        c.result = hwnd;
        return FALSE;
      },
      reinterpret_cast<LPARAM>(&ctx));
  return ctx.result;
}
