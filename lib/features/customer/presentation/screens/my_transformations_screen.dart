import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/services/gallery_service.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/gallery/before_after_slider_widget.dart';

class MyTransformationsScreen extends ConsumerWidget {
  const MyTransformationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final transformationsAsync = ref.watch(myTransformationsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Your Transformations', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myTransformationsProvider.future),
        child: transformationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Could not load transformations: $err', style: TextStyle(color: colors.textSecondary)),
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_fix_high_rounded,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Makeovers Yet',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask your stylist to capture your before & after photos during your next appointment!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final isApproved = post.customerConsent == 'APPROVED';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.glassBorder.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.salonName != null) ...[
                        Row(
                          children: [
                            Icon(Icons.storefront_rounded, size: 16, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              post.salonName!,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      BeforeAfterSliderWidget(
                        beforeImageUrl: post.fullBeforeImageUrl,
                        afterImageUrl: post.fullAfterImageUrl,
                        height: 350,
                        borderRadius: 14,
                      ),

                      const SizedBox(height: 14),
                      if (post.title != null && post.title!.isNotEmpty)
                        Text(
                          post.title!,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Privacy / Consent Toggle
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Public Gallery Listing',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isApproved
                                      ? 'Visible on salon portfolio'
                                      : 'Hidden from public (Only you can see)',
                                  style: TextStyle(
                                    color: isApproved ? Colors.green : colors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isApproved,
                            activeTrackColor: Theme.of(context).primaryColor,
                            onChanged: (val) async {
                              final newConsent = val ? 'APPROVED' : 'REJECTED';
                              await ref.read(galleryServiceProvider).updateConsent(
                                post.id,
                                newConsent,
                              );
                              ref.invalidate(myTransformationsProvider);
                              if (post.salonId.isNotEmpty) {
                                ref.invalidate(salonGalleryProvider(post.salonId));
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

