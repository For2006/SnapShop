import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/l10n/app_localizations.dart';
import '../../config/theme_context.dart';
import '../../config/route_observer.dart';
import '../../core/network/api_client.dart';
import '../../core/history_item.dart';
import '../settings/settings_provider.dart';
import '../product_list/product_provider.dart';
import 'home_provider.dart';
import 'main_search_bar.dart';
import 'gallery_picker_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin, RouteAware {
  late final AnimationController _drawerController;
  double _dragStartValue = 0.0;
  bool _isUserDragging = false;
  double _dragCumulativeDelta = 0.0;

  bool _prevIsHistoryOpen = false;
  int _historyRefreshKey = 0;
  int _homeRefreshKey = 0;

  List<HistoryItem> _historyItems = [];
  bool _historyLoading = false;

  late final AnimationController _entranceController;
  late final Animation<double> _brandAnim;
  late final Animation<double> _topBtnFadeAnim;

  @override
  void initState() {
    super.initState();

    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _brandAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );
    _topBtnFadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.unsubscribe(this);
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _entranceController.reset();
    _entranceController.forward();
    FocusScope.of(context).unfocus();
    _homeRefreshKey++;
    final notifier = ref.read(homeProvider.notifier);
    if (ref.read(homeProvider).isGalleryOpen) {
      notifier.closeGallery();
    }
    if (ref.read(homeProvider).isHistoryOpen) {
      notifier.closeHistory();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _drawerController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _toggleHistory() {
    _isUserDragging = false;
    if (ref.read(homeProvider).isHistoryOpen) {
      ref.read(homeProvider.notifier).closeHistory();
      _drawerController.animateTo(0.0,
        curve: Curves.easeOutCubic,
        duration: const Duration(milliseconds: 300),
      );
    } else {
      ref.read(homeProvider.notifier).openHistory();
      _drawerController.animateTo(1.0,
        curve: Curves.easeOutCubic,
        duration: const Duration(milliseconds: 350),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGalleryOpen = ref.watch(homeProvider.select((s) => s.isGalleryOpen));
    final isHistoryOpen = ref.watch(homeProvider.select((s) => s.isHistoryOpen));

    if (!isHistoryOpen && _prevIsHistoryOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _historyRefreshKey++;
        _prevIsHistoryOpen = false;
      });
    }
    if (isHistoryOpen && !_prevIsHistoryOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadHistory();
        _prevIsHistoryOpen = true;
      });
    }

    if (!_isUserDragging) {
      if (isHistoryOpen && _drawerController.isDismissed) {
        _drawerController.animateTo(1.0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 350),
        );
      } else if (!isHistoryOpen && _drawerController.isCompleted) {
        _drawerController.animateTo(0.0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    final cardBody = _buildCardBody(context, isGalleryOpen, isHistoryOpen);

    return RepaintBoundary(
      child: PopScope(
        canPop: !isGalleryOpen && !isHistoryOpen,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            if (isGalleryOpen) {
              ref.read(homeProvider.notifier).closeGallery();
            } else if (isHistoryOpen) {
              ref.read(homeProvider.notifier).closeHistory();
            }
          }
        },
        child: Scaffold(
          backgroundColor: context.colors.primaryBg,
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              _buildHistoryContent(context),
              GestureDetector(
                onHorizontalDragStart: (_) {
                  _dragStartValue = _drawerController.value;
                  _dragCumulativeDelta = 0;
                  _isUserDragging = true;
                },
                onHorizontalDragUpdate: (details) {
                  _dragCumulativeDelta += details.primaryDelta ?? 0;
                  final newValue = (_dragStartValue + _dragCumulativeDelta / 305.0).clamp(0.0, 1.0);
                  _drawerController.value = newValue;
                },
                onHorizontalDragEnd: (details) {
                  _isUserDragging = false;
                  final velocity = details.primaryVelocity ?? 0;
                  final goOpen = (velocity.abs() > 300 && velocity > 0) ||
                                 (velocity.abs() <= 300 && _drawerController.value > 0.5);
                  if (goOpen) {
                    _drawerController.animateTo(1.0,
                      curve: Curves.easeOutCubic,
                      duration: const Duration(milliseconds: 200),
                    );
                    ref.read(homeProvider.notifier).openHistory();
                  } else {
                    _drawerController.animateTo(0.0,
                      curve: Curves.easeOutCubic,
                      duration: const Duration(milliseconds: 200),
                    );
                    ref.read(homeProvider.notifier).closeHistory();
                  }
                },
                onHorizontalDragCancel: () {
                  _isUserDragging = false;
                },
                child: AnimatedBuilder(
                  animation: _drawerController,
                  child: cardBody,
                  builder: (context, child) {
                    final v = _drawerController.value;
                    final offset = 305 * v;
                    final radius = 24 * v;
                    final shadowOpacity = 0.25 * v;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.primaryBg,
                          borderRadius: radius > 0 ? BorderRadius.circular(radius) : null,
                          boxShadow: shadowOpacity > 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: shadowOpacity),
                                    blurRadius: 24,
                                    offset: const Offset(-8, 0),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              RepaintBoundary(child: child!),
                              if (v > 0.01)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: _toggleHistory,
                                    child: Container(
                                      color: Colors.white.withValues(alpha: 0.15 * v),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent(BuildContext context) {
    final isLoggedIn = ref.watch(settingsProvider.select((s) => s.isLoggedIn));
    return SafeArea(
      key: ValueKey('history_$_historyRefreshKey'),
      child: Padding(
        padding: const EdgeInsets.only(right: 50),
        child: isLoggedIn
            ? _buildLoggedInHistory(context)
            : _buildLoginPrompt(context),
      ),
    );
  }

  Widget _buildLoggedInHistory(BuildContext context) {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyItems.isEmpty) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildHistoryHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                AppLocalizations.of(context).noSearchHistory,
                style: TextStyle(color: context.colors.textSecondary, fontSize: context.fs(14)),
              ),
            ),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHistoryHeader(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).searchHistory,
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showClearAllDialog(context),
                  child: Text(
                    AppLocalizations.of(context).historyClearConfirm,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: Colors.red.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = _historyItems[index];
              return _buildHistoryTile(context, item, index);
            },
            childCount: _historyItems.length,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTile(BuildContext context, HistoryItem item, int index) {
    final isImage = item.searchType == 'image';
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(homeProvider.notifier).setSearchQuery(item.displayText);
                ref.read(productListProvider.notifier).updateProducts([]);
                ref.read(homeProvider.notifier).submitTextSearch(item.displayText);
                ref.read(homeProvider.notifier).closeHistory();
                context.push('/results');
              },
              onLongPress: () => _showDeleteDialog(context, item),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isImage
                            ? AppColors.brandBlue.withOpacity(0.1)
                            : context.colors.textSecondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isImage ? Icons.camera_alt_outlined : Icons.search,
                        size: 20,
                        color: isImage ? AppColors.brandBlue : context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(15),
                              fontWeight: FontWeight.w500,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (item.createdAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _formatHistoryTime(item.createdAt!),
                              style: TextStyle(fontSize: context.fs(12), color: context.colors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isImage
                            ? AppColors.brandBlue.withOpacity(0.1)
                            : context.colors.textSecondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isImage ? AppLocalizations.of(context).historyTypeImage : AppLocalizations.of(context).historyTypeText,
                        style: TextStyle(
                          fontSize: context.fs(11),
                          color: isImage ? AppColors.brandBlue : context.colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: context.colors.textSecondary.withOpacity(0.4)),
                  ],
                ),
              ),
            ),
          ),
          if (index < _historyItems.length - 1)
            Divider(height: 1, indent: 56, color: context.colors.divider),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.historyClearTitle),
        content: Text(l10n.historyClearMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cacheCancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doClearAll();
            },
            child: Text(l10n.historyClearConfirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, HistoryItem item) {
    final l10n = AppLocalizations.of(context);
    final isImage = item.searchType == 'image';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(isImage ? l10n.historyDeleteMessageImage : l10n.historyDeleteMessageText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cacheCancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _doDeleteItem(item);
            },
            child: Text(l10n.historyDeleteConfirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _doDeleteItem(HistoryItem item) async {
    try {
      final api = ApiClient();
      await api.delete('/history/${item.sessionId}');
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint('[HomePage] 删除搜索记录失败: $e');
    }
  }

  Future<void> _doClearAll() async {
    if (mounted) setState(() { _historyItems = []; _historyRefreshKey++; });
    try {
      final api = ApiClient();
      final resp = await api.delete('/history');
      await _loadHistory();
      if (mounted) {
        final cleared = resp.data is Map ? (resp.data['cleared'] ?? 0) : 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已清空 $cleared 条记录'), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint('[HomePage] 清空搜索记录失败: $e');
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('清空失败，请重试'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  String _formatHistoryTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final l10n = AppLocalizations.of(context);
      return l10n.formatRelativeTime(dt);
    } catch (_) {
      return '';
    }
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            l10n.historyLoginPrompt,
            style: TextStyle(
              fontSize: context.fs(14),
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              l10n.historyLoginButton,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final api = ApiClient();
      final response = await api.get('/history');
      final data = response.data;
      List<HistoryItem> items = [];
      if (data is Map && data['items'] is List) {
        items = (data['items'] as List).map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (mounted) setState(() { _historyItems = items; _historyLoading = false; });
    } catch (e) {
      debugPrint('[HomePage] _loadHistory 失败: $e');
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Widget _buildHistoryHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      child: Text(
        l10n.historyTitle,
        style: TextStyle(
          fontSize: context.fs(24),
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBrandSection(BuildContext context, bool isGalleryOpen, bool isHistoryOpen) {
    return RepaintBoundary(
      child: AnimatedOpacity(
        opacity: isHistoryOpen ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Align(
          alignment: const Alignment(0, -0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: _brandGradient,
                child: Text(
                  'SnapShop',
                  style: TextStyle(
                    fontSize: context.fs(56),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).homeSlogan,
                style: TextStyle(
                  color: context.colors.textTertiary,
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _gradient = LinearGradient(
    colors: [AppColors.brandBlue, AppColors.brandPurple],
  );

  static Shader _brandGradient(Rect bounds) {
    return _gradient.createShader(bounds);
  }

  Widget _buildTopButtons(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 6,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _topBtnFadeAnim,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _toggleHistory,
              icon: Icon(Icons.menu, color: context.colors.textTertiary, size: 18),
            ),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: Icon(Icons.settings_outlined, color: context.colors.textTertiary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBody(BuildContext context, bool isGalleryOpen, bool isHistoryOpen) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0, right: 0,
          top: 0,
          height: screenHeight * 0.45,
          child: AnimatedBuilder(
            animation: _brandAnim,
            builder: (context, _) {
              final fadeIn = (0.35 * (1.0 - _brandAnim.value.clamp(0.0, 1.0))).clamp(0.0, 0.35);
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.9,
                    colors: [
                      AppColors.brandBlue.withValues(alpha: 0.3 * fadeIn),
                      AppColors.brandPurple.withValues(alpha: 0.12 * fadeIn),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        _buildTopButtons(context),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: 0, right: 0,
          top: isGalleryOpen ? topPadding + 56 : screenHeight * 0.22,
          child: AnimatedBuilder(
            animation: _brandAnim,
            builder: (context, child) {
              return Opacity(
                opacity: _brandAnim.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 50 * (1.0 - _brandAnim.value)),
                  child: Transform.scale(
                    scale: 0.92 + 0.08 * _brandAnim.value,
                    child: child,
                  ),
                ),
              );
            },
            child: _buildBrandSection(context, isGalleryOpen, isHistoryOpen),
          ),
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: 16, right: 16,
          top: isGalleryOpen ? topPadding + 172 : null,
          bottom: isGalleryOpen ? null : keyboardHeight + (keyboardHeight > 0 ? 12 : 48),
          child: AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              final t = _entranceController.value;
              final v = t - 1;
              final eased = 1.0 + 2.70158 * v * v * v + 1.70158 * v * v;
              final dropOffset = 240.0 * (1.0 - eased);
              return Transform.translate(
                offset: Offset(0, dropOffset),
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: MainSearchBar(
              key: ValueKey('search_$_homeRefreshKey'),
              isGalleryOpen: isGalleryOpen,
              isHistoryOpen: false,
            ),
          ),
        ),

        Positioned(
          left: 0, right: 0,
          top: topPadding + 236,
          bottom: 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            offset: isGalleryOpen ? Offset.zero : const Offset(0, 1.0),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isGalleryOpen ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !isGalleryOpen,
                child: GalleryPickerSheet(compact: true, active: isGalleryOpen),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
