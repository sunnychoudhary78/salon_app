class RoutePaths {
  RoutePaths._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/auth/login';
  static const otpVerify = '/auth/otp';
  static const completeProfile = '/auth/complete-profile';
  static const adminBlocked = '/admin-blocked';

  static const customerHome = '/customer/home';
  static const customerSalons = '/customer/salons';
  static const customerBookings = '/customer/bookings';
  static const customerProfile = '/customer/profile';
  static const customerEditProfile = '/customer/profile/edit';
  static const customerChangePhone = '/customer/profile/change-phone';
  static const customerChangePhoneOtp = '/customer/profile/change-phone/otp';
  static const salonDetail = '/customer/salons/:id';
  static const bookAppointment = '/customer/salons/:id/book';
  static const writeReview = '/customer/bookings/:id/review';

  static const customerNotifications = '/customer/notifications';
  static const customerSettings = '/customer/settings';

  static const ownerDashboard = '/owner/dashboard';
  static const ownerSalons = '/owner/salons';
  static const ownerBookings = '/owner/bookings';
  static const ownerReviews = '/owner/reviews';
  static const ownerNotifications = '/owner/notifications';
  static const ownerProfile = '/owner/profile';
  static const ownerEditProfile = '/owner/profile/edit';
  static const ownerChangePhone = '/owner/profile/change-phone';
  static const ownerChangePhoneOtp = '/owner/profile/change-phone/otp';
  static const ownerSettings = '/owner/settings';
  static const ownerEarnings = '/owner/earnings';
  static const ownerEarningsTransactions = '/owner/earnings/transactions';
  static const ownerPayoutAccount = '/owner/payout-account';
  static const ownerServices = '/owner/salons/:salonId/services';
  static const ownerStaff = '/owner/salons/:salonId/staff';
  static const ownerEditSalon = '/owner/salons/:salonId/edit';
  static const ownerSchedule = '/owner/salons/:salonId/schedule';
  static const becomeOwner = '/owner/become';
  static const applySalon = '/owner/apply';
  static const pendingApproval = '/owner/pending';
}
