import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../service/socket_service.dart';
import '../../../../utils/app_colors/app_colors.dart';
import '../../../../utils/static_strings/static_strings.dart';
import '../../appointment/screen/appointment_screen.dart';
import '../../home/screen/home_screen.dart';
import '../../profile/profile/screen/profile_screen.dart';
import '../../reminder/select_reminder/screen/select_reminder_screen.dart';
import '../controller/bottom_navigation_controller.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  final BottomNavController controller = Get.put(BottomNavController());

  final List<Widget> screens = const [
    HomeScreen(),
    AppointmentScreen(),
    SelectReminderScreen(),
    ProfileScreen(),
  ];

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
            type: BottomNavigationBarType.fixed,
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeIndex,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: AppColors.greyColor,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppStrings.home.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), label: AppStrings.appointments.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.alarm), label: AppStrings.reminder.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.person), label: AppStrings.profile.tr),
            ],
          ),
        ));
  }
}
