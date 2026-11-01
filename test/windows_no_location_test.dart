import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows permission plugin cannot activate geolocation at engine registration', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('path: packages/permission_handler_windows'));
    final native = File('packages/permission_handler_windows/windows/permission_handler_windows_plugin.cpp').readAsStringSync();
    expect(native, isNot(contains('Windows.Devices.Geolocation.h')));
    expect(native, isNot(contains('PositionChanged(')));
    expect(native, isNot(contains('GetGeoposition')));
    expect(native, isNot(contains('::Geolocator')));
    expect(native, contains('PermissionHandlerWindowsPlugin() = default;'));
    expect(native, contains('checkPermissionStatus'));
    expect(native, contains('requestPermissions'));
    expect(native, contains('ServiceStatus::NOT_APPLICABLE'));
  });
}
