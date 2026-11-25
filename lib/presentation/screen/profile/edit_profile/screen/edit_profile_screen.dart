import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/edit_profile_controller.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(EditProfileController());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.editProfile.tr),
      body: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        return Form(
          key: c.formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Center(
              child: GestureDetector(
                onTap: c.pickImage,
                child: Stack(children: [
                  Obx(() => CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.bottomNavigationColor,
                        foregroundImage: c.pickedImage.value != null
                            ? FileImage(c.pickedImage.value!)
                            : (c.existingImageUrl.value.isNotEmpty ? NetworkImage(c.existingImageUrl.value) as ImageProvider : null),
                        child: const Icon(Icons.person, size: 48, color: AppColors.primaryColor),
                      )),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryColor,
                      child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            LabeledField(label: 'Full name'.tr, controller: c.nameController, validator: V.required),
            LabeledField(
              label: 'Phone'.tr,
              controller: c.numberController,
              keyboardType: TextInputType.phone,
              validator: (v) => (v ?? '').trim().length < 6 ? 'Enter a valid phone number'.tr : null,
            ),
            LabeledField(label: 'Address'.tr, controller: c.addressController, maxLines: 2),
            if (c.isNormalUser) ..._patient(c) else ..._provider(c),
            const SizedBox(height: 16),
            Obx(() => PrimaryButton(label: 'Save changes'.tr, loading: c.isSaving.value, onPressed: c.updateProfile)),
            const SizedBox(height: 24),
          ]),
        );
      }),
    );
  }

  List<Widget> _patient(EditProfileController c) => [
        LabeledField(
          label: 'Date of birth'.tr,
          controller: c.dateOfBirthController,
          readOnly: true,
          onTap: c.pickDob,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        Row(children: [
          Expanded(
            child: Obx(() => LabeledDropdown<String>(
                  label: 'Gender'.tr,
                  value: c.gender.value,
                  items: EditProfileController.genders,
                  itemLabel: (g) => Fmt.enumLabel(g).tr,
                  onChanged: (v) => c.gender.value = v,
                )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() => LabeledDropdown<String>(
                  label: 'Blood group'.tr,
                  value: c.bloodGroup.value,
                  items: EditProfileController.bloodGroups,
                  itemLabel: (g) => g,
                  onChanged: (v) => c.bloodGroup.value = v,
                )),
          ),
        ]),
        LabeledField(label: 'ID / AMKA number'.tr, controller: c.identificationController),
        LabeledField(label: 'Allergies (comma separated)'.tr, controller: c.allergiesController, hint: 'penicillin, nuts'),
        LabeledField(label: 'Chronic conditions (comma separated)'.tr, controller: c.chronicController, hint: 'asthma'),
        Row(children: [
          Expanded(child: Text('Emergency contacts'.tr, style: AppTextStyles.title.copyWith(fontSize: 15))),
          TextButton.icon(onPressed: c.addContact, icon: const Icon(Icons.person_add_alt), label: Text('Add'.tr)),
        ]),
        Obx(() => Column(
              children: c.contacts
                  .map((r) => HVCardBox(
                        child: Column(children: [
                          Row(children: [
                            Expanded(child: LabeledField(label: 'Name'.tr, controller: r.name)),
                            IconButton(
                              onPressed: () => c.removeContact(r),
                              icon: const Icon(Icons.delete_outline, color: AppColors.emergencyColor),
                            ),
                          ]),
                          Row(children: [
                            Expanded(
                              child: LabeledField(label: 'Phone'.tr, controller: r.phone, keyboardType: TextInputType.phone),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: LabeledField(label: 'Relation'.tr, controller: r.relation)),
                          ]),
                        ]),
                      ))
                  .toList(),
            )),
      ];

  List<Widget> _provider(EditProfileController c) => [
        LabeledField(label: 'Display / business name'.tr, controller: c.displayNameController),
        LabeledField(label: 'City / area'.tr, controller: c.locationController, hint: 'Athens'),
        LabeledField(label: 'Specialization'.tr, controller: c.specializationController),
        LabeledField(
          label: 'Years of experience'.tr,
          controller: c.experienceController,
          keyboardType: TextInputType.number,
          validator: V.numberIn(0, 80),
        ),
        LabeledField(label: 'Languages (comma separated)'.tr, controller: c.languagesController, hint: 'Greek, English'),
        LabeledField(label: 'About'.tr, controller: c.aboutController, maxLines: 4),
        Obx(() => c.catalogue.isEmpty
            ? const SizedBox.shrink()
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Catalogue services'.tr, style: AppTextStyles.title.copyWith(fontSize: 15)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: c.catalogue
                      .map((s) => FilterChip(
                            label: Text("${s.title} · ${s.priceLabel}"),
                            selected: c.selectedServiceIds.contains(s.id),
                            selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primaryColor,
                            onSelected: (_) => c.toggleService(s.id),
                          ))
                      .toList(),
                ),
              ])),
      ];
}
