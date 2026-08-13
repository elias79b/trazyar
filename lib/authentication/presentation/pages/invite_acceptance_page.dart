import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteAcceptancePage extends StatefulWidget {
  const InviteAcceptancePage({
    super.key,
  });

  @override
  State<InviteAcceptancePage> createState() =>
      _InviteAcceptancePageState();
}

class _InviteAcceptancePageState
    extends State<InviteAcceptancePage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _acceptTerms = false;
  bool _loading = true;

  String? _errorMessage;

  User? _user;

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
      // 1. بررسی Session فعلی
      // ----------------------------------------------------------

      final currentSession =
          _supabase.auth.currentSession;

      debugPrint(
        'CURRENT SESSION EXISTS: ${currentSession != null}',
      );

      if (currentSession != null) {
        debugPrint(
          'CURRENT USER: ${currentSession.user.email}',
        );

        if (mounted) {
          setState(() {
            _user = currentSession.user;
            _loading = false;
          });
        }

        return;
      }

      // ----------------------------------------------------------
      // 2. اگر Session هنوز ایجاد نشده،
      //    منتظر Auth State Change می‌مانیم.
      // ----------------------------------------------------------

      _authSubscription =
          _supabase.auth.onAuthStateChange.listen(
                (authState) {
              debugPrint(
                'INVITE AUTH EVENT: ${authState.event}',
              );

              final session =
                  authState.session;

              if (session == null) {
                return;
              }

              debugPrint(
                'INVITE SESSION RECEIVED',
              );

              debugPrint(
                'INVITE USER ID: ${session.user.id}',
              );

              debugPrint(
                'INVITE USER EMAIL: ${session.user.email}',
              );

              if (!mounted) {
                return;
              }

              setState(() {
                _user = session.user;
                _loading = false;
                _errorMessage = null;
              });

              _authSubscription?.cancel();
            },
          );

      // ----------------------------------------------------------
      // 3. یک فرصت کوتاه برای Supabase می‌دهیم
      //    تا Session لینک دعوت را پردازش کند.
      // ----------------------------------------------------------

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      final sessionAfterWait =
          _supabase.auth.currentSession;

      debugPrint(
        'SESSION AFTER WAIT: ${sessionAfterWait != null}',
      );

      if (sessionAfterWait != null) {
        setState(() {
          _user = sessionAfterWait.user;
          _loading = false;
        });

        await _authSubscription?.cancel();
        _authSubscription = null;

        return;
      }

      // ----------------------------------------------------------
      // 4. اگر هنوز Session نداریم
      // ----------------------------------------------------------

      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage =
          'دعوت‌نامه معتبر نیست یا Session آن هنوز ایجاد نشده است.';
        });
      }
    } catch (error) {
      debugPrint(
        'INVITATION INITIALIZATION ERROR: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage =
            error.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // FULL NAME
  // ============================================================

  String get _fullName {
    final metadata =
        _user?.userMetadata;

    final name =
    metadata?['full_name']
        ?.toString()
        .trim();

    if (name != null &&
        name.isNotEmpty) {
      return name;
    }

    return 'مشاور ترازیار';
  }

  // ============================================================
  // EMAIL
  // ============================================================

  String get _email {
    return _user?.email ?? '';
  }

  // ============================================================
  // ACTIVATE ACCOUNT
  // ============================================================

  Future<void> _activateAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    // ----------------------------------------------------------
    // بررسی Session
    // ----------------------------------------------------------

    final session =
        _supabase.auth.currentSession;

    final user =
        _supabase.auth.currentUser;

    debugPrint(
      'ACTIVATE SESSION EXISTS: ${session != null}',
    );

    debugPrint(
      'ACTIVATE USER: ${user?.email}',
    );

    if (session == null ||
        user == null) {
      setState(() {
        _errorMessage =
        'دعوت‌نامه معتبر نیست یا منقضی شده است.';
      });

      return;
    }

    // ----------------------------------------------------------
    // Password
    // ----------------------------------------------------------

    final password =
        _passwordController.text;

    final confirmPassword =
        _confirmPasswordController.text;

    if (password.isEmpty) {
      setState(() {
        _errorMessage =
        'رمز عبور را وارد کنید.';
      });

      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage =
        'رمز عبور باید حداقل ۸ کاراکتر باشد.';
      });

      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _errorMessage =
        'تکرار رمز عبور را وارد کنید.';
      });

      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage =
        'رمز عبور و تکرار آن یکسان نیستند.';
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
      // 1. تنظیم Password
      // ========================================================

      debugPrint(
        'UPDATING INVITED USER PASSWORD',
      );

      await _supabase.auth.updateUser(
        UserAttributes(
          password: password,
        ),
      );

      // ========================================================
      // 2. گرفتن Session جدید
      // ========================================================

      final updatedSession =
          _supabase.auth.currentSession;

      final updatedUser =
          _supabase.auth.currentUser;

      if (updatedSession == null ||
          updatedUser == null) {
        throw Exception(
          'Session کاربر پس از تعیین رمز پیدا نشد.',
        );
      }

      debugPrint(
        'PASSWORD UPDATED SUCCESSFULLY',
      );

      // ========================================================
      // 3. فعال‌سازی public.users
      // ========================================================

      debugPrint(
        'CALLING ACTIVATE_INVITED_CONSULTANT',
      );

      final response =
      await _supabase.functions.invoke(
        'smooth-action',
        body: {
          'action':
          'activate_invited_consultant',
        },
      );

      debugPrint(
        'ACTIVATE FUNCTION STATUS: ${response.status}',
      );

      debugPrint(
        'ACTIVATE FUNCTION DATA: ${response.data}',
      );

      if (response.status < 200 ||
          response.status >= 300) {
        throw Exception(
          'فعال‌سازی حساب انجام نشد.',
        );
      }

      final data =
          response.data;

      if (data is Map &&
          data['success'] != true) {
        throw Exception(
          data['error']?.toString() ??
              'فعال‌سازی حساب انجام نشد.',
        );
      }

      // ========================================================
      // 4. موفقیت
      // ========================================================

      if (!mounted) {
        return;
      }

      await _showSuccessDialog();

      if (!mounted) {
        return;
      }

      // ========================================================
      // 5. رفتن به Consultant
      // ========================================================

      context.go('/consultant');
    } on AuthException catch (error) {
      debugPrint(
        'AUTH ERROR: ${error.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            error.message;
      });
    } catch (error) {
      debugPrint(
        'ACTIVATE ERROR: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            error.toString().replaceFirst(
              'Exception: ',
              '',
            );
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
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 56,
          ),
          title: const Text(
            'حساب با موفقیت فعال شد',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'حساب مشاور شما فعال شد. اکنون می‌توانید وارد ترازیار شوید.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'ادامه',
                ),
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
    final theme =
    Theme.of(context);

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Center(
            child:
            SingleChildScrollView(
              padding:
              const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 520,
                ),
                child:
                _buildCard(
                  context,
                  theme,
                ),
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

  Widget _buildCard(
      BuildContext context,
      ThemeData theme,
      ) {
    return Card(
      elevation: 3,
      shadowColor:
      Colors.black.withOpacity(.08),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(24),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            _buildLogo(),

            const SizedBox(height: 22),

            const Text(
              'تکمیل و فعال‌سازی حساب',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'خوش آمدید، اطلاعات ورود خود را تعیین کنید.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 26),

            if (_loading)
              const Padding(
                padding:
                EdgeInsets.symmetric(
                  vertical: 30,
                ),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'در حال بررسی دعوت‌نامه...',
                    ),
                  ],
                ),
              )
            else ...[
              _buildUserInfo(),

              const SizedBox(height: 24),

              if (_errorMessage != null)
                _buildError(),

              if (_errorMessage != null)
                const SizedBox(height: 16),

              _buildLabel('رمز عبور'),

              const SizedBox(height: 8),

              TextField(
                controller:
                _passwordController,
                obscureText:
                _obscurePassword,
                textDirection:
                TextDirection.ltr,
                decoration:
                InputDecoration(
                  hintText:
                  'رمز عبور خود را وارد کنید',
                  prefixIcon:
                  const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon:
                  IconButton(
                    onPressed: _loading
                        ? null
                        : () {
                      setState(() {
                        _obscurePassword =
                        !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons
                          .visibility_outlined
                          : Icons
                          .visibility_off_outlined,
                    ),
                  ),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'رمز عبور باید حداقل ۸ کاراکتر باشد.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              _buildLabel(
                'تکرار رمز عبور',
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                _confirmPasswordController,
                obscureText:
                _obscureConfirmPassword,
                textDirection:
                TextDirection.ltr,
                decoration:
                InputDecoration(
                  hintText:
                  'رمز عبور را دوباره وارد کنید',
                  prefixIcon:
                  const Icon(
                    Icons
                        .lock_reset_outlined,
                  ),
                  suffixIcon:
                  IconButton(
                    onPressed: _loading
                        ? null
                        : () {
                      setState(() {
                        _obscureConfirmPassword =
                        !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons
                          .visibility_outlined
                          : Icons
                          .visibility_off_outlined,
                    ),
                  ),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              CheckboxListTile(
                value:
                _acceptTerms,
                onChanged:
                _loading
                    ? null
                    : (value) {
                  setState(() {
                    _acceptTerms =
                        value ?? false;
                  });
                },
                contentPadding:
                EdgeInsets.zero,
                controlAffinity:
                ListTileControlAffinity
                    .leading,
                title: const Text(
                  'قوانین و شرایط استفاده را می‌پذیرم',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed:
                  _loading
                      ? null
                      : _activateAccount,
                  style:
                  FilledButton.styleFrom(
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Text(
                    'فعال‌سازی حساب',
                    style:
                    TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.bold,
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
        decoration:
        BoxDecoration(
          borderRadius:
          BorderRadius.circular(20),
          color: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(.10),
        ),
        child: Icon(
          Icons.business_center_outlined,
          size: 38,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
      ),
    );
  }

  // ============================================================
  // USER INFO
  // ============================================================

  Widget _buildUserInfo() {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(16),
        color: Colors.grey.shade50,
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(
                  _fullName.isNotEmpty
                      ? _fullName[0]
                      : 'م',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      _fullName,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'مشاور ترازیار',
                      style:
                      TextStyle(
                        fontSize: 12,
                        color:
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration:
            BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 19,
                  color: Colors.grey,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    _email.isEmpty
                        ? 'ایمیل دعوت‌نامه'
                        : _email,
                    textDirection:
                    TextDirection.ltr,
                    textAlign:
                    TextAlign.right,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),

                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Colors.grey,
                ),
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

  Widget _buildLabel(
      String text,
      ) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight:
        FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color:
        Colors.red.shade50,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color:
          Colors.red.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color:
            Colors.red.shade700,
            size: 20,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color:
                Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}