import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class StaffAvatar extends StatelessWidget {
  const StaffAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.localPath,
    this.size = 48,
  });

  final String name;
  final String? imageUrl;
  final String? localPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';

    final Widget child;
    if (localPath != null && localPath!.isNotEmpty) {
      child = Image.file(
        File(localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _StaffInitial(initial: initial),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _StaffInitial(initial: initial),
        placeholder: (_, __) => _StaffInitial(initial: initial),
      );
    } else {
      child = _StaffInitial(initial: initial);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

class _StaffInitial extends StatelessWidget {
  const _StaffInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appColors.accent.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.appColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
