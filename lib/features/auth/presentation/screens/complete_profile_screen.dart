import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/providers/audience_mode_provider.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/auth_scaffold.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _gender;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      setState(() => _error = 'Please select your gender');
      return;
    }

    final pending = ref.read(pendingSignupProvider);
    if (pending == null) {
      if (mounted) context.go(RoutePaths.login);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .completeProfile(
            name: _nameController.text.trim(),
            gender: _gender!,
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          );
      await ref
          .read(audienceModeProvider.notifier)
          .hydrateFromGender(_gender);
      if (!mounted) return;
      context.go(RoutePaths.customerHome);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingSignupProvider);
    if (pending == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(RoutePaths.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colors = context.appColors;

    return AuthScaffold(
      headline: 'Create your profile',
      subtitle: 'Tell us a bit about yourself',
      showLogo: true,
      logoHero: true,
      logoSize: AuthScaffold.heroLogoSize,
      child: AnimatedEntrance(
        style: EntranceStyle.scaleIn,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              PremiumTextField(
                controller: _nameController,
                label: 'Full name',
                underline: true,
                prefixIcon: const Icon(Icons.person_outline),
                validator: validateRequiredName,
              ),
              const SizedBox(height: 20),
              PremiumTextField(
                controller: _emailController,
                label: 'Email (optional)',
                underline: true,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: validateOptionalEmail,
              ),
              const SizedBox(height: 20),
              Text(
                'Gender',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _GenderOption(
                      label: 'Male',
                      selected: _gender == 'male',
                      onTap: () => setState(() => _gender = 'male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderOption(
                      label: 'Female',
                      selected: _gender == 'female',
                      onTap: () => setState(() => _gender = 'female'),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              PremiumButton(
                label: 'Continue',
                variant: PremiumButtonVariant.accent,
                loading: _loading,
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: selected ? colors.accentSoft : colors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.accent : colors.glassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
