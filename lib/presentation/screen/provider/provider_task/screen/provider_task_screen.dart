import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../../../appointment/controller/appointment_controller.dart';
import '../../../appointment/widget/appointment_tile.dart';

/// Provider appointment list – GET /appointment/provider-appointments
class ProviderTaskScreen extends StatelessWidget {
  const ProviderTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<AppointmentController>(tag: 'provider')
        ? Get.find<AppointmentController>(tag: 'provider')
        : Get.put(AppointmentController(forProvider: true), tag: 'provider');

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.task.tr, showBack: false),
      body: Column(children: [
        Obx(() => ChoiceBar(
              values: const ['PENDING', 'upcoming', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'past', 'all'],
              labels: ['Requests'.tr, 'Upcoming'.tr, 'Confirmed'.tr, 'Completed'.tr, 'Cancelled'.tr, 'Past'.tr, 'All'.tr],
              selected: c.status.value,
              onSelected: c.setStatus,
            )),
        Expanded(
          child: Obx(() => NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) c.loadMore();
                  return false;
                },
                child: AsyncList(
                  loading: c.isLoading.value,
                  error: c.error.value,
                  isEmpty: c.appointments.isEmpty,
                  onRefresh: c.getMyAppointments,
                  empty: EmptyView(icon: Icons.event_busy_outlined, title: 'No appointments'.tr),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: c.appointments.length + (c.isLoadingMore.value ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= c.appointments.length) {
                        return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                      }
                      final a = c.appointments[i];
                      return AppointmentTile(
                        a: a,
                        showPatient: true,
                        onTap: () => Get.toNamed(RoutePath.appointmentDetails, arguments: {"id": a.id}),
                      );
                    },
                  ),
                ),
              )),
        ),
      ]),
    );
  }
}
