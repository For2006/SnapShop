import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/route_observer.dart';
import '../../shared/widgets/search_history_section.dart';
import '../../shared/widgets/browse_history_section.dart';
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

  // 历史记录刷新
  bool _prevIsHistoryOpen = false;
  int _historyRefreshKey = 0;

  // 主页刷新（返回时重置为初始状态）
  int _homeRefreshKey = 0;

  // 进场动效
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
    routeObserver.subscribe(this, ModalRoute.of(context)! as ModalRoute<void>);
  }

  @override
  void didPopNext() {
    _entranceController.reset();
    _entranceController.forward();
    // 返回主页时收起键盘
    FocusScope.of(context).unfocus();
    // 重置为初始状态
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
    final homeState = ref.watch(homeProvider);
    final isGalleryOpen = homeState.isGalleryOpen;
    final isHistoryOpen = homeState.isHistoryOpen;

    // 历史记录关闭时刷新，下次打开为全新状态
    if (!isHistoryOpen && _prevIsHistoryOpen) {
      _historyRefreshKey++;
    }
    _prevIsHistoryOpen = isHistoryOpen;

    // 非拖拽时由 state 驱动动画
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

    return PopScope(
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
        backgroundColor: AppColors.primaryBg,
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
                child: _buildCardBody(context, isGalleryOpen, isHistoryOpen),
                builder: (context, child) {
                  final v = _drawerController.value;
                  final offset = 305 * v;
                  final radius = 24 * v;
                  final shadowOpacity = 0.25 * v;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
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
    );
  }

  Widget _buildHistoryContent(BuildContext context) {
    return SafeArea(
      key: ValueKey('history_$_historyRefreshKey'),
      child: Padding(
        padding: const EdgeInsets.only(right: 50),
        child: Column(
          children: [
            _buildHistoryHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SearchHistorySection(
                    onItemTap: (item) {
                      ref.read(homeProvider.notifier).setSearchQuery(item);
                      ref.read(homeProvider.notifier).startRecognition();
                      ref.read(homeProvider.notifier).closeHistory();
                      context.push('/results');
                    },
                  ),
                  const SizedBox(height: 24),
                  BrowseHistorySection(
                    onItemTap: (product) {
                      ref.read(homeProvider.notifier).closeHistory();
                      context.push('/results');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 16, 12),
      child: Text(
        '历史记录',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }



  Widget _buildBrandSection(bool isGalleryOpen, bool isHistoryOpen) {
    return RepaintBoundary(
      child: AnimatedOpacity(
        opacity: isHistoryOpen ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Align(
          alignment: Alignment(0, -0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: _brandGradient,
                child: Text(
                  'SnapShop',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '拍照识物 · 智能比价',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
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
              icon: Icon(Icons.menu, color: AppColors.textTertiary, size: 18),
            ),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: Icon(Icons.settings_outlined, color: AppColors.textTertiary, size: 18),
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
        // 进场光晕效果 — 品牌背景渐变脉冲
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

        // 顶部按钮
        _buildTopButtons(context),

        // Logo — 普通模式居中，相册模式抬升到顶部
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
            child: _buildBrandSection(isGalleryOpen, isHistoryOpen),
          ),
        ),

        // 搜索栏 — bottom 由 viewInsets 驱动，与键盘动画同步
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

        // 相册瀑布流 — 使用 Slide 动画，不受键盘高度变化影响
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
