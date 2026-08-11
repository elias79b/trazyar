import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/settings/controllers/settings_controller.dart';

import '../../application/settings_provider.dart';

class SecuritySettingsCard extends ConsumerStatefulWidget {
  const SecuritySettingsCard({super.key});

  @override
  ConsumerState<SecuritySettingsCard> createState() =>
      _SecuritySettingsCardState();
}

class _SecuritySettingsCardState
    extends ConsumerState<SecuritySettingsCard> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    await ref
        .read(settingsControllerProvider.notifier)
        .changePassword(
      context: context,
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(settingsControllerProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'امنیت حساب',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'برای تغییر رمز عبور حساب مالک، رمز جدید را وارد کنید.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _passwordController,
                obscureText: obscurePassword,
                enabled: !loading,
                decoration: InputDecoration(
                  labelText: 'رمز عبور جدید',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'رمز عبور جدید را وارد کنید';
                  }

                  if (value.length < 6) {
                    return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: obscureConfirmPassword,
                enabled: !loading,
                decoration: InputDecoration(
                  labelText: 'تکرار رمز عبور جدید',
                  prefixIcon: const Icon(Icons.lock_reset),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword =
                        !obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'تکرار رمز عبور را وارد کنید';
                  }

                  if (value != _passwordController.text) {
                    return 'رمزهای عبور یکسان نیستند';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'رمز عبور مناسب حداقل ۶ کاراکتر داشته باشد.',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed:
                  loading ? null : _changePassword,
                  icon: loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.password),
                  label: Text(
                    loading
                        ? 'در حال تغییر رمز...'
                        : 'تغییر رمز عبور',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}