import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthvault/utils/static_strings/static_strings.dart';

import '../../../../core/routes/route_path.dart';
import '../../../../utils/app_colors/app_colors.dart';
import '../../../widget/custom_appbar.dart';
import '../../../widget/hv_ui.dart';
import '../controller/appointment_controller.dart';
import '../widget/appointment_tile.dart';

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<AppointmentController>()
        ? Get.find<AppointmentController>()
        : Get.put(AppointmentController());

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(
        title: AppStrings.myAppointments.tr,
        showBack: Navigator.of(context).canPop(),
        actions: [
          IconButton(
            tooltip: 'Find a provider'.tr,
            onPressed: () => Get.toNamed(RoutePath.search),
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryColor),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() => ChoiceBar(
                values: const ['upcoming', 'past', 'CANCELLED', 'all'],
                labels: ['Upcoming'.tr, 'Past'.tr, 'Cancelled'.tr, 'All'.tr],
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
                    empty: EmptyView(
                      icon: Icons.event_available_outlined,
                      title: 'No appointments'.tr,
                      subtitle: 'Book a visit with a doctor, clinic or pharmacy.'.tr,
                      action: OutlinedButton.icon(
                        onPressed: () => Get.toNamed(RoutePath.search),
                        icon: const Icon(Icons.search),
                        label: Text('Find a provider'.tr),
                      ),
                    ),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: c.appointments.length + (c.isLoadingMore.value ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= c.appointments.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                          );
                        }
                        final a = c.appointments[i];
                        return AppointmentTile(
                          a: a,
                          onTap: () => Get.toNamed(RoutePath.appointmentDetails, arguments: {"id": a.id}),
                        );
                      },
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
