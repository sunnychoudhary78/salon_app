import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';

class SalonImagePicker extends StatelessWidget {
  const SalonImagePicker({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.maxImages = 10,
  });

  final List<XFile> images;
  final ValueChanged<List<XFile>> onImagesChanged;
  final int maxImages;

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final remaining = maxImages - images.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can add up to $maxImages photos')),
      );
      return;
    }

    List<XFile> picked;
    if (remaining == 1) {
      final single = await picker.pickImage(source: ImageSource.gallery);
      picked = single != null ? [single] : [];
    } else {
      picked = await picker.pickMultiImage(limit: remaining);
    }

    if (picked.isEmpty) return;
    onImagesChanged([...images, ...picked].take(maxImages).toList());
  }

  void _removeImage(int index) {
    final updated = List<XFile>.from(images)..removeAt(index);
    onImagesChanged(updated);
  }

  void _setAsCover(int index) {
    if (index == 0) return;
    final updated = List<XFile>.from(images);
    final image = updated.removeAt(index);
    updated.insert(0, image);
    onImagesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salon photos',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Add one or more photos. The first image is the cover photo.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        if (images.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final file = images[index];
                final isCover = index == 0;
                return GestureDetector(
                  onTap: () => _setAsCover(index),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(file.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isCover)
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Cover',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Material(
                          color: AppColors.error,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _removeImage(index),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (images.isNotEmpty) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: images.length >= maxImages
              ? null
              : () => _pickImages(context),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            images.isEmpty ? 'Add photos' : 'Add more photos',
          ),
        ),
      ],
    );
  }
}

/// Edits existing remote URLs plus new local picks for salon update requests.
class SalonImageEditor extends StatelessWidget {
  const SalonImageEditor({
    super.key,
    required this.existingUrls,
    required this.newImages,
    required this.onExistingUrlsChanged,
    required this.onNewImagesChanged,
    this.maxImages = 10,
  });

  final List<String> existingUrls;
  final List<XFile> newImages;
  final ValueChanged<List<String>> onExistingUrlsChanged;
  final ValueChanged<List<XFile>> onNewImagesChanged;
  final int maxImages;

  int get _totalCount => existingUrls.length + newImages.length;

  Future<void> _pickImages(BuildContext context) async {
    final remaining = maxImages - _totalCount;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can add up to $maxImages photos')),
      );
      return;
    }

    final picker = ImagePicker();
    List<XFile> picked;
    if (remaining == 1) {
      final single = await picker.pickImage(source: ImageSource.gallery);
      picked = single != null ? [single] : [];
    } else {
      picked = await picker.pickMultiImage(limit: remaining);
    }
    if (picked.isEmpty) return;
    onNewImagesChanged(
      [...newImages, ...picked].take(remaining + newImages.length).toList(),
    );
  }

  void _removeExisting(int index) {
    final updated = List<String>.from(existingUrls)..removeAt(index);
    onExistingUrlsChanged(updated);
  }

  void _removeNew(int index) {
    final updated = List<XFile>.from(newImages)..removeAt(index);
    onNewImagesChanged(updated);
  }

  void _setExistingAsCover(int index) {
    if (index == 0) return;
    final updated = List<String>.from(existingUrls);
    final url = updated.removeAt(index);
    updated.insert(0, url);
    onExistingUrlsChanged(updated);
  }

  void _setNewAsCover(int index) {
    if (existingUrls.isNotEmpty || index == 0) return;
    final updated = List<XFile>.from(newImages);
    final file = updated.removeAt(index);
    updated.insert(0, file);
    onNewImagesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Salon photos', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'First image is the cover photo. Changes apply after admin approval.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        if (_totalCount > 0)
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _totalCount,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isCover = index == 0;
                if (index < existingUrls.length) {
                  final url = existingUrls[index];
                  return _ImageThumb(
                    isCover: isCover,
                    onTap: () => _setExistingAsCover(index),
                    onRemove: () => _removeExisting(index),
                    child: CachedNetworkImage(
                      imageUrl: resolveImageUrl(url),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  );
                }

                final fileIndex = index - existingUrls.length;
                final file = newImages[fileIndex];
                return _ImageThumb(
                  isCover: isCover,
                  onTap: () => _setNewAsCover(fileIndex),
                  onRemove: () => _removeNew(fileIndex),
                  child: Image.file(
                    File(file.path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        if (_totalCount > 0) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _totalCount >= maxImages ? null : () => _pickImages(context),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(_totalCount == 0 ? 'Add photos' : 'Add more photos'),
        ),
      ],
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({
    required this.isCover,
    required this.onTap,
    required this.onRemove,
    required this.child,
  });

  final bool isCover;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: AppColors.error,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only thumbnail strip for the review step.
class SalonImageReviewStrip extends StatelessWidget {
  const SalonImageReviewStrip({super.key, required this.images});

  final List<XFile> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(images[index].path),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
