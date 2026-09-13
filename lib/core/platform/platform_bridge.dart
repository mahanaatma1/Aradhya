import 'dart:io';

import 'package:flutter/services.dart';

/// Tiny native bridge (see `MainActivity.kt`). Every call is offline and every
/// failure degrades to a null/false so callers can fall back.
class PlatformBridge {
  PlatformBridge._();

  static const _ch = MethodChannel('aradhya/platform');

  static Future<DeviceInfo?> deviceInfo() async {
    if (!Platform.isAndroid) return null;
    try {
      final m = await _ch.invokeMapMethod<String, Object?>('deviceInfo');
      if (m == null) return null;
      return DeviceInfo(
        isLowRamDevice: m['isLowRamDevice'] == true,
        totalMemBytes: (m['totalMemBytes'] as num?)?.toInt() ?? 0,
        sdkInt: (m['sdkInt'] as num?)?.toInt() ?? 0,
        cores: (m['cores'] as num?)?.toInt() ?? Platform.numberOfProcessors,
      );
    } catch (_) {
      return null;
    }
  }

  /// Free bytes on the volume holding [path], or null when unknown.
  static Future<int?> freeDiskBytes(String path) async {
    if (!Platform.isAndroid) return null;
    try {
      final v = await _ch.invokeMethod<int>('freeDiskBytes', {'path': path});
      return v == null || v < 0 ? null : v;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> installTtsData() => _bool('installTtsData');
  static Future<bool> openTtsSettings() => _bool('openTtsSettings');

  static Future<bool> _bool(String method) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _ch.invokeMethod<bool>(method) ?? false;
    } catch (_) {
      return false;
    }
  }
}

class DeviceInfo {
  final bool isLowRamDevice;
  final int totalMemBytes;
  final int sdkInt;
  final int cores;
  const DeviceInfo({
    required this.isLowRamDevice,
    required this.totalMemBytes,
    required this.sdkInt,
    required this.cores,
  });

  double get totalGb => totalMemBytes / (1024 * 1024 * 1024);
}
