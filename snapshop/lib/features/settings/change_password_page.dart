import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../core/network/api_client.dart';
import 'settings_provider.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

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
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _submit() async {
    final oldPwd = _oldPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();

    if (oldPwd.isEmpty) {
      _showMessage('请输入原密码', isError: true);
      return;
    }
    if (newPwd.length < 8) {
      _showMessage('新密码至少需要8位字符', isError: true);
      return;
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(newPwd) || !RegExp(r'\d').hasMatch(newPwd)) {
      _showMessage('密码必须包含至少一个字母和一个数字', isError: true);
      return;
    }
    if (newPwd != confirmPwd) {
      _showMessage('两次输入的新密码不一致', isError: true);
      return;
    }
    if (oldPwd == newPwd) {
      _showMessage('新密码不能与原密码相同', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().post('/auth/change-password', data: {
        'old_password': oldPwd,
        'new_password': newPwd,
      });
      if (resp.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码修改成功，请重新登录'), duration: Duration(seconds: 2)),
        );
        await ref.read(settingsProvider.notifier).logout();
        if (mounted) context.go('/login');
      }
    } on DioException catch (e) {
      String message = '修改失败，请稍后重试';
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
      _showMessage('修改失败：$e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _canSubmit {
    return _oldPasswordController.text.trim().isNotEmpty &&
        _newPasswordController.text.trim().length >= 8 &&
        _confirmPasswordController.text.trim().length >= 8;
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
            const SizedBox(height: 12),
            _buildInfoBanner(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('原密码'),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                    controller: _oldPasswordController,
                    hintText: '请输入原密码',
                    obscure: _obscureOld,
                    onToggleObscure: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('新密码'),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    hintText: '至少8位，包含字母和数字',
                    obscure: _obscureNew,
                    onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('确认新密码'),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    hintText: '再次输入新密码',
                    obscure: _obscureConfirm,
                    onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    onSubmitted: _canSubmit ? () => _submit() : null,
                  ),
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
                          : const Text('确认修改', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                '修改密码后，您需要重新登录账号',
                style: TextStyle(fontSize: context.fs(13), color: context.colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.fs(14),
        fontWeight: FontWeight.w600,
        color: context.colors.textPrimary,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggleObscure,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
      decoration: InputDecoration(
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
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: context.colors.textTertiary, size: 20),
          onPressed: onToggleObscure,
        ),
      ),
      style: TextStyle(fontSize: context.fs(15), color: context.colors.textPrimary),
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
              '修改密码',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w700, color: context.colors.textPrimary, letterSpacing: -0.3),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
