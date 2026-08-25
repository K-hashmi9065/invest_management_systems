import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:invest_management_systems/core/security/device_lock_service.dart';

void main() {
  late Directory tempDir;
  late String configPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gim_device_lock_test_');
    configPath = '${tempDir.path}/device_lock.json';
    DeviceLockService.testConfigPath = configPath;
  });

  tearDown(() async {
    DeviceLockService.resetForTest();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DeviceLockService Persistence & Authorization', () {
    test('default configuration authorizes all machines when lock is disabled', () async {
      await DeviceLockService.initialize(customMachineId: 'TEST-MACHINE-GUID-001');
      expect(DeviceLockService.isAuthorized(), isTrue);
    });

    test('saves configuration to JSON file and reloads correctly', () async {
      await DeviceLockService.initialize(customMachineId: 'TEST-MACHINE-GUID-001');

      final newConfig = DeviceLockConfig(
        enableDeviceLock: true,
        allowedMachineIds: ['TEST-MACHINE-GUID-001', 'OFFICE-DESKTOP-002'],
      );

      await DeviceLockService.saveConfig(newConfig);

      // Verify file exists on disk
      final file = File(configPath);
      expect(file.existsSync(), isTrue);

      // Reset in-memory config and reload from disk
      await DeviceLockService.loadConfig();
      expect(DeviceLockService.config.enableDeviceLock, isTrue);
      expect(DeviceLockService.config.allowedMachineIds, contains('TEST-MACHINE-GUID-001'));
      expect(DeviceLockService.config.allowedMachineIds, contains('OFFICE-DESKTOP-002'));
      expect(DeviceLockService.isAuthorized(), isTrue);
    });

    test('blocks unauthorized machine GUID when device lock is enabled', () async {
      await DeviceLockService.initialize(customMachineId: 'UNKNOWN-ROGUE-MACHINE-999');

      final restrictedConfig = DeviceLockConfig(
        enableDeviceLock: true,
        allowedMachineIds: ['AUTHORIZED-GUID-001'],
      );

      await DeviceLockService.saveConfig(restrictedConfig);
      await DeviceLockService.loadConfig();

      expect(DeviceLockService.isAuthorized(), isFalse);
    });

    test('allows any machine if wildcard * is present in allowed list', () async {
      await DeviceLockService.initialize(customMachineId: 'ANY-RANDOM-MACHINE-123');

      final wildcardConfig = DeviceLockConfig(
        enableDeviceLock: true,
        allowedMachineIds: ['AUTHORIZED-GUID-001', '*'],
      );

      await DeviceLockService.saveConfig(wildcardConfig);
      await DeviceLockService.loadConfig();

      expect(DeviceLockService.isAuthorized(), isTrue);
    });
  });
}
