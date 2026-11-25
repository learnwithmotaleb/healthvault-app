import 'json.dart';
import 'user_models.dart';

// =============================================================== Provider
class ProviderModel {
  final String id; // provider profile id
  final String fullName;
  final String? displayName;
  final String? profileImage;
  final String? about;
  final String? address;
  final String? location;
  final String? specialization;
  final int? yearsOfExperience;
  final List<String> languages;
  final ProviderTypeModel? providerType;
  final List<ServiceModel> services;
  final List<AvailabilityDay> availabilityDays;
  final String? email;
  final String? phone;

  ProviderModel({
    required this.id,
    required this.fullName,
    this.displayName,
    this.profileImage,
    this.about,
    this.address,
    this.location,
    this.specialization,
    this.yearsOfExperience,
    this.languages = const [],
    this.providerType,
    this.services = const [],
    this.availabilityDays = const [],
    this.email,
    this.phone,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> j) {
    final account = J.map(j['account']);
    final pt = j['providerType'] is Map ? j['providerType'] : (j['providerTypeId'] is Map ? j['providerTypeId'] : null);
    return ProviderModel(
      id: J.s(j['_id']),
      fullName: J.s(j['fullName']),
      displayName: J.str(j['displayName']),
      profileImage: J.str(j['profile_image']),
      about: J.str(j['about']),
      address: J.str(j['address']),
      location: J.str(j['location']),
      specialization: J.str(j['specialization']),
      yearsOfExperience: J.integer(j['yearsOfExperience']),
      languages: J.strings(j['languages']),
      providerType: pt != null ? ProviderTypeModel.fromJson(J.map(pt)) : null,
      services: J.list(j['services'], ServiceModel.fromJson),
      availabilityDays: J.list(j['availabilityDays'], AvailabilityDay.fromJson),
      email: J.str(account['email']) ?? J.str(j['email']),
      phone: J.str(account['phone']) ?? J.str(j['phone']),
    );
  }

  String get name => (displayName != null && displayName!.isNotEmpty) ? displayName! : fullName;
  String get typeLabel => providerType?.label ?? '';
  String get subtitle => [specialization, typeLabel].whereType<String>().where((e) => e.isNotEmpty).join(' • ');
}

class FavoriteModel {
  final String id;
  final String providerId;
  final ProviderModel? provider;

  FavoriteModel({required this.id, required this.providerId, this.provider});

  factory FavoriteModel.fromJson(Map<String, dynamic> j) {
    final p = J.firstMap(j, ['provider', 'providerId']);
    return FavoriteModel(
      id: J.s(j['_id']),
      providerId: J.s(j['providerId']),
      provider: p != null ? ProviderModel.fromJson(p) : null,
    );
  }
}

// =============================================================== Appointment
class AppointmentPerson {
  final String id;
  final String fullName;
  final String? profileImage;
  final String? email;
  final String? phone;
  final String? address;
  final String? location;
  final String? specialization;
  final String? gender;
  final String? bloodGroup;
  final DateTime? dateOfBirth;
  final String? providerTypeLabel;

  AppointmentPerson({
    required this.id,
    required this.fullName,
    this.profileImage,
    this.email,
    this.phone,
    this.address,
    this.location,
    this.specialization,
    this.gender,
    this.bloodGroup,
    this.dateOfBirth,
    this.providerTypeLabel,
  });

  factory AppointmentPerson.fromJson(Map<String, dynamic> j) => AppointmentPerson(
        id: J.s(j['_id']),
        fullName: J.s(j['fullName'], J.s(j['displayName'])),
        profileImage: J.str(j['profile_image']),
        email: J.str(j['email']),
        phone: J.str(j['phone']),
        address: J.str(j['address']),
        location: J.str(j['location']),
        specialization: J.str(j['specialization']),
        gender: J.str(j['gender']),
        bloodGroup: J.str(j['bloodGroup']),
        dateOfBirth: J.date(j['dateOfBirth']),
        providerTypeLabel: J.str(J.map(j['providerType'])['label']),
      );

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var a = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) a--;
    return a;
  }
}

class AppointmentModel {
  final String id;
  final String normalUserId;
  final String providerId;
  final String serviceId;
  final String? reasonForVisit;
  final DateTime? dateTime;
  final String? dateTimeRaw;
  final int durationMinutes;
  final String status;
  final bool isActive;
  final String? cancellationReason;
  final String? cancelledBy;
  final AppointmentPerson? normalUser;
  final AppointmentPerson? provider;
  final ServiceModel? service;

  AppointmentModel({
    required this.id,
    required this.normalUserId,
    required this.providerId,
    required this.serviceId,
    this.reasonForVisit,
    this.dateTime,
    this.dateTimeRaw,
    this.durationMinutes = 30,
    required this.status,
    this.isActive = true,
    this.cancellationReason,
    this.cancelledBy,
    this.normalUser,
    this.provider,
    this.service,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) {
    final nu = J.firstMap(j, ['normalUser', 'normalUserId']);
    final pr = J.firstMap(j, ['provider', 'providerId']);
    final sv = J.firstMap(j, ['service', 'serviceId']);
    return AppointmentModel(
      id: J.s(j['_id']),
      normalUserId: J.s(j['normalUserId']),
      providerId: J.s(j['providerId']),
      serviceId: J.s(j['serviceId']),
      reasonForVisit: J.str(j['reasonForVisit']),
      dateTime: J.date(j['appointmentDateTime']),
      dateTimeRaw: J.str(j['appointmentDateTime']),
      durationMinutes: J.integer(j['durationMinutes']) ?? 30,
      status: J.s(j['status'], 'PENDING').toUpperCase(),
      isActive: J.b(j['isActive'], true),
      cancellationReason: J.str(j['cancellationReason']),
      cancelledBy: J.str(j['cancelledBy']),
      normalUser: nu != null ? AppointmentPerson.fromJson(nu) : null,
      provider: pr != null ? AppointmentPerson.fromJson(pr) : null,
      service: sv != null ? ServiceModel.fromJson(sv) : null,
    );
  }

  bool get canPatientCancel => status == 'PENDING' || status == 'CONFIRMED';
}

// =============================================================== Reminder
class ReminderModel {
  final String id;
  final String pillName;
  final String dosage;
  final String schedule; // Daily | Weekly | Monthly
  final List<String> times;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? instructions;
  final String assignedTo;
  final bool isActive;
  final String? prescriptionFile;
  final int? dayOfWeek;
  final int? dayOfMonth;

  ReminderModel({
    required this.id,
    required this.pillName,
    required this.dosage,
    required this.schedule,
    required this.times,
    this.startDate,
    this.endDate,
    this.instructions,
    this.assignedTo = 'SELF',
    this.isActive = true,
    this.prescriptionFile,
    this.dayOfWeek,
    this.dayOfMonth,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> j) {
    final meta = J.map(j['scheduleMeta']);
    return ReminderModel(
      id: J.s(j['_id']),
      pillName: J.s(j['pillName']),
      dosage: J.s(j['dosage']),
      schedule: J.s(j['schedule'], 'Daily'),
      times: J.strings(j['times']),
      startDate: J.date(j['startDate']),
      endDate: J.date(j['endDate']),
      instructions: J.str(j['instructions']),
      assignedTo: J.s(j['assignedTo'], 'SELF'),
      isActive: J.b(j['isActive'], true),
      prescriptionFile: J.str(j['prescription_file']),
      dayOfWeek: J.integer(meta['dayOfWeek']),
      dayOfMonth: J.integer(meta['dayOfMonth']),
    );
  }

  bool get isEnded => endDate != null && endDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));
}

class DoseModel {
  final String reminderId;
  final String pillName;
  final String dosage;
  final String? instructions;
  final String assignedTo;
  final String time;
  final String scheduledAt; // keep raw ISO for intake call
  final String status;

  DoseModel({
    required this.reminderId,
    required this.pillName,
    required this.dosage,
    this.instructions,
    this.assignedTo = 'SELF',
    required this.time,
    required this.scheduledAt,
    required this.status,
  });

  factory DoseModel.fromJson(Map<String, dynamic> j) => DoseModel(
        reminderId: J.s(j['reminderId']),
        pillName: J.s(j['pillName']),
        dosage: J.s(j['dosage']),
        instructions: J.str(j['instructions']),
        assignedTo: J.s(j['assignedTo'], 'SELF'),
        time: J.s(j['time']),
        scheduledAt: J.s(j['scheduledAt']),
        status: J.s(j['status'], 'UPCOMING').toUpperCase(),
      );

  DoseModel copyWith({String? status}) => DoseModel(
        reminderId: reminderId,
        pillName: pillName,
        dosage: dosage,
        instructions: instructions,
        assignedTo: assignedTo,
        time: time,
        scheduledAt: scheduledAt,
        status: status ?? this.status,
      );

  bool get isConfirmable => status == 'UPCOMING' || status == 'PENDING';
}

class AdherenceStats {
  final int taken;
  final int missed;
  final int skipped;
  final int pending;
  final num? adherenceRate;
  final String? reminderId;
  final String? pillName;
  final String? dosage;

  AdherenceStats({
    this.taken = 0,
    this.missed = 0,
    this.skipped = 0,
    this.pending = 0,
    this.adherenceRate,
    this.reminderId,
    this.pillName,
    this.dosage,
  });

  factory AdherenceStats.fromJson(Map<String, dynamic> j) => AdherenceStats(
        taken: J.integer(j['taken']) ?? 0,
        missed: J.integer(j['missed']) ?? 0,
        skipped: J.integer(j['skipped']) ?? 0,
        pending: J.integer(j['pending']) ?? 0,
        adherenceRate: J.dbl(j['adherenceRate']),
        reminderId: J.str(j['reminderId']),
        pillName: J.str(j['pillName']),
        dosage: J.str(j['dosage']),
      );
}

class IntakeRecord {
  final String id;
  final String reminderId;
  final DateTime? scheduledAt;
  final DateTime? takenAt;
  final String status;
  final String? pillName;
  final String? dosage;

  IntakeRecord({
    required this.id,
    required this.reminderId,
    this.scheduledAt,
    this.takenAt,
    required this.status,
    this.pillName,
    this.dosage,
  });

  factory IntakeRecord.fromJson(Map<String, dynamic> j) {
    final r = J.map(j['reminder']);
    return IntakeRecord(
      id: J.s(j['_id']),
      reminderId: J.s(j['reminderId']),
      scheduledAt: J.date(j['scheduledAt']),
      takenAt: J.date(j['takenAt']),
      status: J.s(j['status']).toUpperCase(),
      pillName: J.str(r['pillName']),
      dosage: J.str(r['dosage']),
    );
  }
}

// =============================================================== Health log
class HealthLogModel {
  final String id;
  final String forWhom;
  final String? familyMemberName;
  final DateTime? recordedAt;
  final num? systolic;
  final num? diastolic;
  final num? heartRate;
  final num? weight;
  final num? bloodSugar;
  final num? temperature;
  final num? oxygenSaturation;
  final String? note;

  HealthLogModel({
    required this.id,
    this.forWhom = 'SELF',
    this.familyMemberName,
    this.recordedAt,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.weight,
    this.bloodSugar,
    this.temperature,
    this.oxygenSaturation,
    this.note,
  });

  factory HealthLogModel.fromJson(Map<String, dynamic> j) => HealthLogModel(
        id: J.s(j['_id']),
        forWhom: J.s(j['forWhom'], 'SELF'),
        familyMemberName: J.str(j['familyMemberName']),
        recordedAt: J.date(j['recordedAt']),
        systolic: J.dbl(j['systolic']),
        diastolic: J.dbl(j['diastolic']),
        heartRate: J.dbl(j['heartRate']),
        weight: J.dbl(j['weight']),
        bloodSugar: J.dbl(j['bloodSugar']),
        temperature: J.dbl(j['temperature']),
        oxygenSaturation: J.dbl(j['oxygenSaturation']),
        note: J.str(j['note']),
      );

  String? get bloodPressure =>
      systolic != null && diastolic != null ? "${_n(systolic)}/${_n(diastolic)}" : null;

  static String _n(num? v) => v == null ? '-' : (v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1));
  static String fmt(num? v) => _n(v);
}

class TrendStat {
  final num? avg;
  final num? min;
  final num? max;
  TrendStat({this.avg, this.min, this.max});
  factory TrendStat.fromJson(Map<String, dynamic> j) =>
      TrendStat(avg: J.dbl(j['avg']), min: J.dbl(j['min']), max: J.dbl(j['max']));
}

class TrendPoint {
  final DateTime? period;
  final int count;
  final Map<String, TrendStat?> values;

  TrendPoint({this.period, this.count = 0, this.values = const {}});

  factory TrendPoint.fromJson(Map<String, dynamic> j) {
    final values = <String, TrendStat?>{};
    j.forEach((k, v) {
      if (k == 'period' || k == 'count') return;
      values[k] = v is Map ? TrendStat.fromJson(J.map(v)) : null;
    });
    return TrendPoint(period: J.date(j['period']), count: J.integer(j['count']) ?? 0, values: values);
  }
}

// =============================================================== Insurance
class InsuranceModel {
  final String id;
  final String forWhom;
  final String? familyMemberName;
  final String name;
  final String number;
  final String insuranceProvider;
  final String? coverageType;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final String? photo;
  final bool reminderEnabled;
  final bool isExpired;
  final int? daysToExpiry;

  InsuranceModel({
    required this.id,
    required this.forWhom,
    this.familyMemberName,
    required this.name,
    required this.number,
    required this.insuranceProvider,
    this.coverageType,
    this.startDate,
    this.expiryDate,
    this.photo,
    this.reminderEnabled = true,
    this.isExpired = false,
    this.daysToExpiry,
  });

  factory InsuranceModel.fromJson(Map<String, dynamic> j) => InsuranceModel(
        id: J.s(j['_id']),
        forWhom: J.s(j['forWhom'], 'SELF'),
        familyMemberName: J.str(j['familyMemberName']),
        name: J.s(j['name']),
        number: J.s(j['number']),
        insuranceProvider: J.s(j['insuranceProvider']),
        coverageType: J.str(j['coverageType']),
        startDate: J.date(j['startDate']),
        expiryDate: J.date(j['expiryDate']),
        photo: J.str(j['insurance_Photo']),
        reminderEnabled: J.b(j['reminderEnabled'], true),
        isExpired: J.b(j['isExpired']),
        daysToExpiry: J.integer(j['daysToExpiry']),
      );
}

// =============================================================== Documents
class MedicalDocumentModel {
  final String id;
  final String title;
  final String category;
  final List<String> tags;
  final String forWhom;
  final String? familyMemberName;
  final DateTime? documentDate;
  final String file;
  final String? fileType;
  final int? fileSize;
  final String status;
  final String? moderationNote;
  final bool isShared;
  final DateTime? createdAt;

  MedicalDocumentModel({
    required this.id,
    required this.title,
    required this.category,
    this.tags = const [],
    this.forWhom = 'SELF',
    this.familyMemberName,
    this.documentDate,
    required this.file,
    this.fileType,
    this.fileSize,
    this.status = 'PENDING',
    this.moderationNote,
    this.isShared = false,
    this.createdAt,
  });

  factory MedicalDocumentModel.fromJson(Map<String, dynamic> j) => MedicalDocumentModel(
        id: J.s(j['_id']),
        title: J.s(j['title'], 'Document'),
        category: J.s(j['category'], 'OTHER'),
        tags: J.strings(j['tags']),
        forWhom: J.s(j['forWhom'], 'SELF'),
        familyMemberName: J.str(j['familyMemberName']),
        documentDate: J.date(j['documentDate']),
        file: J.s(j['file']),
        fileType: J.str(j['fileType']),
        fileSize: J.integer(j['fileSize']),
        status: J.s(j['status'], 'PENDING').toUpperCase(),
        moderationNote: J.str(j['moderationNote']),
        isShared: J.b(j['isShared']),
        createdAt: J.date(j['createdAt']),
      );

  bool get isPdf => (fileType ?? '').contains('pdf') || file.toLowerCase().endsWith('.pdf');

  String get sizeLabel {
    final s = fileSize ?? 0;
    if (s <= 0) return '';
    if (s < 1024 * 1024) return "${(s / 1024).toStringAsFixed(0)} KB";
    return "${(s / 1024 / 1024).toStringAsFixed(1)} MB";
  }
}

// =============================================================== Notifications
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        id: J.s(j['_id']),
        type: J.s(j['type'], 'GENERAL').toUpperCase(),
        title: J.s(j['title']),
        message: J.s(j['message']),
        data: J.map(j['data']),
        isRead: J.b(j['isRead']),
        createdAt: J.date(j['createdAt']),
      );
}

// =============================================================== SOS
class EmergencyNumber {
  final String name;
  final String number;
  EmergencyNumber({required this.name, required this.number});
  factory EmergencyNumber.fromJson(Map<String, dynamic> j) =>
      EmergencyNumber(name: J.s(j['name']), number: J.s(j['number']));
}

class EmergencyInfo {
  final List<EmergencyNumber> numbers;
  final List<EmergencyContact> contacts;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;

  EmergencyInfo({
    this.numbers = const [],
    this.contacts = const [],
    this.bloodGroup,
    this.allergies = const [],
    this.chronicConditions = const [],
  });

  factory EmergencyInfo.fromJson(Map<String, dynamic> j) {
    final med = J.map(j['medicalInfo']);
    return EmergencyInfo(
      numbers: J.list(j['emergencyNumbers'], EmergencyNumber.fromJson),
      contacts: J.list(j['emergencyContacts'], EmergencyContact.fromJson),
      bloodGroup: J.str(med['bloodGroup']),
      allergies: J.strings(med['allergies']),
      chronicConditions: J.strings(med['chronicConditions']),
    );
  }

  static EmergencyInfo fallback() => EmergencyInfo(numbers: [
        EmergencyNumber(name: 'European emergency number', number: '112'),
        EmergencyNumber(name: 'Ambulance (EKAB)', number: '166'),
        EmergencyNumber(name: 'Police', number: '100'),
        EmergencyNumber(name: 'Fire service', number: '199'),
        EmergencyNumber(name: 'Coast guard', number: '108'),
        EmergencyNumber(name: 'Poison center', number: '2107793777'),
      ]);
}

class SosAlertModel {
  final String id;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? message;
  final DateTime? createdAt;

  SosAlertModel({
    required this.id,
    required this.status,
    this.latitude,
    this.longitude,
    this.address,
    this.message,
    this.createdAt,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> j) {
    final coords = J.map(j['location'])['coordinates'];
    double? lng, lat;
    if (coords is List && coords.length >= 2) {
      lng = J.dbl(coords[0]);
      lat = J.dbl(coords[1]);
    }
    return SosAlertModel(
      id: J.s(j['_id']),
      status: J.s(j['status'], 'ACTIVE').toUpperCase(),
      latitude: lat,
      longitude: lng,
      address: J.str(j['address']),
      message: J.str(j['message']),
      createdAt: J.date(j['createdAt']),
    );
  }
}

// =============================================================== Support
class SupportMessage {
  final String id;
  final String sender;
  final String senderRole;
  final String text;
  final DateTime? createdAt;
  final String? createdAtRaw;

  SupportMessage({
    required this.id,
    required this.sender,
    required this.senderRole,
    required this.text,
    this.createdAt,
    this.createdAtRaw,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> j) => SupportMessage(
        id: J.s(j['_id']),
        sender: J.s(j['sender']),
        senderRole: J.s(j['senderRole']).toUpperCase(),
        text: J.s(j['text']),
        createdAt: J.date(j['createdAt']),
        createdAtRaw: J.str(j['createdAt']),
      );

  bool get isFromSupport => senderRole == 'ADMIN' || senderRole == 'SUPER_ADMIN';
}

// =============================================================== Content
class ArticleModel {
  final String id;
  final String title;
  final String details;
  final String? image;
  final DateTime? createdAt;

  ArticleModel({required this.id, required this.title, required this.details, this.image, this.createdAt});

  factory ArticleModel.fromJson(Map<String, dynamic> j) => ArticleModel(
        id: J.s(j['_id']),
        title: J.s(j['title']),
        details: J.s(j['details']),
        image: J.str(j['article_image']),
        createdAt: J.date(j['createdAt']),
      );
}

class FaqModel {
  final String id;
  final String question;
  final String answer;
  FaqModel({required this.id, required this.question, required this.answer});
  factory FaqModel.fromJson(Map<String, dynamic> j) =>
      FaqModel(id: J.s(j['_id']), question: J.s(j['question']), answer: J.s(j['answer']));
}
