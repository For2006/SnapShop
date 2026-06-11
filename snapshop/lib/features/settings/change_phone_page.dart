import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../core/network/api_client.dart';
import 'settings_provider.dart';

class ChangePhonePage extends ConsumerStatefulWidget {
  const ChangePhonePage({super.key});

  @override
  ConsumerState<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends ConsumerState<ChangePhonePage> {
  final _passwordController = TextEditingController();
  final _newPhoneController = TextEditingController();
  final _newCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePwd = true;
  int _countdownNew = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLoggedIn = ref.read(settingsProvider).isLoggedIn;
      if (!isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录以使用账户安全功能')),
        );
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _newPhoneController.dispose();
    _newCodeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendNewCode() async {
    if (_countdownNew > 0) return;
    final phone = _newPhoneController.text.trim();
    if (phone.length != 11) {
      _showMessage('请输入11位新手机号', isError: true);
      return;
    }
    try {
      await ApiClient().post('/auth/send-sms-code', data: {'phone': phone, 'scene': 'change_phone'});
      if (mounted) {
        _showMessage('验证码已发送');
        setState(() => _countdownNew = 60);
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) { timer.cancel(); return; }
          setState(() {
            if (_countdownNew > 0) { _countdownNew--; } else { timer.cancel(); }
          });
        });
      }
    } catch (e) {
      if (mounted) _showMessage('发送失败：$e', isError: true);
    }
  }

  Future<void> _submit() async {
    final phone = _newPhoneController.text.trim();
    final pwd = _passwordController.text.trim();
    final code = _newCodeController.text.trim();

    if (pwd.isEmpty) {
      _showMessage('请输入账号密码', isError: true);
      return;
    }
    if (phone.length != 11) {
      _showMessage('请输入11位新手机号', isError: true);
      return;
    }
    if (code.length != 6) {
      _showMessage('请输入6位验证码', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().post('/auth/change-phone', data: {
        'password': pwd,
        'new_phone': phone,
        'new_phone_code': code,
      });
      if (resp.data['success'] == true && mounted) {
        _showMessage('手机号换绑成功！');
        context.pop();
      }
    } on DioException catch (e) {
      String message = '换绑失败，请稍后重试';
      if (e.response != null) {
        final detail = e.response!.data;
        if (detail is Map<String, dynamic>) {
          message = detail['message']?.toString() ?? message;
        }
      } else if (e.type == DioExceptionType.connectionError) {
        message = '无法连接服务器，请检查网络';
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        message = '连接超时，请检查网络';
      }
      _showMessage(message, isError: true);
    } catch (e) {
      _showMessage('换绑失败：$e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _canSubmit {
    return _passwordController.text.trim().isNotEmpty &&
        _newPhoneController.text.trim().length == 11 &&
        _newCodeController.text.trim().length == 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.secondaryBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildInfoBanner(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(1, '验证身份'),
                  const SizedBox(height: 8),
                  _buildPasswordField(),
                  const SizedBox(height: 24),
                  _buildStepIndicator(2, '输入新手机号'),
                  const SizedBox(height: 8),
                  _buildPhoneField(),
                  const SizedBox(height: 24),
                  _buildStepIndicator(3, '验证新手机号'),
                  const SizedBox(height: 8),
                  _buildCodeField(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('确认更换手机号', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.brandBlue),
          child: Center(child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePwd,
      decoration: _inputDecoration('输入当前密码以验证身份').copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscurePwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: context.colors.textTertiary, size: 20),
          onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
        ),
      ),
      style: TextStyle(fontSize: context.fs(15), color: context.colors.textPrimary),
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _newPhoneController,
      keyboardType: TextInputType.phone,
      maxLength: 11,
      decoration: _inputDecoration('请输入11位新手机号').copyWith(counterText: ''),
      style: TextStyle(fontSize: context.fs(15), color: context.colors.textPrimary),
    );
  }

  Widget _buildCodeField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _inputDecoration('请输入验证码').copyWith(counterText: ''),
            style: TextStyle(fontSize: context.fs(15), color: context.colors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _countdownNew > 0 || _isLoading ? null : _sendNewCode,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _countdownNew > 0
                    ? context.colors.textTertiary.withValues(alpha: 0.3)
                    : AppColors.brandBlue,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              _countdownNew > 0 ? '${_countdownNew}s' : '获取验证码',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _countdownNew > 0 ? context.colors.textTertiary : AppColors.brandBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: context.colors.textTertiary, fontSize: context.fs(14)),
      filled: true,
      fillColor: context.colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildHeader() {
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.chevron_left, size: 20, color: context.colors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              '更换手机号',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w700, color: context.colors.textPrimary, letterSpacing: -0.3),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningAmberBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warningAmberBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: AppColors.warningAmber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '换绑后，原手机号将无法用于登录',
                style: TextStyle(fontSize: context.fs(13), color: context.colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
