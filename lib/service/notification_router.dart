import 'package:get/get.dart';

import '../core/routes/route_path.dart';
import '../presentation/screen/reminder/controller/reminder_controllers.dart';
import '../presentation/widget/hv_ui.dart';
import 'session_service.dart';

/// Opens the right screen for a notification / push `data` payload.
class NotificationRouter {
  static Future<void> open(Map<String, dynamic> data, {String? title, String? message}) async {
    String? s(String k) => data[k]?.toString();

    if (s('appointmentId') != null) {
      Get.toNamed(RoutePath.appointmentDetails, arguments: {"id": s('appointmentId')});
    } else if (s('reminderId') != null && s('scheduledAt') != null) {
      final ok = await Dialogs.confirm(
        title: 'Did you take your medicine?'.tr,
        message: message ?? title ?? '',
        confirmText: 'Taken'.tr,
      );
      await TodayDosesController.quickRecord(s('reminderId')!, s('scheduledAt')!, ok ? 'TAKEN' : 'SKIPPED');
    } else if (s('reminderId') != null) {
      Get.toNamed(RoutePath.todayDoses);
    } else if (s('insuranceId') != null) {
      Get.toNamed(RoutePath.insurance);
    } else if (s('documentId') != null) {
      Get.toNamed(RoutePath.documentDetails, arguments: {"id": s('documentId')});
    } else if (s('conversationId') != null) {
      Get.toNamed(RoutePath.supportChat);
    } else if (s('providerId') != null && s('approvalStatus') != null) {
      await SessionService.refreshMe();
      Get.toNamed(RoutePath.providerProfile);
    } else if (s('sosId') != null || s('alertId') != null) {
      Get.toNamed(RoutePath.emergency);
    }
  }
}
