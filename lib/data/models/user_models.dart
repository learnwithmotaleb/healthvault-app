import 'json.dart';

class EmergencyContact {
  String name;
  String phone;
  String? relation;

  EmergencyContact({required this.name, required this.phone, this.relation});

  factory EmergencyContact.fromJson(Map<String, dynamic> j) => EmergencyContact(
        name: J.s(j['name']),
        phone: J.s(j['phone']),
        relation: J.str(j['relation']),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "phone": phone,
        if (relation != null && relation!.isNotEmpty) "relation": relation,
      };
}

class ProviderTypeModel {
  final String id;
  final String key;
  final String label;
  final bool isActive;

  ProviderTypeModel({required this.id, required this.key, required this.label, this.isActive = true});

  factory ProviderTypeModel.fromJson(Map<String, dynamic> j) => ProviderTypeModel(
        id: J.s(j['_id']),
        key: J.s(j['key']),
        label: J.s(j['label'], J.s(j['key'])),
        isActive: J.b(j['isActive'], true),
      );
}

class ServiceModel {
  final String id;
  final String title;
  final num price;
  final String? providerType;
  final bool isAdminCreated;
  final String? providerId;

  ServiceModel({
    required this.id,
    required this.title,
    required this.price,
    this.providerType,
    this.isAdminCreated = false,
    this.providerId,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
        id: J.s(j['_id']),
        title: J.s(j['title']),
        price: J.dbl(j['price']) ?? 0,
        providerType: J.str(j['providerType']),
        isAdminCreated: J.b(j['isAdminCreated']),
        providerId: J.str(j['providerId']),
      );

  String get priceLabel => "€${price % 1 == 0 ? price.toInt() : price}";
}

class AvailabilitySlot {
  final String id;
  final String startTime;
  final String endTime;

  AvailabilitySlot({required this.id, required this.startTime, required this.endTime});

  factory AvailabilitySlot.fromJson(Map<String, dynamic> j) => AvailabilitySlot(
        id: J.s(j['_id']),
        startTime: J.s(j['startTime']),
        endTime: J.s(j['endTime']),
      );
}

class AvailabilityDay {
  final String id;
  final String dayOfWeek;
  final List<AvailabilitySlot> slots;

  AvailabilityDay({required this.id, required this.dayOfWeek, required this.slots});

  factory AvailabilityDay.fromJson(Map<String, dynamic> j) => AvailabilityDay(
        id: J.s(j['_id']),
        dayOfWeek: J.s(j['dayOfWeek']),
        slots: J.list(j['availabilitySlots'], AvailabilitySlot.fromJson),
      );

  static const order = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  /// DateTime.weekday (1 = Monday) → MON…
  static String keyForWeekday(int weekday) => order[weekday - 1];
}

/// Profile of either role (patient or provider). Fields not used by a role stay null.
class ProfileModel {
  final String id;
  final String fullName;
  final String? profileImage;
  final String? address;

  // patient
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? membershipId;
  final String? emergencyContact;
  final List<EmergencyContact> emergencyContacts;
  final String? identificationNumber;
  final List<String> allergies;
  final List<String> chronicConditions;

  // provider
  final String? displayName;
  final String? about;
  final String? location;
  final String? specialization;
  final String? medicalLicenseNumber;
  final int? yearsOfExperience;
  final List<String> languages;
  final String? approvalStatus;
  final String? rejectionReason;
  final bool isVerified;
  final bool isActive;
  final String? identificationImages;
  final ProviderTypeModel? providerType;
  final List<String> serviceIds;
  final List<ServiceModel> services;

  final Map<String, dynamic> raw;

  ProfileModel({
    required this.id,
    required this.fullName,
    this.profileImage,
    this.address,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.membershipId,
    this.emergencyContact,
    this.emergencyContacts = const [],
    this.identificationNumber,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.displayName,
    this.about,
    this.location,
    this.specialization,
    this.medicalLicenseNumber,
    this.yearsOfExperience,
    this.languages = const [],
    this.approvalStatus,
    this.rejectionReason,
    this.isVerified = false,
    this.isActive = true,
    this.identificationImages,
    this.providerType,
    this.serviceIds = const [],
    this.services = const [],
    this.raw = const {},
  });

  factory ProfileModel.fromJson(Map<String, dynamic> j) {
    final pt = j['providerType'] is Map
        ? j['providerType']
        : (j['providerTypeId'] is Map ? j['providerTypeId'] : null);
    return ProfileModel(
      id: J.s(j['_id']),
      fullName: J.s(j['fullName']),
      profileImage: J.str(j['profile_image']),
      address: J.str(j['address']),
      dateOfBirth: J.date(j['dateOfBirth']),
      gender: J.str(j['gender']),
      bloodGroup: J.str(j['bloodGroup']),
      membershipId: J.str(j['membershipId']),
      emergencyContact: J.str(j['emergencyContact']),
      emergencyContacts: J.list(j['emergencyContacts'], EmergencyContact.fromJson),
      identificationNumber: J.str(j['identificationNumber']),
      allergies: J.strings(j['allergies']),
      chronicConditions: J.strings(j['chronicConditions']),
      displayName: J.str(j['displayName']),
      about: J.str(j['about']),
      location: J.str(j['location']),
      specialization: J.str(j['specialization']),
      medicalLicenseNumber: J.str(j['medicalLicenseNumber']),
      yearsOfExperience: J.integer(j['yearsOfExperience']),
      languages: J.strings(j['languages']),
      approvalStatus: J.str(j['approvalStatus']),
      rejectionReason: J.str(j['rejectionReason']),
      isVerified: J.b(j['isVerified']),
      isActive: J.b(j['isActive'], true),
      identificationImages: J.str(j['identification_images']),
      providerType: pt != null ? ProviderTypeModel.fromJson(J.map(pt)) : null,
      serviceIds: J.strings(j['serviceId'] is List
          ? (j['serviceId'] as List).map((e) => e is Map ? e['_id'] : e).toList()
          : j['serviceId']),
      services: J.list(j['services'], ServiceModel.fromJson),
      raw: j,
    );
  }

  String get name => (displayName != null && displayName!.isNotEmpty) ? displayName! : fullName;
  bool get isApproved => approvalStatus == 'APPROVED';
}

class NotificationPreferences {
  bool appointments;
  bool reminders;
  bool insurance;
  bool general;

  NotificationPreferences({
    this.appointments = true,
    this.reminders = true,
    this.insurance = true,
    this.general = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> j) => NotificationPreferences(
        appointments: J.b(j['appointments'], true),
        reminders: J.b(j['reminders'], true),
        insurance: J.b(j['insurance'], true),
        general: J.b(j['general'], true),
      );

  Map<String, dynamic> toJson() => {
        "appointments": appointments,
        "reminders": reminders,
        "insurance": insurance,
        "general": general,
      };
}

/// Account (User) with embedded role profile – from login / verify / getMe.
class AccountModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final bool isBlocked;
  final bool isEmailVerified;
  final String language;
  final NotificationPreferences notificationPreferences;
  final String? profileId;
  final ProfileModel? profile;
  final Map<String, dynamic> raw;

  AccountModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.isBlocked = false,
    this.isEmailVerified = true,
    this.language = 'en',
    NotificationPreferences? notificationPreferences,
    this.profileId,
    this.profile,
    this.raw = const {},
  }) : notificationPreferences = notificationPreferences ?? NotificationPreferences();

  factory AccountModel.fromJson(Map<String, dynamic> j) {
    final p = j['profile'] is Map ? J.map(j['profile']) : null;
    return AccountModel(
      id: J.s(j['_id']),
      fullName: J.s(j['fullName'], J.s(p?['fullName'])),
      email: J.s(j['email']),
      phone: J.str(j['phone']),
      role: J.s(j['role']).toUpperCase(),
      isBlocked: J.b(j['isBlocked']),
      isEmailVerified: J.b(j['isVerifyEmailOTPVerified'], true),
      language: J.s(j['language'], 'en'),
      notificationPreferences: NotificationPreferences.fromJson(J.map(j['notificationPreferences'])),
      profileId: J.str(j['profileId']) ?? J.str(p?['_id']),
      profile: p != null ? ProfileModel.fromJson(p) : null,
      raw: j,
    );
  }

  bool get isProvider => role == 'PROVIDER';
  String get displayName => profile?.name ?? fullName;
  String get imageUrl => profile?.profileImage ?? '';
}
