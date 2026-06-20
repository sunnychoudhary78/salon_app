class RoleModel {
  const RoleModel({
    required this.id,
    required this.name,
    this.hierarchyLevel,
  });

  final String id;
  final String name;
  final int? hierarchyLevel;

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        id: json['id'] as String,
        name: json['name'] as String,
        hierarchyLevel: json['hierarchy_level'] as int?,
      );
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.roles,
    this.status,
    this.hasPassword = true,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final List<RoleModel> roles;
  final String? status;
  final bool hasPassword;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        status: json['status'] as String?,
        hasPassword: json['has_password'] as bool? ?? true,
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    List<RoleModel>? roles,
    bool? hasPassword,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        roles: roles ?? this.roles,
        status: status,
        hasPassword: hasPassword ?? this.hasPassword,
      );
}

class CustomerProfileModel {
  const CustomerProfileModel({
    required this.id,
    this.profileImage,
    this.gender,
    this.dob,
  });

  final String id;
  final String? profileImage;
  final String? gender;
  final String? dob;

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) =>
      CustomerProfileModel(
        id: json['id'] as String,
        profileImage: json['profile_image'] as String?,
        gender: json['gender'] as String?,
        dob: json['dob']?.toString(),
      );
}

class SalonOwnerProfileModel {
  const SalonOwnerProfileModel({
    required this.id,
    required this.businessName,
    this.gstNumber,
    this.status,
  });

  final String id;
  final String businessName;
  final String? gstNumber;
  final String? status;

  factory SalonOwnerProfileModel.fromJson(Map<String, dynamic> json) =>
      SalonOwnerProfileModel(
        id: json['id'] as String,
        businessName: json['business_name'] as String,
        gstNumber: json['gst_number'] as String?,
        status: json['status'] as String?,
      );
}

class SalonApplicationProfileModel {
  const SalonApplicationProfileModel({
    required this.id,
    required this.salonName,
    required this.applicationStatus,
    this.applicationType = 'CREATE',
    this.salonId,
    this.rejectionReason,
    this.createdAt,
  });

  final String id;
  final String salonName;
  final String applicationStatus;
  final String applicationType;
  final String? salonId;
  final String? rejectionReason;
  final String? createdAt;

  factory SalonApplicationProfileModel.fromJson(Map<String, dynamic> json) =>
      SalonApplicationProfileModel(
        id: json['id'] as String,
        salonName: json['salon_name'] as String,
        applicationStatus: json['application_status'] as String,
        applicationType: json['application_type'] as String? ?? 'CREATE',
        salonId: json['salon_id'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
        createdAt: json['created_at']?.toString(),
      );

  bool get isPending => applicationStatus == 'PENDING_APPROVAL';
  bool get isRejected => applicationStatus == 'REJECTED';
  bool get isApproved => applicationStatus == 'APPROVED';
  bool get isCreate => applicationType == 'CREATE';
  bool get isUpdate => applicationType == 'UPDATE';
  bool get isDeactivate =>
      applicationType == 'DEACTIVATE' || applicationType == 'CLOSE';
  bool get isActivate => applicationType == 'ACTIVATE';
}

class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final UserModel user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class OtpVerifyResult {
  const OtpVerifyResult({
    required this.isNewUser,
    this.authState,
    this.signupToken,
    this.phone,
  });

  final bool isNewUser;
  final AuthState? authState;
  final String? signupToken;
  final String? phone;
}

class ProfileResponse {
  const ProfileResponse({
    required this.user,
    this.customer,
    this.salonOwner,
    this.salonApplication,
  });

  final UserModel user;
  final CustomerProfileModel? customer;
  final SalonOwnerProfileModel? salonOwner;
  final SalonApplicationProfileModel? salonApplication;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      ProfileResponse(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        customer: json['customer'] != null
            ? CustomerProfileModel.fromJson(
                json['customer'] as Map<String, dynamic>,
              )
            : null,
        salonOwner: json['salon_owner'] != null
            ? SalonOwnerProfileModel.fromJson(
                json['salon_owner'] as Map<String, dynamic>,
              )
            : null,
        salonApplication: json['salon_application'] != null
            ? SalonApplicationProfileModel.fromJson(
                json['salon_application'] as Map<String, dynamic>,
              )
            : null,
      );
}

class AuthState {
  const AuthState({
    required this.token,
    required this.user,
    this.customer,
    this.salonOwner,
    this.salonApplication,
  });

  final String token;
  final UserModel user;
  final CustomerProfileModel? customer;
  final SalonOwnerProfileModel? salonOwner;
  final SalonApplicationProfileModel? salonApplication;

  factory AuthState.fromProfile(String token, ProfileResponse profile) =>
      AuthState(
        token: token,
        user: profile.user,
        customer: profile.customer,
        salonOwner: profile.salonOwner,
        salonApplication: profile.salonApplication,
      );

  AuthState copyWith({
    UserModel? user,
    CustomerProfileModel? customer,
    SalonOwnerProfileModel? salonOwner,
    SalonApplicationProfileModel? salonApplication,
  }) =>
      AuthState(
        token: token,
        user: user ?? this.user,
        customer: customer ?? this.customer,
        salonOwner: salonOwner ?? this.salonOwner,
        salonApplication: salonApplication ?? this.salonApplication,
      );
}
