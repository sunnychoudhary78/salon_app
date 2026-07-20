class NotificationTypes {
  NotificationTypes._();

  static const bookingConfirmed = 'booking_confirmed';
  static const bookingRejected = 'booking_rejected';
  static const bookingCompleted = 'booking_completed';
  static const appointmentReminder = 'appointment_reminder';
  static const bookingCancelled = 'booking_cancelled';
  static const paymentSuccessful = 'payment_successful';
  static const promotionalOffer = 'promotional_offer';
  static const newBooking = 'new_booking';
  static const paymentReceived = 'payment_received';
  static const salonApplicationSubmitted = 'salon_application_submitted';
  static const salonApplicationApproved = 'salon_application_approved';
  static const salonApplicationRejected = 'salon_application_rejected';
  static const newReview = 'new_review';
}

class NotificationScreens {
  NotificationScreens._();

  static const bookingDetails = 'booking_details';
  static const promotions = 'promotions';
  static const ownerBookingDetails = 'owner_booking_details';
  static const ownerEarnings = 'owner_earnings';
  static const ownerDashboard = 'owner_dashboard';
  static const ownerReviews = 'owner_reviews';
}

class NotificationUserRoles {
  NotificationUserRoles._();

  static const customer = 'customer';
  static const salonOwner = 'salon_owner';
}
