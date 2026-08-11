import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/settings/controllers/settings_controller.dart';

import '../../application/settings_provider.dart';

class ProfileSettingsCard extends ConsumerStatefulWidget {
  const ProfileSettingsCard({super.key});

  @override
  ConsumerState<ProfileSettingsCard> createState() =>
      _ProfileSettingsCardState();
}

class _ProfileSettingsCardState
    extends ConsumerState<ProfileSettingsCard> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final profile = ref.watch(ownerProfileProvider);
    final loading = ref.watch(settingsControllerProvider);

    return profile.when(

      loading: () => const Card(
        child: SizedBox(
          height: 420,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),

      error: (e, _) => Card(
        child: SizedBox(
          height: 420,
          child: Center(
            child: Text(e.toString()),
          ),
        ),
      ),

      data: (data) {

        if (!loaded) {
          _nameController.text = data["full_name"] ?? "";
          _emailController.text = data["email"] ?? "";
          _phoneController.text = data["phone"] ?? "";
          loaded = true;
        }

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
                    "پروفایل مالک",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "نام و نام خانوادگی",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "ایمیل",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: "شماره تماس",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(

                      onPressed: loading
                          ? null
                          : () {

                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        ref
                            .read(settingsControllerProvider.notifier)
                            .updateProfile(

                          context: context,

                          fullName: _nameController.text.trim(),

                          email: _emailController.text.trim(),

                          phone: _phoneController.text.trim(),

                        );

                      },

                      child: loading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text("ذخیره اطلاعات"),

                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }
}