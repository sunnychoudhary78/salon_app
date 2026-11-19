import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/reward_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(myRewardsProvider);
    await ref.read(myRewardsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rewardsAsync = ref.watch(myRewardsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('My Rewards & Vouchers'),
        centerTitle: false,
        backgroundColor: colors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.accent,
          unselectedLabelColor: colors.textMuted,
          indicatorColor: colors.accent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Scratch & Win'),
            Tab(text: 'My Vouchers'),
          ],
        ),
      ),
      body: rewardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Failed to load rewards',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (rewards) {
          final unclaimed = rewards.where((r) => r.isUnclaimed && !r.isExpired).toList();
          final claimedOrExpired = rewards
              .where((r) => r.isClaimed || r.isRedeemed || r.isExpired)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _UnclaimedTab(
                rewards: unclaimed,
                onRefresh: _refresh,
              ),
              _ClaimedTab(
                rewards: claimedOrExpired,
                onRefresh: _refresh,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UnclaimedTab extends StatelessWidget {
  const _UnclaimedTab({required this.rewards, required this.onRefresh});

  final List<CustomerRewardModel> rewards;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (rewards.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.card_giftcard_rounded, size: 40, color: colors.accent),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Unclaimed Scratch Cards',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your salon visits to automatically unlock exclusive mystery rewards from Swiggy, Zomato, Nykaa, and more!',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rewards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _ScratchCardItem(
            customerReward: rewards[index],
            onRevealed: onRefresh,
          );
        },
      ),
    );
  }
}

class _ClaimedTab extends StatelessWidget {
  const _ClaimedTab({required this.rewards, required this.onRefresh});

  final List<CustomerRewardModel> rewards;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (rewards.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.confirmation_num_outlined, size: 40, color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Claimed Vouchers Yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scratch your earned cards in the "Scratch & Win" tab to reveal voucher codes here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rewards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _VoucherCardItem(customerReward: rewards[index]);
        },
      ),
    );
  }
}

class _ScratchCardItem extends ConsumerStatefulWidget {
  const _ScratchCardItem({
    required this.customerReward,
    required this.onRevealed,
  });

  final CustomerRewardModel customerReward;
  final VoidCallback onRevealed;

  @override
  ConsumerState<_ScratchCardItem> createState() => _ScratchCardItemState();
}

class _ScratchCardItemState extends ConsumerState<_ScratchCardItem> {
  bool _claiming = false;

  Future<void> _handleClaim() async {
    setState(() => _claiming = true);
    HapticFeedback.mediumImpact();

    try {
      final claimed = await ref
          .read(customerServiceProvider)
          .claimReward(widget.customerReward.id);

      if (!mounted) return;
      setState(() => _claiming = false);

      // Show congratulations dialog with voucher details
      await showDialog(
        context: context,
        builder: (_) => _VoucherCelebrationDialog(customerReward: claimed),
      );

      widget.onRevealed();
    } catch (e) {
      if (!mounted) return;
      setState(() => _claiming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scratch reward: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.customerReward;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4AF37), // Metallic Gold
            Color(0xFFF3E5AB), // Light Gold
            Color(0xFFAA771C), // Deep Gold
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _claiming ? null : _handleClaim,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'MYSTERY CARD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (r.daysRemaining > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Expires in ${r.daysRemaining} days',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _claiming
                          ? const CircularProgressIndicator(color: Color(0xFFAA771C))
                          : const Icon(
                              Icons.card_giftcard_rounded,
                              size: 38,
                              color: Color(0xFFAA771C),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap to Scratch & Reveal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.salonName != null
                      ? 'Earned from visit at ${r.salonName}'
                      : 'Earned from your recent salon appointment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _claiming ? 'SCRATCHING...' : 'CLAIM REWARD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoucherCardItem extends StatelessWidget {
  const _VoucherCardItem({required this.customerReward});

  final CustomerRewardModel customerReward;

  Future<void> _launchExternalUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open external link')),
          );
        }
      }
    }
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher code "$code" copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final r = customerReward;
    final reward = r.reward;
    final isExpired = r.isExpired;
    final isRedeemed = r.isRedeemed;
    final isInactive = isExpired || isRedeemed;
    final voucherCode = r.displayCode.isNotEmpty ? r.displayCode : 'CODE';

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpired ? AppColors.error.withValues(alpha: 0.3) : colors.glassBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with brand and status badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand avatar / icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (reward?.brandName ?? 'B').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward?.brandName ?? 'Partner Brand',
                        style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reward?.title ?? 'Exclusive Reward',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRedeemed
                        ? colors.accent.withValues(alpha: 0.12)
                        : isExpired
                            ? AppColors.error.withValues(alpha: 0.12)
                            : AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isRedeemed
                        ? 'Redeemed'
                        : isExpired
                            ? 'Expired'
                            : 'Claimed',
                    style: TextStyle(
                      color: isRedeemed
                          ? colors.accent
                          : isExpired
                              ? AppColors.error
                              : AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (reward?.description != null && reward!.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                reward.description,
                style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.3),
              ),
            ),

          const SizedBox(height: 12),

          // Voucher Code Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.25),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 18, color: colors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      voucherCode,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: !isInactive
                        ? () => _copyCode(context, voucherCode)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: isInactive ? colors.textMuted : colors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'COPY',
                            style: TextStyle(
                              color: isInactive ? colors.textMuted : colors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Internal Salon Discount hint or External Partner Redeem Button
          if (reward?.isSalonDiscount == true && !isInactive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: colors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reward!.minOrderValue != null && reward.minOrderValue! > 0
                            ? 'Ready to use on your next salon booking (Min order ₹${reward.minOrderValue!.toInt()}).'
                            : 'Ready to apply directly in Checkout Coupons on your next salon booking!',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (reward?.externalUrl != null && reward!.externalUrl!.isNotEmpty && !isInactive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: ElevatedButton.icon(
                onPressed: () => _launchExternalUrl(context, reward.externalUrl!),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text('Redeem on ${reward.brandName}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VoucherCelebrationDialog extends StatelessWidget {
  const _VoucherCelebrationDialog({required this.customerReward});

  final CustomerRewardModel customerReward;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reward = customerReward.reward;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.accent, colors.accent.withValues(alpha: 0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.celebration_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '🎉 Congratulations!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'You unlocked an exclusive voucher from ${reward?.brandName ?? 'our partner'}!',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.glassBorder),
              ),
              child: Column(
                children: [
                  Text(
                    reward?.title ?? 'Exclusive Deal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      customerReward.displayCode.isNotEmpty
                          ? customerReward.displayCode
                          : 'CODE',
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final codeToCopy = customerReward.displayCode;
                      if (codeToCopy.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: codeToCopy));
                        HapticFeedback.selectionClick();
                      }
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Copy Code'),
                  ),
                ),
                if (reward?.externalUrl != null && reward!.externalUrl!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final uri = Uri.tryParse(reward.externalUrl!);
                        if (uri != null) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Redeem Now'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
