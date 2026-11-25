import 'package:flutter/material.dart';
import 'package:healthvault/helper/local_db/shareprefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharePrefsHelper {
  static SharedPreferences? _prefs;

  // Initialize once in main()
  static Future init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ----------------- General Setters -----------------

  static Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  // ----------------- Theme Mode -----------------

  static const String _themeKey = 'theme_mode';

  static ThemeMode getThemeMode() {
    switch (_prefs?.getString(_themeKey)) {
      case 'light': return ThemeMode.light;
      case 'dark':  return ThemeMode.dark;
      default:      return ThemeMode.system;
    }
  }


  static Future<void> saveThemeMode(ThemeMode mode) async {
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';

    await _prefs?.setString(_themeKey, value);
  }

  // ----------------- Role -----------------

  static Future<void> saveRole(String value) async {
    await _prefs?.setString(SharePrefsKeys.role, value);
  }

  static String? getRole() {
    return _prefs?.getString(SharePrefsKeys.role);
  }

  // ----------------- Token -----------------

  static Future<void> saveToken(String token) async {
    await _prefs?.setString(SharePrefsKeys.token, token);
  }

  static String? getToken() {
    return _prefs?.getString(SharePrefsKeys.token);
  }

  // ----------------- User ID -----------------

  static Future<void> saveUserId(String id) async {
    await _prefs?.setString(SharePrefsKeys.userId, id);
  }

  static String? getUserId() {
    return _prefs?.getString(SharePrefsKeys.userId);
  }




  // ----------------- Profile ID -----------------

  static Future<void> saveProfileId(String profileId) async {
    await _prefs?.setString(SharePrefsKeys.profileId, profileId);
  }

  static String? getProfileId() {
    return _prefs?.getString(SharePrefsKeys.profileId);
  }

  // ----------------- Onboard Seen -----------------

  static Future<void> setOnboardSeen(bool value) async {
    await _prefs?.setBool(SharePrefsKeys.onboardSeen, value);
  }

  static bool getOnboardSeen() {
    return _prefs?.getBool(SharePrefsKeys.onboardSeen) ?? false;
  }


  // ----------------- Refresh Token -----------------
  static Future<void> saveRefreshToken(String token) async {
    await _prefs?.setString(SharePrefsKeys.refreshToken, token);
  }

  static String? getRefreshToken() {
    return _prefs?.getString(SharePrefsKeys.refreshToken);
  }







  // ----------------- Cached user (getMe / login user) -----------------
  static Future<void> saveUserJson(String json) async {
    await _prefs?.setString(SharePrefsKeys.userJson, json);
  }

  static String? getUserJson() => _prefs?.getString(SharePrefsKeys.userJson);

  // ----------------- Emergency info (offline cache) -----------------
  static Future<void> saveEmergencyJson(String json) async {
    await _prefs?.setString(SharePrefsKeys.emergencyJson, json);
  }

  static String? getEmergencyJson() => _prefs?.getString(SharePrefsKeys.emergencyJson);

  // ----------------- Push device id (OneSignal) -----------------
  static Future<void> savePlayerId(String id) async {
    await _prefs?.setString(SharePrefsKeys.playerId, id);
  }

  static String? getPlayerId() => _prefs?.getString(SharePrefsKeys.playerId);

  // ----------------- Clear session only -----------------
  /// Removes tokens and user data but keeps language, theme, onboarding
  /// and the device push id.
  static Future<void> clearSession() async {
    for (final k in [
      SharePrefsKeys.token,
      SharePrefsKeys.refreshToken,
      SharePrefsKeys.role,
      SharePrefsKeys.userId,
      SharePrefsKeys.profileId,
      SharePrefsKeys.userJson,
      SharePrefsKeys.emergencyJson,
      'role',
    ]) {
      await _prefs?.remove(k);
    }
  }

  // ----------------- Clear All -----------------
  /// Kept for older callers – now only clears the session.
  static Future<void> clearAll() => clearSession();
}
