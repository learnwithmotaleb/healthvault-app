import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static IconData iconFor(String type) {
    switch (type) {
      case 'APPOINTMENT':
        return Icons.event_note;
      case 'MEDICATION':
        return Icons.medication;
      case 'INSURANCE':
        return Icons.shield_outlined;
      case 'DOCUMENT':
        return Icons.description_outlined;
      case 'SUPPORT':
        return Icons.support_agent;
      case 'SOS':
        return Icons.sos;
      case 'PROVIDER':
        return Icons.verified_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(NotificationController());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.notification.tr, actions: [
        IconButton(
          tooltip: 'Mark all as read'.tr,
          onPressed: c.markAllRead,
          icon: const Icon(Icons.done_all, color: AppColors.primaryColor),
        ),
        IconButton(
          tooltip: 'Settings'.tr,
          onPressed: () => Get.toNamed(RoutePath.notificationSettings),
          icon: const Icon(Icons.tune, color: AppColors.primaryColor),
        ),
      ]),
      body: Column(children: [
        Obx(() => ChoiceBar(
              values: ['', 'UNREAD', ...NotificationController.types],
              labels: ['All'.tr, 'Unread'.tr, ...NotificationController.types.map((t) => Fmt.enumLabel(t).tr)],
              selected: c.unreadOnly.value ? 'UNREAD' : c.type.value,
              onSelected: (v) {
                if (v == 'UNREAD') {
                  c.type.value = '';
                  c.setUnreadOnly(true);
                } else {
                  c.unreadOnly.value = false;
                  c.setType(v);
                }
              },
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
                  isEmpty: c.items.isEmpty,
                  onRefresh: c.fetch,
                  empty: EmptyView(icon: Icons.notifications_none, title: 'No notifications'.tr),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: c.items.length,
                    itemBuilder: (_, i) {
                      final n = c.items[i];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.emergencyColor,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => c.remove(n),
                        child: Material(
                          color: n.isRead ? Colors.white : AppColors.bottomNavigationColor,
                          child: ListTile(
                            onTap: () => c.open(n),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                              child: Icon(iconFor(n.type), color: n.type == 'SOS' ? AppColors.emergencyColor : AppColors.primaryColor),
                            ),
                            title: Text(n.title,
                                style: AppTextStyles.body.copyWith(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700)),
                            subtitle: Text(n.message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(Fmt.ago(n.createdAt), style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
                              if (!n.isRead)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle),
                                ),
                            ]),
                          ),
                        ),
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
