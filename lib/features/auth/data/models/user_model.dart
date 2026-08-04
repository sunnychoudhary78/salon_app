import 'package:saloon_booking/core/utils/json_parse_utils.dart';

class RoleModel {
  const RoleModel({required this.id, required this.name, this.hierarchyLevel});

  final String id;
  final String name;
  final int? hierarchyLevel;

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
    id: requireString(json, 'id'),
    name: requireString(json, 'name'),
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
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final List<RoleModel> roles;
  final String? status;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: requireString(json, 'id'),
    name: requireString(json, 'name'),
    email: optionalString(json, 'email'),
    phone: optionalString(json, 'phone'),
    status: optionalString(json, 'status'),
    roles: (json['roles'] as List<dynamic>? ?? [])
        .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    List<RoleModel>? roles,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    roles: roles ?? this.roles,
    status: status,
  );
}

class CustomerProfileModel {
  const CustomerProfileModel({
    required this.id,
    this.profileImage,
    this.dob,
    this.gender,
  });

  final String id;
  final String? profileImage;
  final String? dob;
  final String? gender;

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) =>
      CustomerProfileModel(
        id: requireString(json, 'id'),
        profileImage: optionalString(json, 'profile_image'),
        dob: json['dob']?.toString(),
        gender: optionalString(json, 'gender'),
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
        id: requireString(json, 'id'),
        businessName: requireString(json, 'business_name'),
        gstNumber: optionalString(json, 'gst_number'),
        status: optionalString(json, 'status'),
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
        id: requireString(json, 'id'),
        salonName: requireString(json, 'salon_name'),
        applicationStatus: requireString(json, 'application_status'),
        applicationType: optionalString(json, 'application_type') ?? 'CREATE',
        salonId: optionalString(json, 'salon_id'),
        rejectionReason: optionalString(json, 'rejection_reason'),
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
    token: requireString(json, 'token'),
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class OtpVerifyResult {
  const OtpVerifyResult({
    required this.isNewUser,
    this.authState,
    this.authResponse,
    this.signupToken,
    this.phone,
  });

  final bool isNewUser;
  final AuthState? authState;
  final AuthResponse? authResponse;
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
  }) => AuthState(
    token: token,
    user: user ?? this.user,
    customer: customer ?? this.customer,
    salonOwner: salonOwner ?? this.salonOwner,
    salonApplication: salonApplication ?? this.salonApplication,
  );
}
