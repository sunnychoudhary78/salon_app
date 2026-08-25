import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/core/utils/platform_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/screen_action_bar.dart';
import 'package:saloon_booking/shared/widgets/salon_rating_badge.dart';
import 'package:saloon_booking/shared/widgets/staff_avatar.dart';

class ManageStaffScreen extends ConsumerStatefulWidget {
  const ManageStaffScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends ConsumerState<ManageStaffScreen> {
  Future<void> _showStaffDialog({StaffModel? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _StaffFormSheet(salonId: widget.salonId, existing: existing),
    );

    if (result == true && mounted) {
      ref.invalidate(ownerStaffProvider(widget.salonId));
      ref.invalidate(salonDetailProvider(widget.salonId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(ownerStaffProvider(widget.salonId));

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Manage staff',
        showMenu: false,
        leading: IconButton(
          icon: Icon(platformBackIcon(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add staff',
            onPressed: () => _showStaffDialog(),
          ),
        ],
      ),
      bottomNavigationBar: ScreenActionBar(
        label: 'Add staff',
        icon: Icons.add_rounded,
        onPressed: () => _showStaffDialog(),
      ),
      body: GradientBackground(
        child: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(ownerStaffProvider(widget.salonId)),
        child: AsyncValueWidget(
          value: staff,
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStateScrollable(
                child: EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No staff yet',
                  subtitle:
                      'Add stylists so customers can choose a preferred staff member.',
                ),
              );
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                AppDecorations.scrollBottomPadding(context),
              ),
              children: [
                SectionHeader(
                  title:
                      '${items.length} staff member${items.length == 1 ? '' : 's'}',
                  subtitle: 'Tap a member to edit',
                ),
                const SizedBox(height: 12),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  return AnimatedEntrance(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        elevated: true,
                        radius: 18,
                        onTap: () => _showStaffDialog(existing: member),
                        child: Row(
                          children: [
                            StaffAvatar(
                              name: member.name,
                              imageUrl: member.profileImage,
                              size: 56,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      SalonRatingBadge(
                                        averageRating: member.averageRating,
                                        reviewCount: member.reviewCount,
                                        size: SalonRatingBadgeSize.compact,
                                      ),
                                      const SizedBox(width: 8),
                                      _StatusPill(
                                        label: member.isActive
                                            ? 'Active'
                                            : 'Inactive',
                                        active: member.isActive,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.appColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

class _StaffFormSheet extends ConsumerStatefulWidget {
  const _StaffFormSheet({required this.salonId, this.existing});

  final String salonId;
  final StaffModel? existing;

  @override
  ConsumerState<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends ConsumerState<_StaffFormSheet> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  String? _profileImageUrl;
  XFile? _pickedImage;
  bool _isActive = true;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController.text = existing?.name ?? '';
    _profileImageUrl = existing?.profileImage;
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        _pickedImage = file;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not pick image');
    }
  }

  Future<void> _save() async {
    final nameError = validateRequiredName(_nameController.text);
    if (nameError != null) {
      setState(() => _error = nameError);
      return;
    }
    final name = _nameController.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      var imageUrl = _profileImageUrl;
      if (_pickedImage != null) {
        setState(() => _uploading = true);
        imageUrl = await ref
            .read(ownerOnboardingActionsProvider)
            .uploadStaffImage(_pickedImage!);
      }

      final body = {
        'name': name,
        'profile_image': imageUrl,
        'status': _isActive ? 'ACTIVE' : 'INACTIVE',
      };

      final api = ref.read(ownerServiceProvider);
      if (widget.existing == null) {
        await api.createStaff(salonId: widget.salonId, body: body);
      } else {
        await api.updateStaff(
          salonId: widget.salonId,
          staffId: widget.existing!.id,
          body: body,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _errorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploading = false;
        });
      }
    }
  }

  String _errorMessage(Object error) => userFacingErrorMessage(error);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEditing ? 'Edit staff' : 'Add staff',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _saving ? null : _pickImage,
                child: Stack(
                  children: [
                    StaffAvatar(
                      name: _nameController.text.isEmpty
                          ? 'S'
                          : _nameController.text,
                      imageUrl: _pickedImage == null ? _profileImageUrl : null,
                      localPath: _pickedImage?.path,
                      size: 88,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.appColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.appColors.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to change photo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            PremiumTextField(
              controller: _nameController,
              label: 'Name',
              validator: validateRequiredName,
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: Text(
                'Inactive staff are hidden from customers',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appColors.textMuted,
                ),
              ),
              value: _isActive,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _isActive = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            PremiumButton(
              label: _uploading
                  ? 'Uploading…'
                  : _saving
                  ? 'Saving…'
                  : (_isEditing ? 'Save changes' : 'Add staff'),
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : context.appColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
