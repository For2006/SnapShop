import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import 'home_provider.dart';

class MainSearchBar extends ConsumerStatefulWidget {
  final bool isHistoryOpen;
  final bool isGalleryOpen;
  const MainSearchBar({
    super.key,
    this.isHistoryOpen = false,
    this.isGalleryOpen = false,
  });

  @override
  ConsumerState<MainSearchBar> createState() => _MainSearchBarState();
}

class _MainSearchBarState extends ConsumerState<MainSearchBar> {
  final TextEditingController _textController = TextEditingController();
  bool _hasText = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final isGalleryOpen = homeState.isGalleryOpen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildSearchBar(context, isGalleryOpen),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isGalleryOpen) {
    Future<void> submitSearch() async {
      final value = _textController.text;
      if (value.trim().isEmpty || _isSearching) return;
      setState(() => _isSearching = true);
      ref.read(homeProvider.notifier).setSearchQuery(value);
      await ref.read(homeProvider.notifier).startRecognition();
      if (!mounted) return;
      setState(() => _isSearching = false);
    }

    void onSearchTap() async {
      await submitSearch();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await context.push('/results');
      _textController.clear();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          if (widget.isHistoryOpen)
            _buildIconButton(
              icon: Icons.search,
              onTap: () {},
            )
          else
            _buildIconButton(
              icon: Icons.camera_alt_outlined,
              onTap: () {
                FocusScope.of(context).unfocus();
                context.push('/camera');
              },
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => onSearchTap(),
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '搜索商品...',
                        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _hasText && !_isSearching ? onSearchTap : null,
                    child: _isSearching
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.brandBlueLight,
                            ),
                          )
                        : Icon(
                            _hasText ? Icons.arrow_upward : Icons.search,
                            color: _hasText ? AppColors.brandBlueLight : AppColors.textTertiary,
                            size: 22,
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.isHistoryOpen)
            _buildIconButton(
              icon: isGalleryOpen ? Icons.close : Icons.photo_library_outlined,
              onTap: () => ref.read(homeProvider.notifier).toggleGallery(),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.secondaryBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 22),
        ),
      ),
    );
  }
}
