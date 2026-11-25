import 'package:get/get.dart';

import '../../../appointment/controller/appointment_controller.dart';

class ProviderBottomNavController extends GetxController {
  var currentIndex = 0.obs;

  void changeIndex(int index) => currentIndex.value = index;

  /// Switch to the Tasks tab with a status filter.
  void openTasks(String status) {
    currentIndex.value = 1;
    if (Get.isRegistered<AppointmentController>(tag: 'provider')) {
      Get.find<AppointmentController>(tag: 'provider').setStatus(status);
    } else {
      Get.put(AppointmentController(forProvider: true), tag: 'provider').status.value = status;
    }
  }
}
