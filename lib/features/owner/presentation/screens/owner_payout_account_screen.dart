import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/screen_action_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/status_badge.dart';

class OwnerPayoutAccountScreen extends ConsumerStatefulWidget {
  const OwnerPayoutAccountScreen({super.key});

  @override
  ConsumerState<OwnerPayoutAccountScreen> createState() =>
      _OwnerPayoutAccountScreenState();
}

class _OwnerPayoutAccountScreenState
    extends ConsumerState<OwnerPayoutAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _populateForm(OwnerPayoutAccountModel? account) {
    if (_initialized) return;
    if (account != null) {
      _holderController.text = account.accountHolderName;
      _ifscController.text = account.ifscCode;
      _upiController.text = account.upiId ?? '';
    }
    _initialized = true;
  }

  String _errorMessage(Object error) => userFacingErrorMessage(error);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final holder = _holderController.text.trim();
    final accountNumber = _accountController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    final upi = _upiController.text.trim();

    setState(() => _saving = true);
    try {
      await ref
          .read(ownerServiceProvider)
          .upsertPayoutAccount(
            accountHolderName: holder,
            accountNumber: accountNumber,
            ifscCode: ifsc,
            upiId: upi.isEmpty ? null : upi,
          );
      ref.invalidate(ownerPayoutAccountProvider);
      _accountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payout account saved')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(ownerPayoutAccountProvider);
    final colors = context.appColors;

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Payout account',
        subtitle: 'Bank details for settlements',
      ),
      body: GradientBackground(
        child: AsyncValueWidget(
          value: account,
          data: (existing) {
            _populateForm(existing);
            return Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  AppDecorations.scrollBottomPadding(context) + 88,
                ),
                children: [
                  AnimatedEntrance(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.surfaceElevated, colors.accentSoft],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.accent.withValues(alpha: 0.28),
                        ),
                        boxShadow: colors.cardShadow(),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: colors.accent,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure payouts',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'We use these details only for settling your online earnings.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: colors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 16),
                    AnimatedEntrance(
                      index: 1,
                      child: GlassCard(
                        elevated: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Current account',
                              subtitle: 'On file for payouts',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.person_outline_rounded,
                              label: existing.accountHolderName,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.tag_rounded,
                              label: existing.ifscCode,
                            ),
                            if (existing.accountNumberMasked != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.credit_card_rounded,
                                label: 'Account ${existing.accountNumberMasked}',
                              ),
                            ],
                            if (existing.verificationStatus != null) ...[
                              const SizedBox(height: 12),
                              StatusBadge(
                                status: existing.verificationStatus!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AnimatedEntrance(
                    index: 2,
                    child: SectionHeader(
                      title: existing == null ? 'Add account' : 'Update account',
                      subtitle: 'Enter bank details securely',
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedEntrance(
                    index: 3,
                    child: GlassCard(
                      elevated: false,
                      child: Column(
                        children: [
                          PremiumTextField(
                            controller: _holderController,
                            label: 'Account holder name',
                            validator: validateAccountHolderName,
                          ),
                          const SizedBox(height: 12),
                          PremiumTextField(
                            controller: _accountController,
                            label: existing == null
                                ? 'Account number'
                                : 'New account number',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(18),
                            ],
                            validator: validateAccountNumber,
                          ),
                          const SizedBox(height: 12),
                          PremiumTextField(
                            controller: _ifscController,
                            label: 'IFSC code',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]'),
                              ),
                              LengthLimitingTextInputFormatter(11),
                              TextInputFormatter.withFunction((
                                oldValue,
                                newValue,
                              ) {
                                return newValue.copyWith(
                                  text: newValue.text.toUpperCase(),
                                  selection: newValue.selection,
                                );
                              }),
                            ],
                            validator: validateIfsc,
                          ),
                          const SizedBox(height: 12),
                          PremiumTextField(
                            controller: _upiController,
                            label: 'UPI ID (optional)',
                            validator: validateOptionalUpi,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: ScreenActionBar(
        label: 'Save payout account',
        icon: Icons.save_rounded,
        loading: _saving,
        onPressed: _saving ? null : _save,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
