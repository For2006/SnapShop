import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import 'settings_provider.dart';

class AccountSecurityPage extends ConsumerStatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  ConsumerState<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends ConsumerState<AccountSecurityPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLoggedIn = ref.read(settingsProvider).isLoggedIn;
      if (!isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.secondaryBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildItem(
              icon: Icons.lock_outline,
              label: '修改密码',
              iconColor: AppColors.brandBlue,
              onTap: () => context.push('/change-password'),
            ),
            _buildItem(
              icon: Icons.phone_android_outlined,
              label: '换绑手机号',
              iconColor: AppColors.brandPurple,
              onTap: () => context.push('/change-phone'),
            ),
            const SizedBox(height: 24),
            _buildItem(
              icon: Icons.delete_outline,
              label: '注销账号',
              iconColor: AppColors.errorRed,
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('注销账号', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          '注销后所有数据将被永久删除，包括收藏、浏览历史和搜索记录。此操作不可恢复。',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('账号注销功能即将上线')),
              );
            },
            child: const Text('确认注销', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                  ),
                ],
              ),
              child: Icon(Icons.chevron_left, size: 20, color: context.colors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              '账号安全',
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

  Widget _buildItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w500,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: context.colors.textTertiary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
