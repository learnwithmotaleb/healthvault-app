import 'package:healthvault/helper/local_db/local_db.dart';

class ApiUrl {
  /// Server root (no trailing slash). Change this for staging / production.
  static const mainDomain = "http://10.10.27.224:3333";
  static const baseUrl = '$mainDomain/api/v1';

  // ============================ Files ==============================
  /// Build a displayable URL from a file value returned by the API.
  /// - `http...`            → used as-is (S3 / CloudFront public files)
  /// - `uploads/...`        → `{SERVER_URL}/{value}`
  static String buildImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.trim().isEmpty) return "";
    final path = relativePath.replaceAll(r'\', '/').trim();
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return "$mainDomain/$clean";
  }

  static String fileUrl(String? value) => buildImageUrl(value);

  /// Private files (`uploads/private/...`) need the Authorization header.
  static bool isPrivateFile(String? value) =>
      (value ?? '').replaceAll(r'\', '/').contains('uploads/private/');

  /// Headers to use with Image.network / downloads for a file value.
  static Map<String, String>? fileHeaders(String? value) {
    if (!isPrivateFile(value)) return null;
    final token = SharePrefsHelper.getToken();
    if (token == null || token.isEmpty) return null;
    return {"Authorization": "Bearer $token"};
  }

  // ============================ Auth ==============================
  static const userLogin = "$baseUrl/auth/login";
  static const userRegister = "$baseUrl/user/register";
  static const changePassword = "$baseUrl/auth/change-password";
  static const verifyEmailOtp = "$baseUrl/auth/verify-email-otp";
  static const resendOtp = "$baseUrl/auth/resend-otp";
  static const forgetPassword = "$baseUrl/auth/forgot-password";
  static const verifyOtp = "$baseUrl/auth/verify-otp";
  static const resetPassword = "$baseUrl/auth/reset-password";
  static const refreshToken = "$baseUrl/auth/refresh-token";
  static const logout = "$baseUrl/auth/logout";
  static const deleteAccount = "$baseUrl/auth/delete-me";

  // ============================ User ==============================
  static const getMe = "$baseUrl/user/getMe";
  static const updateMyProfile = "$baseUrl/user/updateMe";
  static const settings = "$baseUrl/user/settings";
  static const exportMyData = "$baseUrl/user/export-my-data";

  /// Kept for older screens – both now point to getMe.
  static const getUserProfile = getMe;
  static const getProviderProfile = getMe;

  // ============================ Patient home ======================
  static const patientHome = "$baseUrl/normal-User/home";
  static const healthCard = "$baseUrl/normal-User/health-card";

  // ============================ Provider directory ================
  static const providerType = "$baseUrl/provider-types";
  static String adminCreateService(String typeKey) =>
      "$baseUrl/service/admin-service/$typeKey";
  static const getAllProvider = "$baseUrl/provider/all-providers";
  static String getProviderById(String providerTypeID) =>
      "$baseUrl/provider/all-providers?providerTypeId=$providerTypeID";
  static String getSingleProviderById(String profileID) =>
      "$baseUrl/provider/$profileID";
  static String getProviderAvailability(String profileId) =>
      "$baseUrl/availability-day/provider-availability/$profileId";

  // ============================ Favorites =========================
  static String createFavorite(String id) => "$baseUrl/favorite/$id";
  static String removeFavorite(String id) => "$baseUrl/favorite/$id";
  static const getAllFavorite = "$baseUrl/favorite/my-favorites";

  // ============================ Appointments ======================
  static const createAppointment = "$baseUrl/appointment/create-appointment";
  static const myAppointment = "$baseUrl/appointment/my-appointments";
  static String myAppointmentDetails(String id) =>
      "$baseUrl/appointment/my-appointments/$id";
  static String appointmentCalendar(String id) =>
      "$baseUrl/appointment/my-appointments/$id/calendar.ics";
  static String cancelAppointment(String id) =>
      "$baseUrl/appointment/cancel/$id";
  static const providerAppointment =
      "$baseUrl/appointment/provider-appointments";
  static String providerAppointmentDetails(String id) =>
      "$baseUrl/appointment/provider-appointments/$id";
  static String providerUpdateStatus(String id) =>
      "$baseUrl/appointment/provider-update-status/$id";

  // ============================ Reminders =========================
  static const createReminder = "$baseUrl/reminder/create-reminder";
  static const myReminder = "$baseUrl/reminder/my-reminders";
  static String updateReminder(String id) =>
      "$baseUrl/reminder/update-reminder/$id";
  static String deleteReminder(String id) =>
      "$baseUrl/reminder/delete-reminder/$id";
  static const todayDoses = "$baseUrl/reminder/today";
  static String recordIntake(String reminderId) =>
      "$baseUrl/reminder/$reminderId/intake";
  static const adherence = "$baseUrl/reminder/adherence";

  // ============================ Health logs =======================
  static const healthLogs = "$baseUrl/healthLog";
  static const postHealthLog = "$baseUrl/healthLog/create";
  static const healthLogTrends = "$baseUrl/healthLog/trends";
  static String healthLog(String id) => "$baseUrl/healthLog/$id";

  // ============================ Insurance =========================
  static const insurances = "$baseUrl/insurance";
  static const postInsurance = "$baseUrl/insurance/create";
  static String insurance(String id) => "$baseUrl/insurance/$id";

  // ============================ Medical documents =================
  static const uploadDocument = "$baseUrl/medicalDocument";
  static const myDocuments = "$baseUrl/medicalDocument/my";
  static const myDocumentTags = "$baseUrl/medicalDocument/my/tags";
  static String myDocument(String id) => "$baseUrl/medicalDocument/my/$id";
  static String document(String id) => "$baseUrl/medicalDocument/$id";
  static String shareDocument(String id) =>
      "$baseUrl/medicalDocument/$id/share";

  // ============================ SOS ===============================
  static const emergencyInfo = "$baseUrl/sos/emergency-info";
  static const sos = "$baseUrl/sos";
  static const mySos = "$baseUrl/sos/my";
  static String sosLocation(String id) => "$baseUrl/sos/$id/location";
  static String sosCancel(String id) => "$baseUrl/sos/$id/cancel";

  // ============================ Support chat ======================
  static const supportConversation = "$baseUrl/support/my-conversation";
  static const supportMessages = "$baseUrl/support/messages";

  // ============================ Notifications =====================
  static const getAllNotification = "$baseUrl/notification/get-notifications";
  static const unreadCount = "$baseUrl/notification/unread-count";
  static String readNotification(String id) =>
      "$baseUrl/notification/read/$id";
  static const readAllNotifications = "$baseUrl/notification/see-notifications";
  static String removeNotification(String id) =>
      "$baseUrl/notification/delete-notification/$id";

  // ============================ Provider: services ================
  static const createService = "$baseUrl/service/create-service";
  static const myCreateService = "$baseUrl/service/my-created-service";
  static String serviceUpdate(String id) =>
      "$baseUrl/service/update-service/$id";
  static String serviceDelete(String id) =>
      "$baseUrl/service/delete-service/$id";

  // ============================ Provider: availability ============
  static const createAvailabilityDay =
      "$baseUrl/availability-day/create-availability-day";
  static const myAvailabilityDays =
      "$baseUrl/availability-day/my-availability-days";
  static String deleteAvailabilityDay(String dayId) =>
      "$baseUrl/availability-day/$dayId";
  static const createAvailabilitySlot =
      "$baseUrl/availability-slot/create-availability-slot";
  static String deleteAvailabilitySlot(String slotId) =>
      "$baseUrl/availability-slot/delete-availability-slot/$slotId";

  // ============================ Content ===========================
  static const getAllArticle = "$baseUrl/article";
  static String getSingeArticle(String id) => "$baseUrl/article/$id";
  static const getFag = "$baseUrl/manage-web/get-faq";
  static const getAboutUs = "$baseUrl/manage-web/get-about-us";
  static const getTermsAndCondition =
      "$baseUrl/manage-web/get-terms-conditions";
  static const privacyPolicy = "$baseUrl/manage-web/get-privacy-policy";
}
