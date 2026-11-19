import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/platform_utils.dart';
import 'package:saloon_booking/features/customer/data/models/gallery_post_model.dart';
import 'package:saloon_booking/features/customer/data/services/gallery_service.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/gallery/before_after_slider_widget.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_dialog.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/screen_action_bar.dart';

class ManageGalleryScreen extends ConsumerStatefulWidget {
  const ManageGalleryScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<ManageGalleryScreen> createState() => _ManageGalleryScreenState();
}

class _ManageGalleryScreenState extends ConsumerState<ManageGalleryScreen> {
  Future<void> _showAddPostSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddGalleryPostSheet(salonId: widget.salonId),
    );

    if (result == true && mounted) {
      ref.invalidate(ownerGalleryProvider(widget.salonId));
      ref.invalidate(salonGalleryProvider(widget.salonId));
    }
  }

  Future<void> _deletePost(GalleryPostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PremiumDialog(
        title: 'Delete Transformation?',
        subtitle: 'Are you sure you want to remove this Before & After post?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(galleryServiceProvider).ownerDeletePost(post.id);
      ref.invalidate(ownerGalleryProvider(widget.salonId));
      ref.invalidate(salonGalleryProvider(widget.salonId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transformation post deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(ownerGalleryProvider(widget.salonId));

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Salon Gallery',
        showMenu: false,
        leading: IconButton(
          icon: Icon(platformBackIcon(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded),
            tooltip: 'Add Transformation',
            onPressed: _showAddPostSheet,
          ),
        ],
      ),
      bottomNavigationBar: ScreenActionBar(
        label: 'Add Transformation',
        icon: Icons.add_photo_alternate_rounded,
        onPressed: _showAddPostSheet,
      ),
      body: GradientBackground(
        child: AsyncValueWidget<List<GalleryPostModel>>(
          value: gallery,
          data: (posts) {
            if (posts.isEmpty) {
              return EmptyState(
                icon: Icons.auto_awesome_rounded,
                title: 'No Transformations Yet',
                subtitle:
                    'Capture Before & After photos for services to showcase your stylists’ skills and attract new clients!',
                actionLabel: 'Add First Transformation',
                onAction: _showAddPostSheet,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ownerGalleryProvider(widget.salonId));
              },
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  AppDecorations.scrollBottomPadding(context),
                ),
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return AnimatedEntrance(
                    index: index,
                    child: _OwnerGalleryPostCard(
                      post: post,
                      onDelete: () => _deletePost(post),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OwnerGalleryPostCard extends StatelessWidget {
  const _OwnerGalleryPostCard({
    required this.post,
    required this.onDelete,
  });

  final GalleryPostModel post;
  final VoidCallback onDelete;

  Color _consentColor(BuildContext context) {
    switch (post.customerConsent) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'PENDING':
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Stylist + Title + Delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.title != null && post.title!.isNotEmpty)
                      Text(
                        post.title!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (post.staffName != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_rounded,
                                  size: 14, color: context.appColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                post.staffName!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.appColors.accent,
                                    ),
                              ),
                            ],
                          ),
                        if (post.serviceName != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.spa_rounded,
                                  size: 14, color: context.appColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                post.serviceName!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.appColors.textMuted,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                tooltip: 'Delete post',
                onPressed: onDelete,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Interactive Before/After slider
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BeforeAfterSliderWidget(
              beforeImageUrl: post.fullBeforeImageUrl,
              afterImageUrl: post.fullAfterImageUrl,
              height: 320,
            ),
          ),

          const SizedBox(height: 12),

          // Customer Tag & Consent Status
          if (post.customerName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _consentColor(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _consentColor(context).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, size: 16, color: _consentColor(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Customer: ${post.customerName!} (${post.customerConsent})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _consentColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Footer stats & visibility
          Row(
            children: [
              Icon(Icons.favorite_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                '${post.likesCount} likes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appColors.textMuted,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: post.isPublic
                      ? AppColors.success.withValues(alpha: 0.12)
                      : context.appColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      post.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                      size: 14,
                      color: post.isPublic ? AppColors.success : context.appColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.isPublic ? 'Public Gallery' : 'Private',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: post.isPublic ? AppColors.success : context.appColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddGalleryPostSheet extends ConsumerStatefulWidget {
  const _AddGalleryPostSheet({required this.salonId});

  final String salonId;

  @override
  ConsumerState<_AddGalleryPostSheet> createState() => _AddGalleryPostSheetState();
}

class _AddGalleryPostSheetState extends ConsumerState<_AddGalleryPostSheet> {
  final _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  XFile? _beforeImage;
  XFile? _afterImage;
  String? _selectedStaffId;
  String? _selectedServiceId;
  bool _isPublic = true;

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _showPhotoSourcePicker(bool isBefore) async {
    final colors = context.appColors;
    final label = isBefore ? 'Before Photo' : 'After Photo';

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  label,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: colors.accent),
                title: Text(
                  'Take Photo with Camera',
                  style: TextStyle(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Capture directly using device camera',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: colors.accent),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Select an existing photo from your device',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _pickImage(isBefore, source);
  }

  Future<void> _pickImage(bool isBefore, ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (file == null || !mounted) return;
      setState(() {
        if (isBefore) {
          _beforeImage = file;
        } else {
          _afterImage = file;
        }
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = source == ImageSource.camera
            ? 'Could not capture photo from camera'
            : 'Could not pick image from gallery',
      );
    }
  }

  Future<void> _submit() async {
    if (_beforeImage == null || _afterImage == null) {
      setState(() => _error = 'Please select both Before and After photos');
      return;
    }

    final phone = _customerPhoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Customer phone number is required');
      return;
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      setState(() => _error = 'Please enter a valid 10-digit customer phone number');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(galleryServiceProvider).ownerCreatePost(
            salonId: widget.salonId,
            beforeImage: File(_beforeImage!.path),
            afterImage: File(_afterImage!.path),
            title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
            description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
            staffId: _selectedStaffId,
            serviceId: _selectedServiceId,
            customerPhone: phone,
            isPublic: _isPublic,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = userFacingErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(ownerStaffProvider(widget.salonId));
    final servicesAsync = ref.watch(ownerServicesProvider(widget.salonId));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Transformation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Showcase your stylists’ work with Before & After pictures.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appColors.textMuted,
                  ),
            ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Photo pickers side-by-side
            Row(
              children: [
                Expanded(
                  child: _PhotoPickerBox(
                    label: 'BEFORE Photo',
                    image: _beforeImage,
                    onTap: () => _showPhotoSourcePicker(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoPickerBox(
                    label: 'AFTER Photo',
                    image: _afterImage,
                    onTap: () => _showPhotoSourcePicker(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stylist dropdown
            staffAsync.maybeWhen(
              data: (staffList) {
                if (staffList.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStaffId,
                    decoration: const InputDecoration(
                      labelText: 'Stylist / Specialist',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    items: staffList
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedStaffId = val),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Service dropdown
            servicesAsync.maybeWhen(
              data: (services) {
                if (services.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedServiceId,
                    decoration: const InputDecoration(
                      labelText: 'Service (Optional)',
                      prefixIcon: Icon(Icons.spa_rounded),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No specific service'),
                      ),
                      ...services.map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.serviceName),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedServiceId = val),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Title
            PremiumTextField(
              controller: _titleController,
              label: 'Title (e.g. Skin Fade & Beard Trim)',
            ),
            const SizedBox(height: 12),

            // Description
            PremiumTextField(
              controller: _descController,
              label: 'Description / Notes (Optional)',
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Customer Phone (Required)
            PremiumTextField(
              controller: _customerPhoneController,
              label: 'Customer Phone (10 digits) *',
              keyboardType: TextInputType.phone,
              hint: 'e.g. 9876543210',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 12),

            // Public gallery switch
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show in Salon Public Gallery'),
              subtitle: Text(
                'Visible to all customers browsing your salon profile',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appColors.textMuted,
                    ),
              ),
              value: _isPublic,
              activeTrackColor: context.appColors.accent,
              onChanged: (val) => setState(() => _isPublic = val),
            ),
            const SizedBox(height: 16),

            // Submit Button
            PremiumButton(
              label: 'Upload Transformation',
              icon: Icons.cloud_upload_rounded,
              loading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPickerBox extends StatelessWidget {
  const _PhotoPickerBox({
    required this.label,
    required this.image,
    required this.onTap,
  });

  final String label;
  final XFile? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null
                ? context.appColors.accent
                : context.appColors.glassBorder,
            width: image != null ? 2 : 1,
          ),
          color: context.appColors.surfaceElevated,
        ),
        clipBehavior: Clip.antiAlias,
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(image!.path),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                      child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 32,
                    color: context.appColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Camera or Gallery',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: context.appColors.textMuted,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

