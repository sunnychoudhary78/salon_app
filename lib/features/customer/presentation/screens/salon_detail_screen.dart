import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_about_section.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_booking_bar.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_hero_section.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_reviews_section.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_services_section.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_similar_section.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_staff_section.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_summary_card.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_why_choose_section.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';

class SalonDetailScreen extends ConsumerWidget {
  const SalonDetailScreen({super.key, required this.salonId});

  final String salonId;

  void _openBooking(
    BuildContext context, {
    String? serviceId,
    String? staffId,
  }) {
    final base = '${RoutePaths.customerSalons}/$salonId/book';
    final params = <String, String>{};
    if (serviceId != null && serviceId.isNotEmpty) {
      params['serviceId'] = serviceId;
    }
    if (staffId != null && staffId.isNotEmpty) {
      params['staffId'] = staffId;
    }
    if (params.isEmpty) {
      context.push(base);
    } else {
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      context.push('$base?$query');
    }
  }

  Future<void> _openDirections(BuildContext context, SalonModel salon) async {
    final lat = salon.latitude;
    final lng = salon.longitude;
    final Uri mapsUri;
    if (lat != null && lng != null) {
      mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else {
      final query = Uri.encodeComponent(
        (salon.formattedAddress?.isNotEmpty == true)
            ? salon.formattedAddress!
            : [
                salon.address,
                salon.city,
                salon.state,
              ].where((s) => s != null && s.isNotEmpty).join(', '),
      );
      if (query.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location available for directions')),
        );
        return;
      }
      mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
    }
    final launched = await launchWebUrl(mapsUri.toString());
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
  }

  Future<void> _callSalon(BuildContext context, SalonModel salon) async {
    final phone = salon.phone?.trim() ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phone not available')));
      return;
    }
    final launched = await launchPhoneCall(phone);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open dialer')));
    }
  }

  void _shareSalon(BuildContext context, SalonModel salon) {
    final link = '${RoutePaths.customerSalons}/$salonId';
    final text = 'Check out ${salon.salonName} on CATCHY\n$link';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Salon link copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(salonDetailProvider(salonId));
    final reviewsAsync = ref.watch(salonReviewsProvider(salonId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) popOrGoHome(context);
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: context.appColors.surface,
        body: AsyncValueWidget(
          value: salonAsync,
          data: (salon) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SalonHeroSection(
                  salon: salon,
                  onBack: () => popOrGoHome(context),
                ),
              ),
              SliverToBoxAdapter(
                child: SalonSummaryCard(
                  salon: salon,
                  onDirections: () => _openDirections(context, salon),
                  onCall: () => _callSalon(context, salon),
                  onShare: () => _shareSalon(context, salon),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  SalonServicesSection(
                    salon: salon,
                    onBookService: (serviceId) =>
                        _openBooking(context, serviceId: serviceId),
                  ),
                  AsyncValueWidget(
                    value: reviewsAsync,
                    loading: const SizedBox.shrink(),
                    data: (reviewsResult) => SalonReviewsSection(
                      salon: salon,
                      reviewsResult: reviewsResult,
                    ),
                  ),
                  SalonAboutSection(salon: salon),
                  SalonWhyChooseSection(salon: salon),
                  SalonStaffSection(
                    staff: salon.staff,
                    onBookStaff: (staffId) =>
                        _openBooking(context, staffId: staffId),
                  ),
                  SalonSimilarSection(salonId: salonId),
                  const SizedBox(height: 88),
                ]),
              ),
            ],
          ),
        ),
        bottomNavigationBar: salonAsync.maybeWhen(
          data: (salon) => SalonBookingBar(
            salon: salon,
            onBook: () => _openBooking(context),
          ),
          orElse: () => null,
        ),
      ),
    );
  }
}
