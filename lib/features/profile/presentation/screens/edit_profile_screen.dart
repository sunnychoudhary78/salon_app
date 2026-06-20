import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
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
  final _profileImageController = TextEditingController();
  final _genderController = TextEditingController();
  bool _saving = false;

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
    _profileImageController.text = auth.customer?.profileImage ?? '';
    _genderController.text = auth.customer?.gender ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _profileImageController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileActionsProvider).updateProfileFields(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            profileImage: _profileImageController.text.trim().isEmpty
                ? null
                : _profileImageController.text.trim(),
            gender: _genderController.text.trim().isEmpty
                ? null
                : _genderController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                padding: const EdgeInsets.all(16),
                children: [
                  AnimatedEntrance(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Personal details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _nameController,
                            label: 'Full name',
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          PremiumTextField(
                            controller: _emailController,
                            label: 'Email (optional)',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final emailRegex = RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              );
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          PremiumTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            keyboardType: TextInputType.phone,
                            enabled: false,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Phone is verified at login and cannot be changed here.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          PremiumTextField(
                            controller: _genderController,
                            label: 'Gender',
                          ),
                          const SizedBox(height: 12),
                          PremiumTextField(
                            controller: _profileImageController,
                            label: 'Profile image URL',
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
