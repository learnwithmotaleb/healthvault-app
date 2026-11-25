import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routes/route_path.dart';
import '../../../../utils/app_colors/app_colors.dart';
import '../../../../utils/app_text_style/app_text_style.dart';
import '../../../../utils/static_strings/static_strings.dart';
import '../../../widget/custom_appbar.dart';
import '../../../widget/hv_ui.dart';
import '../controller/emergency_controller.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<EmergencyController>() ? Get.find<EmergencyController>() : Get.put(EmergencyController());

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.emergency.tr, actions: [
        IconButton(
          tooltip: 'History'.tr,
          onPressed: () => Get.toNamed(RoutePath.sosHistory),
          icon: const Icon(Icons.history, color: AppColors.primaryColor),
        ),
      ]),
      body: RefreshIndicator(
        onRefresh: c.loadInfo,
        child: Obx(() {
          final a = c.active.value;
          final info = c.info.value;
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (a == null) ...[
              Center(
                child: GestureDetector(
                  onLongPress: c.isSending.value ? null : c.triggerSos,
                  onTap: c.isSending.value
                      ? null
                      : () async {
                          if (await Dialogs.confirm(
                            title: 'Send SOS?'.tr,
                            message: 'Your location will be shared with the support team.'.tr,
                            confirmText: 'Send SOS'.tr,
                            destructive: true,
                          )) {
                            c.triggerSos();
                          }
                        },
                  child: Container(
                    width: 190,
                    height: 190,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emergencyColor,
                      boxShadow: [
                        BoxShadow(color: AppColors.emergencyColor.withValues(alpha: 0.35), blurRadius: 30, spreadRadius: 10),
                      ],
                    ),
                    child: Center(
                      child: c.isSending.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.sos, color: Colors.white, size: 64),
                              Text('Tap for help'.tr, style: AppTextStyles.body.copyWith(color: Colors.white)),
                            ]),
                    ),
                  ),
                ),
              ),
              LabeledField(
                label: 'What happened? (optional)'.tr,
                controller: c.messageController,
                hint: 'Chest pain'.tr,
              ),
            ] else
              _ActiveCard(c: c),
            SectionTitle('Emergency numbers'.tr),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: info.numbers
                  .map((n) => HVCardBox(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        onTap: () => c.call(n.number),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.emergencyColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.call, color: AppColors.emergencyColor, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n.number, style: AppTextStyles.title.copyWith(fontSize: 15)),
                              Text(n.name.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
                            ]),
                          ),
                        ]),
                      ))
                  .toList(),
            ),
            SectionTitle('Emergency contacts'.tr, action: 'Edit'.tr, onAction: () => Get.toNamed(RoutePath.editProfile)),
            if (info.contacts.isEmpty)
              Text('Add emergency contacts in your profile.'.tr, style: AppTextStyles.body.copyWith(color: AppColors.hintColor)),
            ...info.contacts.map((ct) => HVCardBox(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.bottomNavigationColor,
                      child: Text(ct.name.isNotEmpty ? ct.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primaryColor)),
                    ),
                    title: Text(ct.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text([ct.phone, if ((ct.relation ?? '').isNotEmpty) ct.relation!].join(' · ')),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(onPressed: () => c.smsContact(ct), icon: const Icon(Icons.sms_outlined, color: AppColors.primaryColor)),
                      IconButton(onPressed: () => c.call(ct.phone), icon: const Icon(Icons.call, color: AppColors.primaryColor)),
                    ]),
                  ),
                )),
            if (info.bloodGroup != null || info.allergies.isNotEmpty || info.chronicConditions.isNotEmpty) ...[
              SectionTitle('Medical info'.tr),
              HVCardBox(
                child: Column(children: [
                  KeyValueRow('Blood group'.tr, info.bloodGroup ?? '-'),
                  KeyValueRow('Allergies'.tr, info.allergies.join(', ')),
                  KeyValueRow('Chronic conditions'.tr, info.chronicConditions.join(', ')),
                ]),
              ),
            ],
            const SizedBox(height: 24),
          ]);
        }),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final EmergencyController c;
  const _ActiveCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final a = c.active.value!;
    return HVCardBox(
      color: AppColors.emergencyColor,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.sos, color: Colors.white, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text('SOS alert is active'.tr, style: AppTextStyles.title.copyWith(color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 6),
        Text("${'Sent'.tr}: ${Fmt.dateTime(a.createdAt)}", style: AppTextStyles.body.copyWith(color: Colors.white70)),
        Text(
          c.lastLocationAt.value == null
              ? 'Sharing live location every 30 seconds while this screen is open.'.tr
              : "${'Location updated'.tr} ${Fmt.time(c.lastLocationAt.value)}",
          style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 12),
        ),
        if ((a.address ?? '').isNotEmpty)
          Text(a.address!, style: AppTextStyles.body.copyWith(color: Colors.white)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () => c.call('112'),
              icon: const Icon(Icons.call, color: AppColors.emergencyColor),
              label: const Text('112', style: TextStyle(color: AppColors.emergencyColor)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () => c.call('166'),
              icon: const Icon(Icons.local_hospital, color: AppColors.emergencyColor),
              label: const Text('166', style: TextStyle(color: AppColors.emergencyColor)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
              onPressed: c.smsAllContacts,
              icon: const Icon(Icons.sms, color: Colors.white),
              label: Text('Text contacts'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
              onPressed: c.shareToContacts,
              icon: const Icon(Icons.share, color: Colors.white),
              label: Text('Share'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ]),
        if (c.mapsLink.value != null)
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(c.mapsLink.value!), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            label: Text('Open my location in Maps'.tr, style: const TextStyle(color: Colors.white)),
          ),
        const Divider(color: Colors.white38),
        Row(children: [
          Expanded(
            child: TextButton(
              onPressed: c.isSending.value ? null : c.triggerSos,
              child: Text('Send again'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: c.isSending.value
                  ? null
                  : () async {
                      if (await Dialogs.confirm(title: 'Cancel SOS'.tr, message: 'Was this a false alarm?'.tr)) c.cancelSos();
                    },
              child: Text("I'm safe – cancel".tr,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<EmergencyController>() ? Get.find<EmergencyController>() : Get.put(EmergencyController());
    c.loadHistory();
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'SOS history'.tr),
      body: Obx(() => c.history.isEmpty
          ? EmptyView(icon: Icons.history, title: 'No SOS alerts'.tr)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: c.history.length,
              itemBuilder: (_, i) {
                final h = c.history[i];
                return HVCardBox(
                  child: Row(children: [
                    Icon(Icons.sos, color: statusColor(h.status == 'ACTIVE' ? 'CANCELLED' : h.status)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(Fmt.dateTime(h.createdAt), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                        if ((h.message ?? '').isNotEmpty) Text(h.message!, style: AppTextStyles.body.copyWith(fontSize: 12)),
                        if ((h.address ?? '').isNotEmpty)
                          Text(h.address!, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                      ]),
                    ),
                    StatusChip(h.status == 'ACTIVE' ? 'CANCELLED' : h.status, label: Fmt.enumLabel(h.status)),
                  ]),
                );
              },
            )),
    );
  }
}
