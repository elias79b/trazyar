import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tarazyar/owner/settings/controllers/settings_controller.dart';

import '../../application/settings_provider.dart';
import '../../data/settings_repository.dart';

class CompanySettingsCard extends ConsumerStatefulWidget {
  const CompanySettingsCard({super.key});

  @override
  ConsumerState<CompanySettingsCard> createState() =>
      _CompanySettingsCardState();
}

class _CompanySettingsCardState
    extends ConsumerState<CompanySettingsCard> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();

  bool loaded = false;
  bool uploadingLogo = false;
  String? logoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadData(Map<String, dynamic> data) {
    if (loaded) return;

    _nameController.text = data['name']?.toString() ?? '';
    _phoneController.text = data['phone']?.toString() ?? '';
    _emailController.text = data['email']?.toString() ?? '';
    _websiteController.text = data['website']?.toString() ?? '';
    _addressController.text = data['address']?.toString() ?? '';

    logoUrl = data['logo']?.toString();

    loaded = true;
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      setState(() {
        uploadingLogo = true;
      });

      final url = await ref
          .read(settingsRepositoryProvider)
          .uploadCompanyLogo(image);

      if (!mounted) return;

      setState(() {
        logoUrl = url;
        uploadingLogo = false;
      });

      ref.invalidate(companyInfoProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لوگوی شرکت با موفقیت ذخیره شد'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        uploadingLogo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در آپلود لوگو: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveCompany() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref.read(settingsControllerProvider.notifier).updateCompany(
      context: context,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      address: _addressController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(companyInfoProvider);
    final loading = ref.watch(settingsControllerProvider);

    return company.when(
      loading: () => const Card(
        child: SizedBox(
          height: 560,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, _) => Card(
        child: SizedBox(
          height: 560,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'خطا در دریافت اطلاعات شرکت\n\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      data: (data) {
        _loadData(data);

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
                    'اطلاعات شرکت',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.25),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: logoUrl != null &&
                                logoUrl!.isNotEmpty
                                ? Image.network(
                              logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) {
                                return const Icon(
                                  Icons.business,
                                  size: 55,
                                );
                              },
                            )
                                : const Icon(
                              Icons.business,
                              size: 55,
                            ),
                          ),
                        ),

                        FloatingActionButton.small(
                          heroTag:
                          'company_logo_upload_button',
                          onPressed:
                          uploadingLogo
                              ? null
                              : _pickAndUploadLogo,
                          child: uploadingLogo
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(
                            Icons.camera_alt,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'برای تغییر لوگو روی آیکون دوربین کلیک کنید',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ),

                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'نام شرکت',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'نام شرکت را وارد کنید';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'شماره تماس',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                    TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'ایمیل شرکت',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'وب سایت',
                      prefixIcon: Icon(Icons.language),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'آدرس شرکت',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed:
                      loading ? null : _saveCompany,
                      icon: loading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.save),
                      label: Text(
                        loading
                            ? 'در حال ذخیره...'
                            : 'ذخیره اطلاعات شرکت',
                      ),
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