import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/location/user_location_service.dart';

final userLocationServiceProvider = Provider<UserLocationService>((ref) {
  return UserLocationService();
});
