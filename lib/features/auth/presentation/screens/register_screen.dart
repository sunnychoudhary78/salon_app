import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/auth_scaffold.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.hasError) {
        setState(() => _error = auth.error.toString());
      }
    } on DioException catch (e) {
      setState(() => _error = e.apiException.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      headline: 'Create your account',
      subtitle: 'Join ${AppConfig.appName}',
      onBack: () => context.pop(),
      child: AnimatedEntrance(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumTextField(
                controller: _nameController,
                label: 'Full name',
                underline: true,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 20),
              PremiumTextField(
                controller: _emailController,
                label: 'Email',
                underline: true,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Email required' : null,
              ),
              const SizedBox(height: 20),
              PremiumTextField(
                controller: _phoneController,
                label: 'Phone (optional)',
                underline: true,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              PremiumTextField(
                controller: _passwordController,
                label: 'Password',
                underline: true,
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 8 ? 'Min 8 characters' : null,
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
                label: 'Sign up',
                variant: PremiumButtonVariant.accent,
                loading: _loading,
                icon: Icons.person_add_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
