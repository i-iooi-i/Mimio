cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "audio_recorder.cpp"
  "autostart.cpp"
  "flutter_window.cpp"
  "main.cpp"
  "mini_window_native.cpp"
  "tray_icon.cpp"
  "utils.cpp"
  "video_capture.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib" "comctl32.lib")
# Audio recorder: WASAPI (Mmdevapi/AvRt) + Media Foundation Sink Writer
# + Psapi for process enumeration (per-process loopback target lookup).
target_link_libraries(${BINARY_NAME} PRIVATE
  "Mmdevapi.lib"
  "Avrt.lib"
  "Mfplat.lib"
  "Mfreadwrite.lib"
  "Mfuuid.lib"
  "Mf.lib"
  "Ole32.lib"
  "Psapi.lib"
  "Kernel32.lib"
)
# Video capture: Windows.Graphics.Capture (WinRT ABI via runtimeobject)
# + D3D11 for frame scaling/NV12 conversion.
target_link_libraries(${BINARY_NAME} PRIVATE
  "d3d11.lib"
  "dxgi.lib"
  "runtimeobject.lib"
)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
