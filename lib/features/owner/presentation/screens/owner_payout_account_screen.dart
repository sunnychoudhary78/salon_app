import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerPayoutAccountScreen extends ConsumerStatefulWidget {
  const OwnerPayoutAccountScreen({super.key});

  @override
  ConsumerState<OwnerPayoutAccountScreen> createState() =>
      _OwnerPayoutAccountScreenState();
}

class _OwnerPayoutAccountScreenState extends ConsumerState<OwnerPayoutAccountScreen> {
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

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return error.toString();
  }

  Future<void> _save() async {
    final holder = _holderController.text.trim();
    final accountNumber = _accountController.text.trim();
    final ifsc = _ifscController.text.trim();
    final upi = _upiController.text.trim();

    if (holder.isEmpty || accountNumber.isEmpty || ifsc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account holder, number, and IFSC are required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(ownerServiceProvider).upsertPayoutAccount(
        accountHolderName: holder,
        accountNumber: accountNumber,
        ifscCode: ifsc,
        upiId: upi.isEmpty ? null : upi,
      );
      ref.invalidate(ownerPayoutAccountProvider);
      _accountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout account saved')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(ownerPayoutAccountProvider);

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Payout account',
        subtitle: 'Bank details for settlements',
      ),
      body: AsyncValueWidget(
        value: account,
        data: (existing) {
          _populateForm(existing);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              AppDecorations.scrollBottomPadding(context),
            ),
            children: [
              if (existing != null) ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Current account',
                        subtitle: 'On file for payouts',
                      ),
                      const SizedBox(height: 8),
                      Text('${existing.accountHolderName} · ${existing.ifscCode}'),
                      if (existing.accountNumberMasked != null)
                        Text('Account ${existing.accountNumberMasked}'),
                      if (existing.verificationStatus != null)
                        Text('Status: ${existing.verificationStatus}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              SectionHeader(
                title: existing == null ? 'Add account' : 'Update account',
                subtitle: 'Enter bank details securely',
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: _holderController,
                label: 'Account holder name',
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: _accountController,
                label: existing == null ? 'Account number' : 'New account number',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: _ifscController,
                label: 'IFSC code',
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: _upiController,
                label: 'UPI ID (optional)',
              ),
              const SizedBox(height: 24),
              PremiumButton(
                label: 'Save payout account',
                loading: _saving,
                loadingLabel: 'Saving',
                onPressed: _saving ? null : _save,
              ),
            ],
          );
        },
      ),
    );
  }
}
