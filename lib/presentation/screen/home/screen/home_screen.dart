import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/route_path.dart';
import '../../../../data/models/app_models.dart';
import '../../../../service/socket_service.dart';
import '../../../../utils/app_colors/app_colors.dart';
import '../../../../utils/app_text_style/app_text_style.dart';
import '../../../../utils/static_strings/static_strings.dart';
import '../../../widget/hv_ui.dart';
import '../../../widget/provider_tile.dart';
import '../../appointment/widget/appointment_tile.dart';
import '../../bottom_navigationbar/controller/bottom_navigation_controller.dart';
import '../../reminder/widget/dose_tile.dart';
import '../Simmer_Effect/simmer_effect_screen.dart';
import '../controller/home_controller.dart';
import '../widgets/category_card.dart';
import '../widgets/emergency_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  IconData _iconFor(String key) {
    switch (key.toUpperCase()) {
      case 'DOCTOR':
        return Icons.medical_services_outlined;
      case 'PHARMACY':
        return Icons.local_pharmacy_outlined;
      case 'CLINIC':
      case 'HOSPITAL':
        return Icons.local_hospital_outlined;
      case 'DIAGNOSTIC':
      case 'DIAGNOSTIC_CENTER':
      case 'LAB':
        return Icons.biotech_outlined;
      case 'WELLNESS':
        return Icons.spa_outlined;
      case 'PLASTIC_SURGERY':
        return Icons.face_retouching_natural;
      default:
        return Icons.health_and_safety_outlined;
    }
  }

  void _goTab(int i) {
    if (Get.isRegistered<BottomNavController>()) Get.find<BottomNavController>().changeIndex(i);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : Get.put(HomeController());

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Obx(() {
        if (c.isLoading.value && c.fullName.isEmpty) return const HomeScreenShimmer();
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: c.loadAll,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(c),
              if (c.activeSosId.value != null)
                HVCardBox(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  color: AppColors.emergencyColor,
                  onTap: () => Get.toNamed(RoutePath.emergency),
                  child: Row(children: [
                    const Icon(Icons.sos, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('SOS alert is active. Tap to manage.'.tr,
                          style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: LayoutBuilder(builder: (context, cons) {
                  const spacing = 10.0;
                  final w = (cons.maxWidth - spacing * 2) / 3;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: c.providerTypes
                        .map((t) => CategoryCard(
                              width: w,
                              title: Fmt.enumLabel(t.label),
                              icon: _iconFor(t.key),
                              onTap: () => Get.toNamed(RoutePath.search, arguments: {
                                "providerTypeId": t.id,
                                "providerTypeKey": t.key,
                                "providerTypeLabel": Fmt.enumLabel(t.label),
                              }),
                            ))
                        .toList(),
                  );
                }),
              ),
              EmergencyCard(
                title: AppStrings.emergencyNeed.tr,
                subtitle: AppStrings.immediateConnectionWithEmergencyServices.tr,
                buttonLabel: AppStrings.emergency.tr,
                leadingIcon: Icons.add_alert,
                backgroundColor: AppColors.emergencyColor,
                buttonColor: AppColors.emergencyBlackColor,
                onPressed: () => Get.toNamed(RoutePath.emergency),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ---------------- Today's medicines
                  SectionTitle(
                    "${"Today's medicines".tr}${c.todayDoses.isEmpty ? '' : '  (${c.taken.value}/${c.todayDoses.length})'}",
                    action: 'View all'.tr,
                    onAction: () => Get.toNamed(RoutePath.todayDoses),
                  ),
                  if (c.todayDoses.isEmpty)
                    _hint(Icons.medication_outlined, 'No medicines scheduled today'.tr, 'Add reminder'.tr,
                        () => Get.toNamed(RoutePath.addReminder))
                  else
                    ...c.todayDoses.take(4).map((d) => DoseTile(
                          dose: d,
                          busy: c.isRecording(d),
                          onRecord: (s) => c.recordDose(d, s),
                        )),
                  // ---------------- Upcoming appointments
                  SectionTitle('Upcoming appointments'.tr, action: 'View all'.tr, onAction: () => _goTab(1)),
                ]),
              ),
              if (c.upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _hint(Icons.event_outlined, 'No upcoming appointments'.tr, 'Find a provider'.tr,
                      () => Get.toNamed(RoutePath.search)),
                )
              else
                ...c.upcoming.map((a) => AppointmentTile(
                      a: a,
                      onTap: () => Get.toNamed(RoutePath.appointmentDetails, arguments: {"id": a.id}),
                    )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SectionTitle('Latest health log'.tr, action: 'Trends'.tr, onAction: () => Get.toNamed(RoutePath.healthTrends)),
                  _latestLog(c.latestLog.value),
                  if (c.expiringInsurances.isNotEmpty) ...[
                    SectionTitle('Insurance expiring soon'.tr),
                    ...c.expiringInsurances.map((i) => HVCardBox(
                          borderColor: const Color(0xFFE09B00),
                          onTap: () => Get.toNamed(RoutePath.insurance),
                          child: Row(children: [
                            const Icon(Icons.shield_outlined, color: Color(0xFFE09B00)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(i.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                Text("${i.insuranceProvider} • ${'expires'.tr} ${Fmt.date(i.expiryDate)}",
                                    style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                              ]),
                            ),
                          ]),
                        )),
                  ],
                  SectionTitle('Providers'.tr, action: 'View all'.tr, onAction: () => Get.toNamed(RoutePath.search)),
                ]),
              ),
              if (c.providers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No providers available yet'.tr, style: AppTextStyles.body.copyWith(color: AppColors.hintColor)),
                )
              else
                ...c.providers.take(3).map((p) => ProviderTile(provider: p)),
              if (c.articles.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SectionTitle(AppStrings.healthANDWellnessArticles.tr,
                      action: AppStrings.viewAll.tr, onAction: () => Get.toNamed(RoutePath.healthArticle)),
                ),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: c.articles.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _ArticleCard(c.articles[i]),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _header(HomeController c) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(Get.context!).padding.top + 12, 8, 16),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      child: Column(children: [
        ListTile(
          leading: GestureDetector(
            onTap: () => Get.toNamed(RoutePath.healthCard),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              foregroundImage: c.fullImageUrl.isNotEmpty ? NetworkImage(c.fullImageUrl) : null,
              child: Text(c.fullName.isNotEmpty ? c.fullName.value[0].toUpperCase() : '?',
                  style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 22)),
            ),
          ),
          title: Text(c.fullName.isNotEmpty ? c.fullName.value : AppStrings.welcomeBack.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 19)),
          subtitle: Text(
            [
              AppStrings.welcomeBack.tr,
              if (c.bloodGroup.value != null) "🩸 ${c.bloodGroup.value}",
            ].join('  ·  '),
            style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
          trailing: Obx(() {
            final n = RealtimeService.to.unreadCount.value;
            return GestureDetector(
              onTap: () => Get.toNamed(RoutePath.notification),
              child: Badge(
                isLabelVisible: n > 0,
                label: Text(n > 99 ? '99+' : '$n'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () => Get.toNamed(RoutePath.search),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.search, color: AppColors.hintColor),
                const SizedBox(width: 8),
                Text(AppStrings.searchByProvider.tr, style: AppTextStyles.hint),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _hint(IconData icon, String text, String action, VoidCallback onTap) {
    return HVCardBox(
      child: Row(children: [
        Icon(icon, color: AppColors.primaryColor.withValues(alpha: 0.6)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.hintColor))),
        TextButton(onPressed: onTap, child: Text(action)),
      ]),
    );
  }

  Widget _latestLog(HealthLogModel? l) {
    if (l == null) {
      return _hint(Icons.monitor_heart_outlined, 'No measurements yet'.tr, 'Add'.tr, () => Get.toNamed(RoutePath.addHealthLog));
    }
    final items = <(IconData, String, String)>[
      if (l.bloodPressure != null) (Icons.favorite_outline, l.bloodPressure!, 'mmHg'),
      if (l.heartRate != null) (Icons.monitor_heart_outlined, HealthLogModel.fmt(l.heartRate), 'bpm'),
      if (l.bloodSugar != null) (Icons.water_drop_outlined, HealthLogModel.fmt(l.bloodSugar), 'mg/dL'),
      if (l.weight != null) (Icons.monitor_weight_outlined, HealthLogModel.fmt(l.weight), 'kg'),
      if (l.temperature != null) (Icons.thermostat, HealthLogModel.fmt(l.temperature), '°C'),
      if (l.oxygenSaturation != null) (Icons.air, HealthLogModel.fmt(l.oxygenSaturation), 'SpO₂ %'),
    ];
    return HVCardBox(
      onTap: () => Get.toNamed(RoutePath.healthLog),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: items
              .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(e.$1, size: 18, color: AppColors.primaryColor),
                    const SizedBox(width: 4),
                    Text(e.$2, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 2),
                    Text(e.$3, style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
                  ]))
              .toList(),
        ),
        const SizedBox(height: 6),
        Text(Fmt.dateTime(l.recordedAt), style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
      ]),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ArticleModel a;
  const _ArticleCard(this.a);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(RoutePath.healthDetail, arguments: {'articleId': a.id}),
      child: SizedBox(
        width: 260,
        child: Stack(children: [
          ApiImage(a.image, width: 260, height: 190, radius: BorderRadius.circular(10)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Text(a.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}
