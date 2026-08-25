import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DeviceLockConfig {
  final bool enableDeviceLock;
  final List<String> allowedMachineIds;

  DeviceLockConfig({
    required this.enableDeviceLock,
    required this.allowedMachineIds,
  });

  factory DeviceLockConfig.fromJson(Map<String, dynamic> json) {
    return DeviceLockConfig(
      enableDeviceLock: json['enableDeviceLock'] as bool? ?? false,
      allowedMachineIds:
          (json['allowedMachineIds'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          ['*'],
    );
  }

  Map<String, dynamic> toJson() => {
    'enableDeviceLock': enableDeviceLock,
    'allowedMachineIds': allowedMachineIds,
  };

  DeviceLockConfig copyWith({
    bool? enableDeviceLock,
    List<String>? allowedMachineIds,
  }) {
    return DeviceLockConfig(
      enableDeviceLock: enableDeviceLock ?? this.enableDeviceLock,
      allowedMachineIds: allowedMachineIds ?? this.allowedMachineIds,
    );
  }
}

class DeviceLockService {
  static DeviceLockConfig _config = DeviceLockConfig(
    enableDeviceLock: false,
    allowedMachineIds: ['*'],
  );

  static String _cachedMachineId = '';
  static String? testConfigPath;

  static Future<void> initialize({String? customMachineId}) async {
    if (customMachineId != null) {
      _cachedMachineId = customMachineId;
    } else {
      _cachedMachineId = await fetchMachineGuid();
    }
    await loadConfig();
  }

  static String get currentMachineGuid => _cachedMachineId;

  static Future<File> _getConfigFile() async {
    if (testConfigPath != null) {
      return File(testConfigPath!);
    }

    if (kIsWeb) {
      return File('device_lock.json');
    }

    if (Platform.isWindows) {
      final appData = Platform.environment['PROGRAMDATA'] ?? 'C:\\ProgramData';
      final dir = Directory(
        p.join(appData, 'GroupInvestmentManagement', 'config'),
      );
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return File(p.join(dir.path, 'device_lock.json'));
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      final dir = Directory(p.join(appSupportDir.path, 'config'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return File(p.join(dir.path, 'device_lock.json'));
    }
  }

  static Future<DeviceLockConfig> loadConfig() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final jsonMap = jsonDecode(content) as Map<String, dynamic>;
          _config = DeviceLockConfig.fromJson(jsonMap);
          return _config;
        }
      }
    } catch (e) {
      debugPrint('DeviceLockService.loadConfig error: $e');
    }

    // Default configuration if missing or error
    _config = DeviceLockConfig(
      enableDeviceLock: false,
      allowedMachineIds: ['*'],
    );
    return _config;
  }

  static Future<void> saveConfig(DeviceLockConfig newConfig) async {
    _config = newConfig;
    try {
      final file = await _getConfigFile();
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(newConfig.toJson()));
    } catch (e) {
      debugPrint('DeviceLockService.saveConfig error: $e');
    }
  }

  static Future<String> fetchMachineGuid() async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          "(Get-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Cryptography').MachineGuid",
        ]);
        if (result.exitCode == 0 &&
            result.stdout.toString().trim().isNotEmpty) {
          return result.stdout.toString().trim();
        }
      }
    } catch (_) {}
    return 'DEV-MACHINE-${kIsWeb ? "WEB" : Platform.operatingSystem.toUpperCase()}-001';
  }

  static bool isAuthorized() {
    if (!_config.enableDeviceLock) return true;
    if (_config.allowedMachineIds.contains('*')) return true;
    if (_config.allowedMachineIds.contains(_cachedMachineId)) return true;
    return false;
  }

  static void updateConfig(DeviceLockConfig newConfig) {
    _config = newConfig;
    saveConfig(newConfig);
  }

  static DeviceLockConfig get config => _config;

  static void resetForTest() {
    _config = DeviceLockConfig(
      enableDeviceLock: false,
      allowedMachineIds: ['*'],
    );
    _cachedMachineId = '';
    testConfigPath = null;
  }
}
