import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import 'setup_controller.dart';

class FirstTimeSetupScreen extends ConsumerStatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  ConsumerState<FirstTimeSetupScreen> createState() =>
      _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends ConsumerState<FirstTimeSetupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final user = await ref
        .read(setupControllerProvider.notifier)
        .completeSetup(
          fullName: _fullNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (user != null && mounted) {
      context.go(RoutePaths.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupControllerProvider);
    final isLoading = setupState.isLoading;
    final errorMessage = setupState.hasError
        ? setupState.error.toString()
        : null;

    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: AppCard(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: AppColors.accent,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'System Initial Setup',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create the Super Admin master account to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    AppTextField(
                      label: 'Full Name',
                      hint: 'Super Admin Name',
                      controller: _fullNameController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Full name required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email Address',
                      hint: 'admin@example.com (Used for Login)',
                      controller: _emailController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Email required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Mobile Number',
                      hint: '+91 9876543210 (Used for Login)',
                      controller: _phoneController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Mobile number required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hint: 'Create strong password',
                      obscureText: true,
                      controller: _passwordController,
                      validator: (val) => val == null || val.length < 4
                          ? 'Password must be at least 4 chars'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Confirm Password',
                      hint: 'Re-enter password',
                      obscureText: true,
                      controller: _confirmPasswordController,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Confirm password'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    AppButton(
                      text: 'Complete Setup & Launch',
                      height: 50,
                      fontSize: 15,
                      isLoading: isLoading,
                      onPressed: _handleSetup,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
