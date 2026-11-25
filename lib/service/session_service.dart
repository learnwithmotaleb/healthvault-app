import 'dart:convert';

import 'package:get/get.dart';

import '../core/routes/route_path.dart';
import '../data/models/user_models.dart';
import '../global/language/controller/language_controller.dart';
import '../helper/local_db/local_db.dart';
import '../helper/tost_message/show_snackbar.dart';
import 'api_service.dart';
import 'api_url.dart';
import 'socket_service.dart';

/// Holds the logged-in account and handles token storage, login state,
/// logout and role-based navigation.
class SessionService {
  SessionService._();

  static final Rx<AccountModel?> account = Rx<AccountModel?>(_loadCached());
  static bool _loggingOut = false;

  static AccountModel? _loadCached() {
    final raw = SharePrefsHelper.getUserJson();
    if (raw == null || raw.isEmpty) return null;
    try {
      return AccountModel.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }

  static bool get isLoggedIn => (SharePrefsHelper.getToken() ?? '').isNotEmpty;
  static String get role => (SharePrefsHelper.getRole() ?? '').toUpperCase();
  static bool get isProvider => role == 'PROVIDER';
  static bool get isPatient => role == 'NORMALUSER';
  static String? get userId => SharePrefsHelper.getUserId();
  static String? get profileId => SharePrefsHelper.getProfileId();

  /// Push device id (OneSignal) if the app has one.
  static String? get playerId {
    final id = SharePrefsHelper.getPlayerId();
    return (id == null || id.isEmpty) ? null : id;
  }

  /// Save the `data` of login / verify-email-otp / reset / change-password.
  static Future<void> saveAuth(Map<String, dynamic> data) async {
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is String && access.isNotEmpty) await SharePrefsHelper.saveToken(access);
    if (refresh is String && refresh.isNotEmpty) await SharePrefsHelper.saveRefreshToken(refresh);

    final jwt = data['jwtPayload'] is Map ? Map<String, dynamic>.from(data['jwtPayload']) : <String, dynamic>{};
    final user = data['user'] is Map ? Map<String, dynamic>.from(data['user']) : null;

    final role = (jwt['role'] ?? user?['role'])?.toString().toUpperCase();
    final id = (jwt['id'] ?? user?['_id'])?.toString();
    final profileId = (jwt['profileId'] ?? user?['profileId'] ?? (user?['profile'] is Map ? user!['profile']['_id'] : null))?.toString();

    if (role != null && role.isNotEmpty) await SharePrefsHelper.saveRole(role);
    if (id != null && id.isNotEmpty) await SharePrefsHelper.saveUserId(id);
    if (profileId != null && profileId.isNotEmpty) await SharePrefsHelper.saveProfileId(profileId);

    if (user != null) await _setAccount(user);
    RealtimeService.to.connect();
  }

  static Future<void> _setAccount(Map<String, dynamic> user) async {
    await SharePrefsHelper.saveUserJson(jsonEncode(user));
    final acc = AccountModel.fromJson(user);
    account.value = acc;
    if (acc.role.isNotEmpty) await SharePrefsHelper.saveRole(acc.role);
    if (acc.id.isNotEmpty) await SharePrefsHelper.saveUserId(acc.id);
    if ((acc.profileId ?? '').isNotEmpty) await SharePrefsHelper.saveProfileId(acc.profileId!);
    _syncLanguage(acc.language);
  }

  static void _syncLanguage(String lang) {
    if (!Get.isRegistered<LanguageController>()) return;
    final lc = Get.find<LanguageController>();
    final english = lang != 'el';
    if (lc.isEnglish.value != english) lc.switchLanguage(english, syncServer: false);
  }

  /// GET /user/getMe – refresh the cached account.
  static Future<AccountModel?> refreshMe() async {
    final res = await ApiClient().get(url: ApiUrl.getMe);
    if (res.isOk && res.data is Map) {
      await _setAccount(Map<String, dynamic>.from(res.data));
    }
    return account.value;
  }

  static void goHome() {
    if (isProvider) {
      Get.offAllNamed(RoutePath.providerNav);
    } else {
      Get.offAllNamed(RoutePath.bottomNav);
    }
  }

  /// User-initiated logout: tells the server to unlink the push device.
  static Future<void> logout() async {
    try {
      await ApiClient().post(url: ApiUrl.logout, body: {if (playerId != null) "playerId": playerId});
    } catch (_) {}
    await _clear();
    AppSnackBar.success("Logged out successfully");
    Get.offAllNamed(RoutePath.login);
  }

  /// Session invalid (refresh failed / blocked / account deleted).
  static Future<void> forceLogout({String? message}) async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      await _clear();
      if (message != null) AppSnackBar.fail(message);
      Get.offAllNamed(RoutePath.login);
    } finally {
      Future.delayed(const Duration(seconds: 2), () => _loggingOut = false);
    }
  }

  static Future<void> _clear() async {
    RealtimeService.to.disconnect();
    await SharePrefsHelper.clearSession();
    account.value = null;
  }

  static void onTokenRefreshed() => RealtimeService.to.reconnect();
}
