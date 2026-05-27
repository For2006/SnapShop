import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headerAnim;
  late final Animation<double> _profileAnim;
  late final Animation<double> _accountAnim;
  late final Animation<double> _appAnim;
  late final Animation<double> _aboutAnim;
  late final Animation<double> _helpAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _headerAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
    );
    _profileAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.35, curve: Curves.easeOutCubic),
    );
    _accountAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
    );
    _appAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
    );
    _aboutAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
    );
    _helpAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            _AnimatedSection(
              animation: _headerAnim,
              child: _buildHeader(context),
            ),
            Expanded(
              child: ListView(
                children: [
                  _AnimatedSection(
                    animation: _profileAnim,
                    child: _buildProfileCard(),
                  ),
                  _AnimatedSection(
                    animation: _accountAnim,
                    child: _buildSection('账户', [
                      _SettingsItem(
                        icon: Icons.person_outline,
                        label: '账号管理',
                        onTap: () {},
                      ),
                    ]),
                  ),
                  _AnimatedSection(
                    animation: _appAnim,
                    child: _buildSection('应用', [
                      _SettingsItem(icon: Icons.language, label: '语言', onTap: () {}),
                      _SettingsItem(icon: Icons.palette_outlined, label: '外观', onTap: () {}),
                      _SettingsItem(icon: Icons.text_fields, label: '字体大小', onTap: () {}),
                    ]),
                  ),
                  _AnimatedSection(
                    animation: _aboutAnim,
                    child: _buildSection('关于', [
                      _SettingsItem(icon: Icons.refresh, label: '检查更新', onTap: () {}),
                      _SettingsItem(icon: Icons.description_outlined, label: '服务协议', onTap: () {}),
                    ]),
                  ),
                  _AnimatedSection(
                    animation: _helpAnim,
                    child: _buildSection('', [
                      _SettingsItem(
                        icon: Icons.chat_bubble_outline,
                        label: '帮助与反馈',
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.logout,
                        label: '退出登录',
                        onTap: () {},
                        isDanger: true,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBg)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.chevron_left, size: 24, color: AppColors.textPrimary),
            padding: EdgeInsets.zero,
          ),
          const Expanded(
            child: Text(
              '设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandBlue, AppColors.brandPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '用户账号',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'user@example.com',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_SettingsItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(color: AppColors.cardBg),
              bottom: BorderSide(color: AppColors.cardBg),
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      entry.value.icon,
                      size: 20,
                      color: entry.value.isDanger
                          ? AppColors.errorRed
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      entry.value.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: entry.value.isDanger
                            ? AppColors.errorRed
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: entry.value.isDanger
                          ? AppColors.errorRed.withValues(alpha: 0.6)
                          : AppColors.textTertiary,
                    ),
                    onTap: entry.value.onTap,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  if (!isLast)
                    Divider(height: 1, indent: 16, color: AppColors.cardBg),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedSection({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1.0 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
}
