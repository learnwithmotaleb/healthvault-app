import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/json.dart';
import '../../../../../data/models/user_models.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';

/// GET /normal-User/health-card
class HealthCardController extends GetxController {
  final card = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;
  final error = RxnString();
  Uint8List? qr;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    final res = await ApiClient().get(url: ApiUrl.healthCard);
    isLoading.value = false;
    if (res.isOk && res.data is Map) {
      final d = J.map(res.data);
      final q = J.str(d['qrCode']);
      if (q != null && q.contains(',')) {
        try {
          qr = base64Decode(q.split(',').last);
        } catch (_) {
          qr = null;
        }
      }
      card.value = d;
    } else {
      error.value = res.message;
    }
  }
}

class HealthCardScreen extends StatelessWidget {
  const HealthCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HealthCardController());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.healthCardID.tr),
      body: Obx(() {
        if (c.isLoading.value && c.card.value == null) return const Center(child: CircularProgressIndicator());
        final d = c.card.value;
        if (d == null) return ErrorView(message: c.error.value ?? 'Error'.tr, onRetry: c.load);
        final ins = d['insurance'] is Map ? J.map(d['insurance']) : null;
        final contacts = J.list(d['emergencyContacts'], EmergencyContact.fromJson);
        final allergies = J.strings(d['allergies']);
        final chronic = J.strings(d['chronicConditions']);
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.providerHomePageColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: AppColors.primaryColor.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.health_and_safety, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('HEALTH VAULT', style: AppTextStyles.body.copyWith(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (J.str(d['bloodGroup']) != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text("🩸 ${d['bloodGroup']}",
                          style: AppTextStyles.body.copyWith(color: AppColors.emergencyColor, fontWeight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Avatar(image: J.str(d['profile_image']), name: J.s(d['name']), radius: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(J.s(d['name']), style: AppTextStyles.title.copyWith(color: Colors.white)),
                      Text("ID: ${J.s(d['membershipId'])}", style: AppTextStyles.body.copyWith(color: Colors.white)),
                      Text(
                        [
                          if (J.date(d['dateOfBirth']) != null) Fmt.date(J.date(d['dateOfBirth'])),
                          if (J.str(d['gender']) != null) Fmt.enumLabel(J.s(d['gender'])).tr,
                        ].join(' · '),
                        style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 12),
                      ),
                      if (J.str(d['phone']) != null)
                        Text(J.s(d['phone']), style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            if (c.qr != null)
              Center(
                child: HVCardBox(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Image.memory(c.qr!, width: 200, height: 200, gaplessPlayback: true),
                    const SizedBox(height: 4),
                    Text('Show this QR to a doctor or paramedic'.tr,
                        style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                  ]),
                ),
              ),
            SectionTitle('Medical info'.tr),
            HVCardBox(
              child: Column(children: [
                KeyValueRow('Allergies'.tr, allergies.join(', ')),
                KeyValueRow('Chronic conditions'.tr, chronic.join(', ')),
              ]),
            ),
            if (ins != null) ...[
              SectionTitle('Insurance'.tr),
              HVCardBox(
                child: Column(children: [
                  KeyValueRow('Plan'.tr, J.s(ins['name'])),
                  KeyValueRow('Company'.tr, J.s(ins['insuranceProvider'])),
                  KeyValueRow('Policy number'.tr, J.s(ins['number'])),
                  KeyValueRow('Expiry date'.tr, Fmt.date(J.date(ins['expiryDate']))),
                ]),
              ),
            ],
            if (contacts.isNotEmpty) ...[
              SectionTitle('Emergency contacts'.tr),
              ...contacts.map((e) => HVCardBox(
                    child: Row(children: [
                      const Icon(Icons.contact_phone_outlined, color: AppColors.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text("${e.name}${(e.relation ?? '').isNotEmpty ? ' (${e.relation})' : ''}", style: AppTextStyles.body),
                      ),
                      Text(e.phone, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    ]),
                  )),
            ],
            const SizedBox(height: 24),
          ]),
        );
      }),
    );
  }
}
