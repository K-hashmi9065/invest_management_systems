import 'dart:io';

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
      allowedMachineIds: (json['allowedMachineIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['*'],
    );
  }

  Map<String, dynamic> toJson() => {
        'enableDeviceLock': enableDeviceLock,
        'allowedMachineIds': allowedMachineIds,
      };
}

class DeviceLockService {
  static DeviceLockConfig _config = DeviceLockConfig(
    enableDeviceLock: false,
    allowedMachineIds: ['*'],
  );

  static String _cachedMachineId = '';

  static Future<void> initialize() async {
    _cachedMachineId = await fetchMachineGuid();
  }

  static String get currentMachineGuid => _cachedMachineId;

  static Future<String> fetchMachineGuid() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-Command',
          "(Get-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Cryptography').MachineGuid",
        ]);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          return result.stdout.toString().trim();
        }
      }
    } catch (_) {}
    return 'DEV-MACHINE-${Platform.operatingSystem.toUpperCase()}-001';
  }

  static bool isAuthorized() {
    if (!_config.enableDeviceLock) return true;
    if (_config.allowedMachineIds.contains('*')) return true;
    if (_config.allowedMachineIds.contains(_cachedMachineId)) return true;
    return false;
  }

  static void updateConfig(DeviceLockConfig newConfig) {
    _config = newConfig;
  }

  static DeviceLockConfig get config => _config;
}
