import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/app_models.dart';
import '../../../../utils/app_colors/app_colors.dart';
import '../../../../utils/app_text_style/app_text_style.dart';
import '../../../widget/hv_ui.dart';

/// Appointment card – shows the provider (patient view) or the patient (provider view).
class AppointmentTile extends StatelessWidget {
  final AppointmentModel a;
  final bool showPatient;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppointmentTile({super.key, required this.a, this.showPatient = false, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final person = showPatient ? a.normalUser : a.provider;
    final d = a.dateTime;
    return HVCardBox(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bottomNavigationColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(d == null ? '-' : '${d.day}',
                      style: AppTextStyles.title.copyWith(fontSize: 18, color: AppColors.primaryColor)),
                  Text(d == null ? '' : Fmt.dayMonth(d).split(' ').last,
                      style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.primaryColor)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person?.fullName ?? 'Unknown'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      [a.service?.title, if (a.service != null) a.service!.priceLabel].whereType<String>().join(' • '),
                      style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.primaryColor),
                    ),
                    const SizedBox(height: 2),
                    InfoLine(Icons.access_time, Fmt.dateTime(d)),
                    if ((a.reasonForVisit ?? '').isNotEmpty)
                      Text(a.reasonForVisit!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                  ],
                ),
              ),
              StatusChip(a.status),
            ],
          ),
          if (trailing != null) ...[const SizedBox(height: 10), trailing!],
        ],
      ),
    );
  }
}
