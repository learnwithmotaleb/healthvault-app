import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/app_models.dart';
import '../../../../service/session_service.dart';
import '../../../../utils/app_colors/app_colors.dart';
import '../../../../utils/app_text_style/app_text_style.dart';
import '../../../widget/custom_appbar.dart';
import '../../../widget/hv_ui.dart';
import '../controller/appointment_controller.dart';

/// Details of one appointment. Patients can cancel / add to calendar;
/// providers can confirm, complete or cancel.
class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({super.key});

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  late final AppointmentDetailsController c;
  late final String tag;
  final isProvider = SessionService.isProvider;

  @override
  void initState() {
    super.initState();
    tag = 'appt-${DateTime.now().microsecondsSinceEpoch}';
    c = Get.put(AppointmentDetailsController(forProvider: isProvider), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<AppointmentDetailsController>(tag: tag);
    super.dispose();
  }

  Future<void> _cancel() async {
    final reason = await Dialogs.input(
      title: 'Cancel appointment'.tr,
      hint: 'Reason (optional)'.tr,
      confirmText: 'Cancel appointment'.tr,
    );
    if (reason == null) return;
    isProvider ? c.updateStatus('CANCELLED', reason: reason) : c.cancel(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'Appointment details'.tr),
      body: Obx(() {
        final a = c.appointment.value;
        if (c.isLoading.value && a == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (a == null) return ErrorView(message: c.error.value ?? 'Not found'.tr, onRetry: c.load);
        final person = isProvider ? a.normalUser : a.provider;
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              HVCardBox(
                child: Row(children: [
                  Avatar(image: person?.profileImage, name: person?.fullName ?? '?', radius: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(person?.fullName ?? '-', style: AppTextStyles.title.copyWith(fontSize: 16)),
                      if (!isProvider && (person?.specialization ?? person?.providerTypeLabel) != null)
                        Text(person?.specialization ?? person?.providerTypeLabel ?? '',
                            style: AppTextStyles.body.copyWith(color: AppColors.primaryColor, fontSize: 13)),
                      if (isProvider && person != null)
                        Text(
                          [
                            if (person.age != null) "${person.age} ${'yrs'.tr}",
                            if (person.gender != null) Fmt.enumLabel(person.gender!),
                            if (person.bloodGroup != null) person.bloodGroup!,
                          ].join(' • '),
                          style: AppTextStyles.body.copyWith(color: AppColors.hintColor, fontSize: 13),
                        ),
                    ]),
                  ),
                  StatusChip(a.status),
                ]),
              ),
              HVCardBox(
                child: Column(children: [
                  KeyValueRow('Date & time'.tr, Fmt.dateTime(a.dateTime)),
                  KeyValueRow('Duration'.tr, "${a.durationMinutes} min"),
                  KeyValueRow('Service'.tr, a.service?.title ?? '-'),
                  KeyValueRow('Price'.tr, a.service?.priceLabel ?? '-'),
                  KeyValueRow('Reason'.tr, a.reasonForVisit ?? '-'),
                  if (!isProvider && (person?.address ?? '').isNotEmpty) KeyValueRow('Address'.tr, person!.address!),
                  if (a.status == 'CANCELLED') ...[
                    KeyValueRow('Cancelled by'.tr, Fmt.enumLabel(a.cancelledBy ?? '-')),
                    KeyValueRow('Cancellation reason'.tr, a.cancellationReason ?? '-'),
                  ],
                ]),
              ),
              if (person != null && ((person.phone ?? '').isNotEmpty || (person.email ?? '').isNotEmpty))
                HVCardBox(
                  child: Column(children: [
                    if ((person.phone ?? '').isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.call_outlined, color: AppColors.primaryColor),
                        title: Text(person.phone!),
                        onTap: () => launchUrl(Uri.parse('tel:${person.phone}')),
                      ),
                    if ((person.email ?? '').isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.email_outlined, color: AppColors.primaryColor),
                        title: Text(person.email!),
                        onTap: () => launchUrl(Uri.parse('mailto:${person.email}')),
                      ),
                  ]),
                ),
              const SizedBox(height: 12),
              ..._actions(a),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _actions(AppointmentModel a) {
    final working = c.isWorking.value;
    final gap = const SizedBox(height: 10);
    if (isProvider) {
      return [
        if (a.status == 'PENDING') ...[
          PrimaryButton(label: 'Confirm'.tr, icon: Icons.check, loading: working, onPressed: () => c.updateStatus('CONFIRMED')),
          gap,
        ],
        if (a.status == 'PENDING' || a.status == 'CONFIRMED') ...[
          PrimaryButton(
            label: 'Mark as completed'.tr,
            icon: Icons.task_alt,
            color: AppColors.loginLogoRadiusColor,
            loading: working,
            onPressed: () async {
              if (await Dialogs.confirm(title: 'Complete'.tr, message: 'Mark this appointment as completed?'.tr)) {
                c.updateStatus('COMPLETED');
              }
            },
          ),
          gap,
          PrimaryButton(
            label: 'Cancel appointment'.tr,
            outlined: true,
            color: AppColors.emergencyColor,
            onPressed: working ? null : _cancel,
          ),
        ],
      ];
    }
    return [
      if (a.status != 'CANCELLED' && a.status != 'COMPLETED') ...[
        PrimaryButton(label: 'Add to calendar'.tr, icon: Icons.event, loading: working, onPressed: c.addToCalendar),
        gap,
      ],
      if (a.canPatientCancel)
        PrimaryButton(
          label: 'Cancel appointment'.tr,
          outlined: true,
          color: AppColors.emergencyColor,
          onPressed: working ? null : _cancel,
        ),
    ];
  }
}
