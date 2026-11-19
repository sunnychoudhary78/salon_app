import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/gallery_post_model.dart';
import 'package:saloon_booking/features/customer/data/services/gallery_service.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/gallery/before_after_slider_widget.dart';
import 'package:saloon_booking/shared/widgets/staff_avatar.dart';

class GalleryCardWidget extends ConsumerStatefulWidget {
  const GalleryCardWidget({
    super.key,
    required this.post,
    this.onBookStaff,
    this.onBookService,
  });

  final GalleryPostModel post;
  final void Function(String staffId)? onBookStaff;
  final void Function(String serviceId)? onBookService;

  @override
  ConsumerState<GalleryCardWidget> createState() => _GalleryCardWidgetState();
}

class _GalleryCardWidgetState extends ConsumerState<GalleryCardWidget> {
  late bool _isLiked;
  late int _likesCount;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe;
    _likesCount = widget.post.likesCount;
  }

  @override
  void didUpdateWidget(covariant GalleryCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _isLiked = widget.post.isLikedByMe;
      _likesCount = widget.post.likesCount;
    }
  }

  Future<void> _handleLikeToggle() async {
    if (_isToggling) return;
    HapticFeedback.lightImpact();

    final prevLiked = _isLiked;
    final prevCount = _likesCount;

    // Optimistic UI update
    setState(() {
      _isToggling = true;
      _isLiked = !prevLiked;
      _likesCount = _isLiked ? prevCount + 1 : (prevCount > 0 ? prevCount - 1 : 0);
    });

    try {
      final res = await ref.read(galleryServiceProvider).toggleLike(widget.post.id);
      if (mounted) {
        setState(() {
          _isLiked = res.liked;
          _likesCount = res.likesCount;
        });
      }
    } catch (_) {
      // Revert if API fails
      if (mounted) {
        setState(() {
          _isLiked = prevLiked;
          _likesCount = prevCount;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final staff = widget.post.staff;
    final service = widget.post.service;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.glassBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Stylist Info & Service Tag
          if (staff != null || service != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  if (staff != null) ...[
                    StaffAvatar(
                      imageUrl: staff.profileImage,
                      name: staff.name,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Specialist',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (service != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        service.serviceName,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // 2. Interactive Before / After Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: BeforeAfterSliderWidget(
              beforeImageUrl: widget.post.fullBeforeImageUrl,
              afterImageUrl: widget.post.fullAfterImageUrl,
              height: 350,
              borderRadius: 14,
            ),
          ),

          // 3. Actions & Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action Bar: Like & Booking Buttons
                Row(
                  children: [
                    InkWell(
                      onTap: _handleLikeToggle,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isLiked ? Colors.redAccent : colors.textSecondary,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_likesCount',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (staff != null && widget.onBookStaff != null)
                      FilledButton.tonalIcon(
                        onPressed: () => widget.onBookStaff!(staff.id),
                        icon: const Icon(Icons.calendar_today_rounded, size: 14),
                        label: Text('Book ${staff.name.split(' ').first}'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      )
                    else if (service != null && widget.onBookService != null)
                      FilledButton.tonal(
                        onPressed: () => widget.onBookService!(service.id),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                        child: const Text('Book Service', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                  ],
                ),

                // Title & Description
                if (widget.post.title != null && widget.post.title!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.post.title!,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
                if (widget.post.description != null && widget.post.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.post.description!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

