import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/app_models.dart';
import '../../../../utils/app_colors/app_colors.dart';
import '../../../../utils/app_text_style/app_text_style.dart';
import '../../../widget/hv_ui.dart';

class DoseTile extends StatelessWidget {
  final DoseModel dose;
  final bool busy;
  final void Function(String status) onRecord;

  const DoseTile({super.key, required this.dose, required this.onRecord, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return HVCardBox(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: statusColor(dose.status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.medication_outlined, color: statusColor(dose.status), size: 20),
            Text(dose.time, style: AppTextStyles.body.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${dose.pillName} · ${dose.dosage}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            if ((dose.instructions ?? '').isNotEmpty)
              Text(dose.instructions!, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
            if (dose.assignedTo != 'SELF')
              Text("${'For'.tr}: ${dose.assignedTo}",
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.primaryColor)),
          ]),
        ),
        if (busy)
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
        else if (dose.isConfirmable)
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              tooltip: 'Skip'.tr,
              visualDensity: VisualDensity.compact,
              onPressed: () => onRecord('SKIPPED'),
              icon: const Icon(Icons.close_rounded, color: AppColors.greyColor),
            ),
            IconButton.filled(
              tooltip: 'Taken'.tr,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(backgroundColor: AppColors.primaryColor),
              onPressed: () => onRecord('TAKEN'),
              icon: const Icon(Icons.check_rounded, color: Colors.white),
            ),
          ])
        else
          StatusChip(dose.status),
      ]),
    );
  }
}
