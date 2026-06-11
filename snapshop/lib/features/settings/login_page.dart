import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import 'settings_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _smsCodeController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _loading = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _smsMode = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _smsCodeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_isLogin ? l10n.loginFailed : l10n.registerFailed),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.okLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSmsCode() async {
    if (_countdown > 0) return;
    final phone = _phoneController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (phone.length != 11) {
      _showError(l10n.loginPhoneError);
      return;
    }
    final scene = _isLogin ? 'login' : 'register';
    try {
      await ApiClient().post('/auth/send-sms-code', data: {
        'phone': phone,
        'scene': scene,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginSmsSentDebug)),
        );
        setState(() => _countdown = 60);
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            if (_countdown > 0) {
              _countdown--;
            } else {
              timer.cancel();
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('${l10n.loginSendSmsFailed}：$e');
      }
    }
  }

  void _submit() async {
    final l10n = AppLocalizations.of(context);
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 11) {
      _showError(l10n.loginPhoneError);
      return;
    }

    if (!_smsMode) {
      final password = _passwordController.text.trim();
      if (_isLogin) {
        if (password.isEmpty) {
          _showError(l10n.loginPasswordHint);
          return;
        }
      } else {
        if (password.length < 8) {
          _showError(l10n.loginPasswordHint);
          return;
        }
      }
      if (!_isLogin) {
        final passwordConfirm = _passwordConfirmController.text.trim();
        if (passwordConfirm != _passwordController.text.trim()) {
          _showError(l10n.registerPasswordMismatch);
          return;
        }
      }
    } else {
      final code = _smsCodeController.text.trim();
      if (code.length != 6) {
        _showError(l10n.loginSmsCodeError);
        return;
      }
    }

    setState(() => _loading = true);
    String? error;
    if (_smsMode) {
      error = await ref.read(settingsProvider.notifier).smsLogin(phone, _smsCodeController.text.trim());
    } else if (_isLogin) {
      error = await ref.read(settingsProvider.notifier).login(phone, _passwordController.text.trim());
    } else {
      error = await ref.read(settingsProvider.notifier).register(phone, _passwordController.text.trim(), _passwordConfirmController.text.trim());
    }
    setState(() => _loading = false);
    if (error != null && mounted) {
      _showError(error);
      return;
    }
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.colors.secondaryBg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brandBlue.withValues(alpha: 0.08),
                      AppColors.brandPurple.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brandPurple.withValues(alpha: 0.06),
                      AppColors.brandBlue.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _buildHeader(context, l10n),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: AppColors.brandGradient,
                          ).createShader(bounds),
                          child: Text(
                            'SnapShop',
                            style: TextStyle(
                              fontSize: context.fs(36),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.homeSlogan,
                          style: TextStyle(
                            fontSize: context.fs(14),
                            color: context.colors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            color: context.colors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() { _smsMode = false; _isLogin = true; }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_smsMode ? context.colors.surface : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_smsMode
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                          : null,
                                    ),
                                    child: Text(l10n.loginPasswordTab, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _smsMode = true),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _smsMode ? context.colors.surface : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _smsMode
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                          : null,
                                    ),
                                    child: Text(l10n.loginSmsTab, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Phone number input (both modes)
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: l10n.loginPhoneHint,
                            hintStyle: TextStyle(
                              color: context.colors.textTertiary,
                              fontSize: context.fs(15),
                            ),
                            filled: true,
                            fillColor: context.colors.cardBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          style: TextStyle(
                            fontSize: context.fs(15),
                            color: context.colors.textPrimary,
                          ),
                        ),

                        if (_smsMode) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _smsCodeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    hintText: l10n.loginSmsCodeHint,
                                    counterText: '',
                                    hintStyle: TextStyle(
                                      color: context.colors.textTertiary,
                                      fontSize: context.fs(15),
                                    ),
                                    filled: true,
                                    fillColor: context.colors.cardBg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  style: TextStyle(
                                    fontSize: context.fs(15),
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _countdown > 0 || _loading ? null : _sendSmsCode,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: _countdown > 0
                                          ? context.colors.textTertiary.withValues(alpha: 0.3)
                                          : AppColors.brandBlue,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: Text(
                                    _countdown > 0 ? '${_countdown}s' : l10n.loginGetCode,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _countdown > 0 ? context.colors.textTertiary : AppColors.brandBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: l10n.loginPasswordHint,
                              hintStyle: TextStyle(
                                color: context.colors.textTertiary,
                                fontSize: context.fs(15),
                              ),
                              filled: true,
                              fillColor: context.colors.cardBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: context.colors.textTertiary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            style: TextStyle(
                              fontSize: context.fs(15),
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordConfirmController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: l10n.registerPasswordConfirmHint,
                                hintStyle: TextStyle(
                                  color: context.colors.textTertiary,
                                  fontSize: context.fs(15),
                                ),
                                filled: true,
                                fillColor: context.colors.cardBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: context.colors.textTertiary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              style: TextStyle(
                                fontSize: context.fs(15),
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _smsMode
                                        ? l10n.loginSmsButton
                                        : _isLogin ? l10n.loginButton : l10n.registerButton,
                                    style: TextStyle(
                                      fontSize: context.fs(16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        if (!_smsMode) ...[
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => setState(() => _isLogin = !_isLogin),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: context.fs(13)),
                                children: [
                                  TextSpan(
                                    text: _isLogin ? l10n.loginNoAccount : l10n.loginHaveAccount,
                                    style: TextStyle(color: context.colors.textTertiary),
                                  ),
                                  TextSpan(
                                    text: _isLogin ? l10n.loginRegister : l10n.loginBack,
                                    style: const TextStyle(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Icon(Icons.chevron_left, size: 20, color: context.colors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              _isLogin ? l10n.loginTitle : l10n.registerTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(18),
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
