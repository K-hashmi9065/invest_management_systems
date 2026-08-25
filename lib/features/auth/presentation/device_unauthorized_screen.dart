import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/device_lock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

final machineGuidProvider = StateProvider<String>(
  (ref) => DeviceLockService.currentMachineGuid,
);

class DeviceUnauthorizedScreen extends ConsumerWidget {
  const DeviceUnauthorizedScreen({super.key});

  void _copyToClipboard(BuildContext context, String machineGuid) {
    Clipboard.setData(ClipboardData(text: machineGuid));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Machine ID copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machineGuid = ref.watch(machineGuidProvider);

    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: AppCard(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppColors.danger,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Device Not Authorized',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This computer is not authorized to run Group Investment Management.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Machine ID Display Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Machine ID',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        machineGuid,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Copy ID',
                        icon: Icons.copy,
                        isSecondary: true,
                        onPressed: () => _copyToClipboard(context, machineGuid),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Retry',
                        icon: Icons.refresh,
                        onPressed: () {
                          ref.read(machineGuidProvider.notifier).state =
                              DeviceLockService.currentMachineGuid;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
