import 'package:get/get.dart';

import '../../global/language/controller/language_controller.dart';
import '../../presentation/screen/appointment/screen/appointment_details_screen.dart';
import '../../presentation/screen/appointment/screen/appointment_screen.dart';
import '../../presentation/screen/bottom_navigationbar/screen/bottom_navigation_screen.dart';
import '../../presentation/screen/category_screen/info_provider_details/screen/book_appointment_screen.dart';
import '../../presentation/screen/category_screen/info_provider_details/screen/info_provider_details_screen.dart';
import '../../presentation/screen/category_screen/search/screen/search_screen.dart';
import '../../presentation/screen/content/content_screens.dart';
import '../../presentation/screen/emergency_screen/screen/emergency_screen.dart';
import '../../presentation/screen/home/screen/home_screen.dart';
import '../../presentation/screen/language/screen/language_screen.dart';
import '../../presentation/screen/onboarding/controller/onboarding_controller.dart';
import '../../presentation/screen/onboarding/screen/onboarding_screen.dart';
import '../../presentation/screen/profile/account_setting_profile/screen/acccount_setting_screen.dart';
import '../../presentation/screen/profile/change_password/controller/change_password_controller.dart';
import '../../presentation/screen/profile/change_password/screen/change_password_screen.dart';
import '../../presentation/screen/profile/document_profile/screen/document_details_screen.dart';
import '../../presentation/screen/profile/document_profile/screen/document_profile_screen.dart';
import '../../presentation/screen/profile/document_profile/screen/upload_document_screen.dart';
import '../../presentation/screen/profile/edit_profile/screen/edit_profile_screen.dart';
import '../../presentation/screen/profile/favourite_profile/screen/favourite_screen.dart';
import '../../presentation/screen/profile/health_card_profile/screen/health_card_screen.dart';
import '../../presentation/screen/profile/health_log_profile/screen/add_health_log_screen.dart';
import '../../presentation/screen/profile/health_log_profile/screen/health_log_screen.dart';
import '../../presentation/screen/profile/health_log_profile/screen/health_trends_screen.dart';
import '../../presentation/screen/profile/insurance_profile/screen/add_insurance_screen.dart';
import '../../presentation/screen/profile/insurance_profile/screen/insurance_screen.dart';
import '../../presentation/screen/profile/language_profile/controller/language_profile_controller.dart';
import '../../presentation/screen/profile/language_profile/screen/language_profile_screen.dart';
import '../../presentation/screen/profile/notification_profile/screen/notification_screen.dart';
import '../../presentation/screen/profile/profile/screen/profile_screen.dart';
import '../../presentation/screen/provider/doctor_identification/controller/doctor_indentification_controller.dart';
import '../../presentation/screen/provider/doctor_identification/screen/doctor_identification_screen.dart';
import '../../presentation/screen/provider/medical_license/controller/medical_license_controller.dart';
import '../../presentation/screen/provider/medical_license/screen/medical_license_screen.dart';
import '../../presentation/screen/provider/passport_identification/screen/passport_identification_screen.dart';
import '../../presentation/screen/provider/pharmacy_identification/controller/pharmacy_identification_controller.dart';
import '../../presentation/screen/provider/pharmacy_identification/screen/pharmacy_identification_screen.dart';
import '../../presentation/screen/provider/provider_bottom_nav/screen/provider_bottom_nav_screen.dart';
import '../../presentation/screen/provider/provider_edit_schedule/screen/provider_edit_schedule_screen.dart';
import '../../presentation/screen/provider/provider_home/screen/provider_home_screen.dart';
import '../../presentation/screen/provider/provider_profile/screen/provider_profile_screen.dart';
import '../../presentation/screen/provider/provider_service/screen/provider_service_screen.dart';
import '../../presentation/screen/provider/provider_task/screen/provider_task_screen.dart';
import '../../presentation/screen/provider/select_provider/controller/provider_selection_controller.dart';
import '../../presentation/screen/provider/select_provider/screen/provider_selection_screen.dart';
import '../../presentation/screen/reminder/add_medicine/screen/reminder_form_screen.dart';
import '../../presentation/screen/reminder/select_reminder/screen/select_reminder_screen.dart';
import '../../presentation/screen/reminder/today/adherence_screen.dart';
import '../../presentation/screen/reminder/today/today_doses_screen.dart';
import '../../presentation/screen/select/controller/select_controller.dart';
import '../../presentation/screen/select/screen/select_screen.dart';
import '../../presentation/screen/splash/controller/splash_controller.dart';
import '../../presentation/screen/splash/screen/splash_screen.dart';
import '../../presentation/screen/support/support_chat_screen.dart';
import '../../presentation/screen/user/auth/Identification/controller/identification_controller.dart';
import '../../presentation/screen/user/auth/Identification/screen/identification_screen.dart';
import '../../presentation/screen/user/auth/forget/controller/forget_controller.dart';
import '../../presentation/screen/user/auth/forget/screen/forget_screen.dart';
import '../../presentation/screen/user/auth/login/controller/login_controller.dart';
import '../../presentation/screen/user/auth/login/screen/login_screen.dart';
import '../../presentation/screen/user/auth/registaration/controller/registration_controller.dart';
import '../../presentation/screen/user/auth/registaration/screen/registration_screen.dart';
import '../../presentation/screen/user/auth/reset/controller/reset_controller.dart';
import '../../presentation/screen/user/auth/reset/screen/reset_screen.dart';
import '../../presentation/screen/user/auth/signup/controller/signup_controller.dart';
import '../../presentation/screen/user/auth/signup/screen/signup_screen.dart';
import '../../presentation/screen/user/auth/verification/controller/vefication_controller.dart';
import '../../presentation/screen/user/auth/verification/screen/verification_screen.dart';
import '../../presentation/screen/user/auth/verify/controller/verify_controller.dart';
import '../../presentation/screen/user/auth/verify/screen/verify_screen.dart';
import '../../presentation/screen/category_screen/info_provider_details/controller/info_provider_details_controller.dart';
import 'route_path.dart';

GetPage<dynamic> _page(String name, GetPageBuilder page, [dynamic Function()? bind]) => GetPage(
      name: name,
      page: page,
      transition: Transition.cupertino,
      binding: bind == null ? null : BindingsBuilder(() => bind()),
    );

class AppRouter {
  static final List<GetPage<dynamic>> pages = [
    // ---------------------------------------------------------------- onboarding & auth
    _page(RoutePath.splash, () => const SplashScreen(), () => Get.put(SplashController())),
    _page(RoutePath.onboard, () => OnBoardingScreen(), () => Get.put(OnBoardingController())),
    _page(RoutePath.languages, () => LanguageScreen(), () => Get.put(LanguageController())),
    _page(RoutePath.select, () => SelectScreen(), () => Get.put(SelectController())),
    _page(RoutePath.login, () => LoginScreen(), () => Get.put(LoginController())),
    _page(RoutePath.signup, () => SignupScreen(), () => Get.isRegistered<SignupController>() ? null : Get.put(SignupController(), permanent: true)),
    _page(RoutePath.verification, () => VerificationScreen(), () => Get.put(VerificationController())),
    _page(RoutePath.forget, () => ForgetScreen(), () => Get.put(ForgetController())),
    _page(RoutePath.verify, () => VerifyScreen(), () => Get.put(VerifyController())),
    _page(RoutePath.reset, () => ResetScreen(), () => Get.put(ResetController())),
    _page(RoutePath.registration, () => RegistrationScreen(), () => Get.isRegistered<RegistrationController>() ? null : Get.put(RegistrationController(), permanent: true)),
    _page(RoutePath.identification, () => IdentificationScreen(), () => Get.isRegistered<IdentificationController>() ? null : Get.put(IdentificationController(), permanent: true)),
    _page(RoutePath.providerSelection, () => ProviderSelectionScreen(), () => Get.put(ProviderSelectionController())),
    _page(RoutePath.doctorIdentification, () => DoctorIdentificationScreen(), () {
      final args = Get.arguments;
      if (!Get.isRegistered<DoctorIdentificationController>()) {
        Get.put(DoctorIdentificationController(args is Map ? (args["providerLabel"] ?? "").toString() : ""), permanent: true);
      }
    }),
    _page(RoutePath.pharmacyIdentification, () => PharmacyIdentificationScreen(), () => Get.isRegistered<PharmacyIdentificationController>() ? null : Get.put(PharmacyIdentificationController(), permanent: true)),
    _page(RoutePath.medicalLicense, () => MedicalLicenseScreen(), () => Get.isRegistered<MedicalLicenseController>() ? null : Get.put(MedicalLicenseController(), permanent: true)),
    _page(RoutePath.passportPhoto, () => PassportIdentificationScreen()),

    // ---------------------------------------------------------------- patient shell
    _page(RoutePath.bottomNav, () => const BottomNavigationScreen()),
    _page(RoutePath.home, () => const HomeScreen()),
    _page(RoutePath.appointment, () => const AppointmentScreen()),
    _page(RoutePath.appointmentDetails, () => const AppointmentDetailsScreen()),
    _page(RoutePath.profile, () => const ProfileScreen()),

    // directory & booking
    _page(RoutePath.search, () => const SearchScreen()),
    _page(RoutePath.doctor, () => const SearchScreen()),
    _page(RoutePath.pharmacy, () => const SearchScreen()),
    _page(RoutePath.clinic, () => const SearchScreen()),
    _page(RoutePath.diagnostic, () => const SearchScreen()),
    _page(RoutePath.plastic, () => const SearchScreen()),
    _page(RoutePath.medicalTourism, () => const SearchScreen()),
    _page(RoutePath.inVitoFertilization, () => const SearchScreen()),
    _page(RoutePath.wellness, () => const SearchScreen()),
    _page(RoutePath.infoProviderDetails, () => const InfoProviderDetailsScreen()),
    _page(RoutePath.providerDetails, () => const InfoProviderDetailsScreen()),
    _page(RoutePath.details, () => const AppointmentDetailsScreen()),
    _page(RoutePath.bookAppointment, () => const BookAppointmentScreen(), () {
      if (!Get.isRegistered<InfoProviderDetailsController>()) Get.put(InfoProviderDetailsController());
    }),
    _page(RoutePath.favourite, () => const FavouriteScreen()),

    // reminders
    _page(RoutePath.selectReminder, () => const SelectReminderScreen()),
    _page(RoutePath.addReminder, () => const ReminderFormScreen()),
    _page(RoutePath.editReminder, () => const ReminderFormScreen()),
    _page(RoutePath.todayDoses, () => const TodayDosesScreen()),
    _page(RoutePath.adherence, () => const AdherenceScreen()),

    // health records
    _page(RoutePath.healthCard, () => const HealthCardScreen()),
    _page(RoutePath.healthLog, () => const HealthLogScreen()),
    _page(RoutePath.healthLogMySelf, () => const HealthLogScreen()),
    _page(RoutePath.healthLogFamily, () => const HealthLogScreen()),
    _page(RoutePath.addHealthLog, () => const AddHealthLogScreen()),
    _page(RoutePath.healthTrends, () => const HealthTrendsScreen()),
    _page(RoutePath.insurance, () => const InsuranceScreen()),
    _page(RoutePath.insuranceMySelf, () => const InsuranceScreen()),
    _page(RoutePath.insuranceFamily, () => const InsuranceScreen()),
    _page(RoutePath.addInsurance, () => const AddInsuranceScreen()),
    _page(RoutePath.document, () => const DocumentProfileScreen()),
    _page(RoutePath.addDocument, () => const DocumentProfileScreen()),
    _page(RoutePath.familyDocument, () => const DocumentProfileScreen()),
    _page(RoutePath.uploadDocument, () => const UploadDocumentScreen()),
    _page(RoutePath.documentDetails, () => const DocumentDetailsScreen()),

    // emergency & support
    _page(RoutePath.emergency, () => const EmergencyScreen()),
    _page(RoutePath.sosHistory, () => const SosHistoryScreen()),
    _page(RoutePath.supportChat, () => const SupportChatScreen()),
    _page(RoutePath.notification, () => const NotificationScreen()),

    // account
    _page(RoutePath.editProfile, () => const EditProfileScreen()),
    _page(RoutePath.accountSetting, () => const AccountSettingScreen()),
    _page(RoutePath.notificationSettings, () => const NotificationSettingsScreen()),
    _page(RoutePath.changePassword, () => ChangePasswordScreen(), () => Get.put(ChangePasswordController())),
    _page(RoutePath.changeLanguageProfile, () => LanguageProfileScreen(), () => Get.put(LanguageProfileController())),

    // content
    _page(RoutePath.healthArticle, () => const ArticleListScreen()),
    _page(RoutePath.healthDetail, () => const ArticleDetailsScreen()),
    _page(RoutePath.termsAndCondition, () => const TermsScreen()),
    _page(RoutePath.policy, () => const PrivacyScreen()),
    _page(RoutePath.aboutUs, () => const AboutUsScreen()),
    _page(RoutePath.faq, () => const FaqScreen()),

    // ---------------------------------------------------------------- provider
    _page(RoutePath.providerNav, () => const ProviderBottomNavScreen()),
    _page(RoutePath.providerHome, () => const ProviderHomeScreen()),
    _page(RoutePath.providerTask, () => const ProviderTaskScreen()),
    _page(RoutePath.providerProfile, () => const ProviderProfileScreen()),
    _page(RoutePath.providerService, () => const ProviderServiceScreen()),
    _page(RoutePath.providerSchedule, () => const ProviderEditScheduleScreen()),
    _page(RoutePath.providerAppointmentDetails, () => const AppointmentDetailsScreen()),
    _page(RoutePath.appalmentDocument, () => const AppointmentDetailsScreen()),
  ];
}
