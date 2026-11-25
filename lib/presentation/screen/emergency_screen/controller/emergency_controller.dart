import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/app_models.dart';
import '../../../../data/models/json.dart';
import '../../../../data/models/user_models.dart';
import '../../../../helper/local_db/local_db.dart';
import '../../../../helper/tost_message/show_snackbar.dart';
import '../../../../service/api_service.dart';
import '../../../../service/api_url.dart';
import '../../home/controller/home_controller.dart';

/// SOS: emergency info (cached offline), trigger, live location, cancel.
class EmergencyController extends GetxController {
  final _api = ApiClient();

  final info = Rx<EmergencyInfo>(EmergencyInfo.fallback());
  final active = Rxn<SosAlertModel>();
  final mapsLink = RxnString();
  final shareMessage = RxnString();
  final isSending = false.obs;
  final isLoading = false.obs;
  final lastLocationAt = Rxn<DateTime>();
  final history = <SosAlertModel>[].obs;
  final messageController = TextEditingController();

  Timer? _liveTimer;

  @override
  void onInit() {
    super.onInit();
    _loadCached();
    loadInfo();
    _checkActive();
  }

  void _loadCached() {
    final raw = SharePrefsHelper.getEmergencyJson();
    if (raw == null) return;
    try {
      info.value = EmergencyInfo.fromJson(J.map(jsonDecode(raw)));
    } catch (_) {}
  }

  Future<void> loadInfo() async {
    isLoading.value = true;
    final res = await _api.get(url: ApiUrl.emergencyInfo);
    isLoading.value = false;
    if (res.isOk && res.data is Map) {
      info.value = EmergencyInfo.fromJson(J.map(res.data));
      SharePrefsHelper.saveEmergencyJson(jsonEncode(res.data));
    }
  }

  Future<void> _checkActive() async {
    final res = await _api.get(url: ApiUrl.mySos);
    if (!res.isOk) return;
    final list = Paged.parse(res.data, SosAlertModel.fromJson).items;
    history.assignAll(list);
    final a = list.firstWhereOrNull((e) => e.status == 'ACTIVE');
    if (a != null) {
      active.value = a;
      if (a.latitude != null) mapsLink.value = "https://maps.google.com/?q=${a.latitude},${a.longitude}";
      _startLive();
    }
  }

  Future<void> loadHistory() async {
    final res = await _api.get(url: ApiUrl.mySos);
    if (res.isOk) history.assignAll(Paged.parse(res.data, SosAlertModel.fromJson).items);
  }

  Future<Position?> _position() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 12));
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// POST /sos (pressing again while active updates the same alert)
  Future<void> triggerSos() async {
    isSending.value = true;
    final pos = await _position();
    final body = <String, dynamic>{
      if (pos != null) ...{
        "latitude": pos.latitude,
        "longitude": pos.longitude,
        "accuracy": pos.accuracy,
      },
      if (messageController.text.trim().isNotEmpty) "message": messageController.text.trim(),
    };
    final res = await _api.post(url: ApiUrl.sos, body: body);
    isSending.value = false;

    if (res.isOk && res.data is Map) {
      final d = J.map(res.data);
      active.value = SosAlertModel.fromJson(J.map(d['alert']));
      mapsLink.value = J.str(d['mapsLink']);
      shareMessage.value = J.str(d['shareMessage']);
      if (d['emergencyNumbers'] is List || d['emergencyContacts'] is List) {
        info.value = EmergencyInfo(
          numbers: d['emergencyNumbers'] is List
              ? J.list(d['emergencyNumbers'], EmergencyNumber.fromJson)
              : info.value.numbers,
          contacts: d['emergencyContacts'] is List
              ? J.list(d['emergencyContacts'], EmergencyContact.fromJson)
              : info.value.contacts,
          bloodGroup: info.value.bloodGroup,
          allergies: info.value.allergies,
          chronicConditions: info.value.chronicConditions,
        );
      }
      lastLocationAt.value = pos != null ? DateTime.now() : null;
      AppSnackBar.success(pos == null
          ? "SOS sent. Location unavailable – turn on GPS for live location."
          : "SOS sent. Support team has been alerted.");
      _startLive();
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().loadDashboard();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  void _startLive() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pushLocation());
  }

  /// PATCH /sos/:id/location
  Future<void> _pushLocation() async {
    final a = active.value;
    if (a == null) return _liveTimer?.cancel();
    final pos = await _position();
    if (pos == null) return;
    final res = await _api.patch(url: ApiUrl.sosLocation(a.id), body: {
      "latitude": pos.latitude,
      "longitude": pos.longitude,
      "accuracy": pos.accuracy,
    });
    if (res.isOk) {
      lastLocationAt.value = DateTime.now();
      mapsLink.value = "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
    } else if (res.statusCode == 404) {
      // closed by support (RESOLVED) or already cancelled
      _liveTimer?.cancel();
      active.value = null;
      AppSnackBar.info("Your SOS alert was closed.");
      loadHistory();
    }
  }

  /// PATCH /sos/:id/cancel
  Future<void> cancelSos() async {
    final a = active.value;
    if (a == null) return;
    isSending.value = true;
    final res = await _api.patch(url: ApiUrl.sosCancel(a.id));
    isSending.value = false;
    if (res.isOk || res.statusCode == 404) {
      _liveTimer?.cancel();
      active.value = null;
      shareMessage.value = null;
      AppSnackBar.success("SOS cancelled");
      loadHistory();
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().loadDashboard();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  String get _text =>
      shareMessage.value ?? "SOS! I need help.${mapsLink.value != null ? ' Location: ${mapsLink.value}' : ''}";

  Future<void> call(String number) => launchUrl(Uri.parse('tel:$number'));

  Future<void> smsContact(EmergencyContact c) async {
    final uri = Uri(scheme: 'sms', path: c.phone, queryParameters: {'body': _text});
    if (!await launchUrl(uri)) await shareToContacts();
  }

  Future<void> smsAllContacts() async {
    final phones = info.value.contacts.map((e) => e.phone).where((p) => p.isNotEmpty).join(',');
    if (phones.isEmpty) return shareToContacts();
    final uri = Uri(scheme: 'sms', path: phones, queryParameters: {'body': _text});
    if (!await launchUrl(uri)) await shareToContacts();
  }

  Future<void> shareToContacts() => SharePlus.instance.share(ShareParams(text: _text));

  @override
  void onClose() {
    _liveTimer?.cancel();
    messageController.dispose();
    super.onClose();
  }
}
