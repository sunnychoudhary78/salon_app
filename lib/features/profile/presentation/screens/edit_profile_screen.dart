import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/profile/data/services/profile_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _existingImageUrl;
  XFile? _pickedImage;
  bool _removedImage = false;
  bool _saving = false;
  String? _gender;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromAuth());
  }

  void _loadFromAuth() {
    final auth = ref.read(authProvider).value;
    if (auth == null) return;
    _nameController.text = auth.user.name;
    _emailController.text = auth.user.email ?? '';
    _phoneController.text = auth.user.phone ?? '';
    _existingImageUrl = auth.customer?.profileImage;
    final gender = auth.customer?.gender?.toLowerCase();
    _gender = gender == 'male' || gender == 'female' ? gender : null;
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _pickedImage = picked;
      _removedImage = false;
    });
  }

  void _removePhoto() {
    setState(() {
      _pickedImage = null;
      _removedImage = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final actions = ref.read(profileActionsProvider);
      String? profileImageUrl;
      var clearProfileImage = false;

      if (_pickedImage != null) {
        profileImageUrl = await actions.uploadProfileImage(_pickedImage!);
      } else if (_removedImage) {
        clearProfileImage = true;
      }

      await actions.updateProfileFields(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        profileImage: profileImageUrl,
        clearProfileImage: clearProfileImage,
        gender: _gender,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).value;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Edit profile',
        showMenu: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: auth == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  AppDecorations.scrollBottomPadding(context),
                ),
                children: [
                  AnimatedEntrance(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Profile photo',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: _ProfilePhotoPreview(
                              pickedImage: _pickedImage,
                              existingImageUrl: _removedImage
                                  ? null
                                  : _existingImageUrl,
                              initials: _initials,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: PremiumButton(
                                  label: 'Choose photo',
                                  icon: Icons.photo_library_rounded,
                                  variant: PremiumButtonVariant.ghost,
                                  expand: false,
                                  onPressed: _saving ? null : _pickFromGallery,
                                ),
                              ),
                              if (_pickedImage != null ||
                                  (!_removedImage &&
                                      (_existingImageUrl?.isNotEmpty ??
                                          false))) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PremiumButton(
                                    label: 'Remove',
                                    icon: Icons.delete_outline_rounded,
                                    variant: PremiumButtonVariant.ghost,
                                    expand: false,
                                    onPressed: _saving ? null : _removePhoto,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Personal details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _nameController,
                            label: 'Full name',
                            validator: validateRequiredName,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          PremiumTextField(
                            controller: _emailController,
                            label: 'Email (optional)',
                            keyboardType: TextInputType.emailAddress,
                            validator: validateOptionalEmail,
                          ),
                          const SizedBox(height: 12),
                          PremiumTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            keyboardType: TextInputType.phone,
                            enabled: false,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _saving
                                  ? null
                                  : () {
                                      final isOwner = GoRouterState.of(context)
                                          .uri
                                          .path
                                          .startsWith('/owner');
                                      context.push(
                                        isOwner
                                            ? RoutePaths.ownerChangePhone
                                            : RoutePaths.customerChangePhone,
                                      );
                                    },
                              child: const Text('Change phone number'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 0),
                            child: Text(
                              'Changing your phone requires OTP verification on the new number.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.appColors.textMuted,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gender',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Male'),
                                  selected: _gender == 'male',
                                  onSelected: _saving
                                      ? null
                                      : (_) => setState(() => _gender = 'male'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Female'),
                                  selected: _gender == 'female',
                                  onSelected: _saving
                                      ? null
                                      : (_) =>
                                            setState(() => _gender = 'female'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PremiumButton(
                    label: 'Save changes',
                    variant: PremiumButtonVariant.accent,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfilePhotoPreview extends StatelessWidget {
  const _ProfilePhotoPreview({
    required this.pickedImage,
    required this.existingImageUrl,
    required this.initials,
  });

  final XFile? pickedImage;
  final String? existingImageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            pickedImage == null &&
                (existingImageUrl == null || existingImageUrl!.isEmpty)
            ? context.appColors.accentGradient
            : null,
        border: Border.all(color: context.appColors.glassBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: context.appColors.accent.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: pickedImage != null
          ? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
          : existingImageUrl != null && existingImageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: resolveImageUrl(existingImageUrl!),
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _InitialsAvatar(initials: initials),
            )
          : _InitialsAvatar(initials: initials),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: context.appColors.onAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
