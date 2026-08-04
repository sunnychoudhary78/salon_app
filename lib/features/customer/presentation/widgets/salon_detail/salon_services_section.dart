import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/providers/audience_mode_provider.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_service_card.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';

class SalonServicesSection extends ConsumerWidget {
  const SalonServicesSection({
    super.key,
    required this.salon,
    required this.onBookService,
  });

  final SalonModel salon;
  final void Function(String serviceId) onBookService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audience = ref.watch(audienceModeValueProvider);
    final services = salon.services
        .where((s) => isServiceVisibleForAudience(s.serviceName, audience))
        .toList();
    if (services.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 360 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                primary: false,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 160,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return AnimatedEntrance(
                    delay: Duration(milliseconds: 50 * index),
                    child: SalonServiceCard(
                      service: service,
                      audience: audience,
                      onBook: () => onBookService(service.id),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
