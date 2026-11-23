import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/reward_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays a celebratory modal dialog when a customer earns a mystery reward upon payment.
Future<void> showRewardScratchDialog(
  BuildContext context, {
  required CustomerRewardModel reward,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => RewardScratchDialog(initialReward: reward),
  );
}

class RewardScratchDialog extends ConsumerStatefulWidget {
  const RewardScratchDialog({super.key, required this.initialReward});

  final CustomerRewardModel initialReward;

  @override
  ConsumerState<RewardScratchDialog> createState() => _RewardScratchDialogState();
}

class _RewardScratchDialogState extends ConsumerState<RewardScratchDialog>
    with SingleTickerProviderStateMixin {
  late CustomerRewardModel _reward;
  bool _revealing = false;
  bool _copied = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _reward = widget.initialReward;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _revealReward() async {
    if (_revealing || _reward.isClaimed) return;
    setState(() => _revealing = true);
    HapticFeedback.heavyImpact();

    try {
      final claimed = await ref
          .read(customerServiceProvider)
          .claimReward(_reward.id);
      ref.invalidate(myRewardsProvider);

      if (!mounted) return;
      setState(() {
        _reward = claimed;
        _revealing = false;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() => _revealing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reveal reward: $e')),
      );
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final r = _reward.reward;
    final isClaimed = _reward.isClaimed;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Close & Celebration Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  // Glowing celebration circle
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.08);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37),
                            Color(0xFFAA771C),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.celebration_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: colors.textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                isClaimed ? '🎉 Voucher Unlocked!' : '🎉 Payment Successful!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                isClaimed
                  ? 'Congratulations! Here is your exclusive voucher code:'
                  : 'You unlocked a Mystery Reward for completing your payment! Scratch/tap below to reveal your voucher.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Interactive Scratch / Mystery Card
              if (!isClaimed) ...[
                // Golden Mystery Scratch Card
                InkWell(
                  onTap: _revealing ? null : _revealReward,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFFF3E5AB),
                          Color(0xFFAA771C),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
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
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                r?.brandName ?? 'CATCHY REWARD',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Icon(
                          Icons.touch_app_rounded,
                          size: 38,
                          color: Color(0xFF5A3D06),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _revealing ? 'Revealing your reward...' : 'TAP TO SCRATCH & REVEAL',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF3E2B05),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Exclusive voucher hidden underneath',
                          style: TextStyle(
                            color: Color(0xFF6B4D0B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Revealed Voucher Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.glassBorder),
                  ),
                  child: Column(
                    children: [
                      // Brand & Title
                      if (r?.brandName != null)
                        Text(
                          r!.brandName,
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        r?.title ?? 'Special Reward',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (r?.description != null && r!.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          r.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Code Display with Copy Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.35),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _reward.displayCode.isNotEmpty ? _reward.displayCode : 'CODE',
                              style: TextStyle(
                                color: colors.accent,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                            InkWell(
                              onTap: () => _copyCode(_reward.displayCode),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _copied ? 'Copied!' : 'Copy',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Bottom Actions
              if (isClaimed && r?.externalUrl != null && r!.externalUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(r.externalUrl!),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text('Redeem on ${r.brandName}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(RoutePaths.customerRewards);
                },
                icon: const Icon(Icons.card_giftcard_rounded, size: 16),
                label: const Text('View All My Rewards'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.glassBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
