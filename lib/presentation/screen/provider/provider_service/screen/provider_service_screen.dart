import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/user_models.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/provider_service_controller.dart';

class ProviderServiceScreen extends StatelessWidget {
  const ProviderServiceScreen({super.key});

  Future<void> _edit(ProviderServiceController c, [ServiceModel? s]) async {
    final title = TextEditingController(text: s?.title);
    final price = TextEditingController(text: s == null ? '' : s.price.toString());
    final key = GlobalKey<FormState>();
    await Get.bottomSheet(
      Builder(
        builder: (context) => Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          child: Form(
            key: key,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s == null ? 'Add service'.tr : 'Edit service'.tr, style: AppTextStyles.title.copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              LabeledField(label: 'Title'.tr, controller: title, hint: 'ECG test', validator: V.required),
              LabeledField(
                label: 'Price (€)'.tr,
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: V.numberIn(0, 100000, optional: false),
              ),
              Obx(() => PrimaryButton(
                    label: 'Save'.tr,
                    loading: c.isSaving.value,
                    onPressed: () async {
                      if (!(key.currentState?.validate() ?? false)) return;
                      final p = num.parse(price.text.trim().replaceAll(',', '.'));
                      final ok = s == null ? await c.create(title.text.trim(), p) : await c.updateService(s, title.text.trim(), p);
                      if (ok) Get.back();
                    },
                  )),
            ]),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProviderServiceController());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'My services'.tr),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        onPressed: () => _edit(c),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add service'.tr, style: const TextStyle(color: Colors.white)),
      ),
      body: Obx(() {
        if (c.isLoading.value && c.mine.isEmpty && c.catalogue.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: c.fetch,
          child: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 90), children: [
            SectionTitle('My own services'.tr),
            if (c.mine.isEmpty)
              Text('You have not created any services yet.'.tr, style: AppTextStyles.body.copyWith(color: AppColors.hintColor)),
            ...c.mine.map((s) => HVCardBox(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.medical_services_outlined, color: AppColors.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.title, style: AppTextStyles.body)),
                    Text(s.priceLabel, style: AppTextStyles.body.copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
                    IconButton(onPressed: () => _edit(c, s), icon: const Icon(Icons.edit_outlined, size: 20)),
                    IconButton(
                      onPressed: () => c.delete(s),
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.emergencyColor),
                    ),
                  ]),
                )),
            if (c.catalogue.isNotEmpty) ...[
              SectionTitle('Catalogue services'.tr),
              Text('Tick the standard services you offer.'.tr, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
              const SizedBox(height: 6),
              ...c.catalogue.map((s) => HVCardBox(
                    padding: EdgeInsets.zero,
                    child: CheckboxListTile(
                      activeColor: AppColors.primaryColor,
                      value: c.profileServiceIds.contains(s.id),
                      onChanged: c.isSaving.value ? null : (_) => c.toggleCatalogue(s),
                      title: Text(s.title, style: AppTextStyles.body),
                      secondary: Text(s.priceLabel, style: AppTextStyles.body.copyWith(color: AppColors.primaryColor)),
                    ),
                  )),
            ],
          ]),
        );
      }),
    );
  }
}
