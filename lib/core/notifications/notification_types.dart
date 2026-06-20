class NotificationTypes {
  NotificationTypes._();

  static const bookingConfirmed = 'booking_confirmed';
  static const appointmentReminder = 'appointment_reminder';
  static const bookingCancelled = 'booking_cancelled';
  static const paymentSuccessful = 'payment_successful';
  static const promotionalOffer = 'promotional_offer';
  static const newBooking = 'new_booking';
  static const paymentReceived = 'payment_received';
}

class NotificationScreens {
  NotificationScreens._();

  static const bookingDetails = 'booking_details';
  static const promotions = 'promotions';
  static const ownerBookingDetails = 'owner_booking_details';
  static const ownerEarnings = 'owner_earnings';
}

class NotificationUserRoles {
  NotificationUserRoles._();

  static const customer = 'customer';
  static const salonOwner = 'salon_owner';
}
