import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteAcceptancePage extends StatefulWidget {
  const InviteAcceptancePage({super.key});

  @override
  State<InviteAcceptancePage> createState() => _InviteAcceptancePageState();
}

class _InviteAcceptancePageState extends State<InviteAcceptancePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _acceptTerms = false;
  bool _loading = true;

  String? _errorMessage;

  User? _user;

  String? _role;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _initializeInvitation();
  }

  // ============================================================
  // INITIALIZE INVITATION
  // ============================================================

  Future<void> _initializeInvitation() async {
    try {
      debugPrint('========================================');
      debugPrint('INVITATION INITIALIZATION');
      debugPrint('CURRENT URL: ${Uri.base}');
      debugPrint('CURRENT PATH: ${Uri.base.path}');
      debugPrint('CURRENT FRAGMENT: ${Uri.base.fragment}');
      debugPrint('========================================');

      // ----------------------------------------------------------
      // 1. Session فعلی
      // ----------------------------------------------------------

      final currentSession = _supabase.auth.currentSession;

      debugPrint('CURRENT SESSION EXISTS: ${currentSession != null}');

      if (currentSession != null) {
        debugPrint('CURRENT USER: ${currentSession.user.email}');

        await _loadInvitedUser(currentSession.user);

        return;
      }

      // ----------------------------------------------------------
      // 2. منتظر Auth State Change
      // ----------------------------------------------------------

      _authSubscription = _supabase.auth.onAuthStateChange.listen((authState) {
        debugPrint('INVITE AUTH EVENT: ${authState.event}');

        final session = authState.session;

        if (session == null) {
          return;
        }

        debugPrint('INVITE SESSION RECEIVED');

        debugPrint('INVITE USER ID: ${session.user.id}');

        debugPrint('INVITE USER EMAIL: ${session.user.email}');

        _loadInvitedUser(session.user);

        _authSubscription?.cancel();
        _authSubscription = null;
      });

      // ----------------------------------------------------------
      // 3. فرصت کوتاه برای پردازش لینک دعوت
      // ----------------------------------------------------------

      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        return;
      }

      final sessionAfterWait = _supabase.auth.currentSession;

      debugPrint('SESSION AFTER WAIT: ${sessionAfterWait != null}');

      if (sessionAfterWait != null) {
        await _loadInvitedUser(sessionAfterWait.user);

        await _authSubscription?.cancel();
        _authSubscription = null;

        return;
      }

      // ----------------------------------------------------------
      // 4. Session پیدا نشد
      // ----------------------------------------------------------

      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage =
              'دعوت‌نامه معتبر نیست یا Session آن هنوز ایجاد نشده است.';
        });
      }
    } catch (error) {
      debugPrint('INVITATION INITIALIZATION ERROR: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // LOAD INVITED USER
  // ============================================================

  Future<void> _loadInvitedUser(User user) async {
    try {
      debugPrint('LOADING INVITED USER: ${user.id}');

      // ============================================================
      // Accountant
      //
      // نقش حسابدار هنگام ارسال دعوت‌نامه داخل Auth metadata
      // ذخیره شده است. بنابراین برای Accountant نیازی نیست
      // قبل از آماده شدن Session از public.users بخوانیم.
      // ============================================================

      final metadataRole =
      user.userMetadata?['role']?.toString().trim().toLowerCase();

      if (metadataRole == 'accountant') {
        debugPrint('INVITED USER ROLE FROM METADATA: accountant');

        if (!mounted) {
          return;
        }

        setState(() {
          _user = user;
          _role = 'accountant';
          _loading = false;
          _errorMessage = null;
        });

        return;
      }

      // ============================================================
      // Consultant
      //
      // این قسمت عمداً همان منطق قبلی است تا Flow مشاور
      // هیچ تغییری نکند.
      // ============================================================

      final response =
      await _supabase
          .from('users')
          .select('id, full_name, email, role, is_active')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        throw Exception('پروفایل کاربر دعوت‌شده در سیستم پیدا نشد.');
      }

      final role = response['role']?.toString().trim().toLowerCase();

      if (role != 'consultant') {
        throw Exception('نقش این دعوت‌نامه معتبر نیست.');
      }

      debugPrint('INVITED USER ROLE: $role');

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _role = role;
        _loading = false;
        _errorMessage = null;
      });
    } catch (error) {
      debugPrint('LOAD INVITED USER ERROR: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // ROLE
  // ============================================================

  bool get _isAccountant => _role == 'accountant';

  bool get _isConsultant => _role == 'consultant';

  String get _roleTitle {
    if (_isAccountant) {
      return 'حسابدار ترازیار';
    }

    return 'مشاور ترازیار';
  }

  String get _roleDescription {
    if (_isAccountant) {
      return 'اطلاعات ورود حسابدار خود را تعیین کنید.';
    }

    return 'اطلاعات ورود مشاور خود را تعیین کنید.';
  }

  // ============================================================
  // FULL NAME
  // ============================================================

  String get _fullName {
    final metadata = _user?.userMetadata;

    final name = metadata?['full_name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return _isAccountant ? 'حسابدار ترازیار' : 'مشاور ترازیار';
  }

  // ============================================================
  // EMAIL
  // ============================================================

  String get _email {
    return _user?.email ?? '';
  }

  // ============================================================
  // ACTIVATION
  // ============================================================

  Future<void> _activateAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    // ----------------------------------------------------------
    // Session
    // ----------------------------------------------------------

    final session = _supabase.auth.currentSession;

    final user = _supabase.auth.currentUser;

    debugPrint('ACTIVATE SESSION EXISTS: ${session != null}');

    debugPrint('ACTIVATE USER: ${user?.email}');

    if (session == null || user == null) {
      setState(() {
        _errorMessage = 'دعوت‌نامه معتبر نیست یا منقضی شده است.';
      });

      return;
    }

    // ----------------------------------------------------------
    // Password
    // ----------------------------------------------------------

    final password = _passwordController.text;

    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'رمز عبور را وارد کنید.';
      });

      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'رمز عبور باید حداقل ۸ کاراکتر باشد.';
      });

      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'تکرار رمز عبور را وارد کنید.';
      });

      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'رمز عبور و تکرار آن یکسان نیستند.';
      });

      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage =
            'برای فعال‌سازی حساب باید قوانین و شرایط استفاده را بپذیرید.';
      });

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // ========================================================
      // 1. تعیین Password
      // ========================================================

      debugPrint('UPDATING INVITED USER PASSWORD');

      await _supabase.auth.updateUser(UserAttributes(password: password));

      // ========================================================
      // 2. Session جدید
      // ========================================================

      final updatedSession = _supabase.auth.currentSession;

      final updatedUser = _supabase.auth.currentUser;

      if (updatedSession == null || updatedUser == null) {
        throw Exception('Session کاربر پس از تعیین رمز پیدا نشد.');
      }

      debugPrint('PASSWORD UPDATED SUCCESSFULLY');

      // ========================================================
      // 3. اگر role هنوز مشخص نیست دوباره دریافت شود
      // ========================================================

      var role = _role;

      if (role == null) {
        final response =
            await _supabase
                .from('users')
                .select('role')
                .eq('id', updatedUser.id)
                .maybeSingle();

        role = response?['role']?.toString().trim();

        _role = role;
      }

      if (role != 'consultant' && role != 'accountant') {
        throw Exception('نقش کاربر برای فعال‌سازی معتبر نیست.');
      }

      // ========================================================
      // 4. انتخاب Action
      // ========================================================

      final activationAction =
          role == 'accountant'
              ? 'activate_invited_accountant'
              : 'activate_invited_consultant';

      debugPrint('ACTIVATION ACTION: $activationAction');

      // ========================================================
      // 5. فعال‌سازی public.users
      // ========================================================

      final response = await _supabase.functions.invoke(
        'smooth-action',
        body: {'action': activationAction},
      );

      debugPrint('ACTIVATE FUNCTION STATUS: ${response.status}');

      debugPrint('ACTIVATE FUNCTION DATA: ${response.data}');

      if (response.status < 200 || response.status >= 300) {
        throw Exception('فعال‌سازی حساب انجام نشد.');
      }

      final data = response.data;

      if (data is! Map) {
        throw Exception('پاسخ نامعتبر از سرور دریافت شد.');
      }

      if (data['success'] != true) {
        throw Exception(
          data['error']?.toString() ?? 'فعال‌سازی حساب انجام نشد.',
        );
      }

      // ========================================================
      // 6. موفقیت
      // ========================================================

      if (!mounted) {
        return;
      }

      await _showSuccessDialog();

      if (!mounted) {
        return;
      }

      // ========================================================
      // 7. مقصد بر اساس نقش
      // ========================================================

      if (role == 'accountant') {
        context.go('/accountant');
      } else {
        context.go('/consultant');
      }
    } on AuthException catch (error) {
      debugPrint('AUTH ERROR: ${error.message}');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      debugPrint('ACTIVATE ERROR: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showSuccessDialog() async {
    final isAccountant = _isAccountant;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 56,
          ),
          title: Text(
            isAccountant
                ? 'حساب حسابدار با موفقیت فعال شد'
                : 'حساب با موفقیت فعال شد',
            textAlign: TextAlign.center,
          ),
          content: Text(
            isAccountant
                ? 'حساب حسابدار شما فعال شد. اکنون می‌توانید وارد داشبورد حسابدار ترازیار شوید.'
                : 'حساب مشاور شما فعال شد. اکنون می‌توانید وارد ترازیار شوید.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('ادامه'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _authSubscription?.cancel();

    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _buildCard(context, theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLogo(),

            const SizedBox(height: 22),

            const Text(
              'تکمیل و فعال‌سازی حساب',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              _roleDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),

            const SizedBox(height: 26),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('در حال بررسی دعوت‌نامه...'),
                  ],
                ),
              )
            else ...[
              _buildUserInfo(),

              const SizedBox(height: 24),

              if (_errorMessage != null) _buildError(),

              if (_errorMessage != null) const SizedBox(height: 16),

              _buildLabel('رمز عبور'),

              const SizedBox(height: 8),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'رمز عبور خود را وارد کنید',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed:
                        _loading
                            ? null
                            : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'رمز عبور باید حداقل ۸ کاراکتر باشد.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 20),

              _buildLabel('تکرار رمز عبور'),

              const SizedBox(height: 8),

              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'رمز عبور را دوباره وارد کنید',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    onPressed:
                        _loading
                            ? null
                            : () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              CheckboxListTile(
                value: _acceptTerms,
                onChanged:
                    _loading
                        ? null
                        : (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'قوانین و شرایط استفاده را می‌پذیرم',
                  style: TextStyle(fontSize: 13),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _activateAccount,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            _isAccountant
                                ? 'فعال‌سازی حساب حسابدار'
                                : 'فعال‌سازی حساب',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.primary.withOpacity(.10),
        ),
        child: Icon(
          _isAccountant
              ? Icons.account_balance_wallet_outlined
              : Icons.business_center_outlined,
          size: 38,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // ============================================================
  // USER INFO
  // ============================================================

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(
                  _fullName.isNotEmpty ? _fullName[0] : 'م',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _roleTitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, size: 19, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _email.isEmpty ? 'ایمیل دعوت‌نامه' : _email,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
