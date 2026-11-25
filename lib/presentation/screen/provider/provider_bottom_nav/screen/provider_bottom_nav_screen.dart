import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../service/socket_service.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../provider_home/screen/provider_home_screen.dart';
import '../../provider_profile/screen/provider_profile_screen.dart';
import '../../provider_task/screen/provider_task_screen.dart';
import '../controller/provider_bottom_nav_controller.dart';

class ProviderBottomNavScreen extends StatefulWidget {
  const ProviderBottomNavScreen({super.key});

  @override
  State<ProviderBottomNavScreen> createState() => _ProviderBottomNavScreenState();
}

class _ProviderBottomNavScreenState extends State<ProviderBottomNavScreen> {
  final ProviderBottomNavController controller = Get.put(ProviderBottomNavController());

  final List<Widget> screens = const [ProviderHomeScreen(), ProviderTaskScreen(), ProviderProfileScreen()];

  @override
  void initState() {
    super.initState();
    RealtimeService.to.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: IndexedStack(index: controller.currentIndex.value, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeIndex,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: AppColors.greyColor,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppStrings.home.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), label: AppStrings.task.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.person), label: AppStrings.profile.tr),
            ],
          ),
        ));
  }
}
