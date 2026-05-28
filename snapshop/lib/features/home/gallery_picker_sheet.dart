import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../config/app_colors.dart';
import '../../config/l10n/app_localizations.dart';
import 'home_provider.dart';

class GalleryPickerSheet extends ConsumerStatefulWidget {
  final bool compact;
  final bool active;
  const GalleryPickerSheet({super.key, this.compact = false, this.active = false});

  @override
  ConsumerState<GalleryPickerSheet> createState() =>
      _GalleryPickerSheetState();
}

class _GalleryPickerSheetState extends ConsumerState<GalleryPickerSheet>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _hasBeenActive = false;
  List<AssetEntity> _photos = [];
  final Map<int, Uint8List?> _thumbnails = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) {
      _hasBeenActive = true;
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPhotos();
      });
    }
  }

  @override
  void didUpdateWidget(GalleryPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      setState(() {
        _hasBeenActive = true;
        _isLoading = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPhotos();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active) {
      _loadPhotos(fromResume: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadPhotos({bool fromResume = false}) async {
    // 从设置页面返回后，给系统时间更新权限状态
    if (fromResume) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    setState(() {
      _photos = [];
    });

    final currentPerm = await PhotoManager.getPermissionState(requestOption: const PermissionRequestOption());
    if (!mounted) return;

    if (!currentPerm.hasAccess) {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;

      if (!permission.hasAccess) {
        setState(() {
          _isLoading = false;
          _hasPermission = false;
        });
        return;
      }
    }

    setState(() {
      _hasPermission = true;
    });

    try {
      final count = await PhotoManager.getAssetCount(type: RequestType.image);
      if (count == 0) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final size = count < 30 ? count : 30;
      final photos = await PhotoManager.getAssetListPaged(
        page: 0,
        pageCount: size,
        type: RequestType.image,
      );
      photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      // 预加载缩略图
      final thumbnails = <int, Uint8List?>{};
      for (var i = 0; i < photos.length; i++) {
        final data = await photos[i].thumbnailDataWithSize(
          const ThumbnailSize(200, 200),
        );
        thumbnails[i] = data;
      }

      if (mounted) {
        setState(() {
          _photos = photos;
          _thumbnails
            ..clear()
            ..addAll(thumbnails);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Container(
        color: AppColors.primaryBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildBody(context),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => ref.read(homeProvider.notifier).closeGallery(),
            child: Container(color: Colors.transparent),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: AppColors.primaryBg,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildBody(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_hasBeenActive) return const SizedBox.shrink();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              l10n.galleryPermissionTitle,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                // 先重新请求权限
                final perm = await PhotoManager.requestPermissionExtend();
                if (perm.hasAccess) {
                  _loadPhotos();
                  return;
                }
                // 仍被拒绝则跳转系统设置
                PhotoManager.openSetting();
              },
              child: Text(l10n.galleryPermissionGrant),
            ),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined,
                size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              l10n.galleryEmpty,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: _photos.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildGalleryEntry(context);
        }
        return _buildGalleryItem(index - 1);
      },
    );
  }

  Widget _buildGalleryEntry(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null && context.mounted) {
          ref.read(homeProvider.notifier).closeGallery();
          ref.read(homeProvider.notifier).startRecognition();
          context.push('/results');
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.divider,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.brandBlueLight,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.galleryTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryItem(int index) {
    final asset = _photos[index];
    final thumb = _thumbnails[index];
    return GestureDetector(
      onTap: () async {
        final file = await asset.file;
        if (file != null && mounted) {
          ref.read(homeProvider.notifier).closeGallery();
          ref.read(homeProvider.notifier).startRecognition();
          context.push('/results');
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: thumb != null
            ? Image.memory(
                thumb,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : Container(
                color: AppColors.cardBg,
                child: const Icon(Icons.photo, color: AppColors.textSecondary),
              ),
      ),
    );
  }
}
