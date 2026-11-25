import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../data/models/user_models.dart';
import '../../../../../service/session_service.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/hv_ui.dart';
import '../../../profile/favourite_profile/controller/favourite_controller.dart';
import '../controller/info_provider_details_controller.dart';

class InfoProviderDetailsScreen extends StatelessWidget {
  const InfoProviderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(InfoProviderDetailsController());
    final fav = FavouriteController.to;

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Obx(() {
        if (c.isLoading.value && c.provider.value == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        final p = c.provider.value;
        if (p == null) {
          return SafeArea(
            child: Column(children: [
              const Align(alignment: Alignment.centerLeft, child: BackButton()),
              Expanded(
                child: ErrorView(
                  message: c.errorMessage.value.isEmpty ? 'Provider not found'.tr : c.errorMessage.value,
                  onRetry: () => c.getProviderDetails(c.profileId),
                ),
              ),
            ]),
          );
        }
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 230,
              backgroundColor: AppColors.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                if (SessionService.isPatient)
                  Obx(() {
                    final isFav = fav.ids.contains(p.id);
                    return IconButton(
                      onPressed: () => fav.toggleFavorite(p.id, providerName: p.name),
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                    );
                  }),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  ApiImage(
                    p.profileImage,
                    placeholder: Container(
                      color: AppColors.primaryColor,
                      child: const Icon(Icons.local_hospital, size: 90, color: Colors.white54),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(p.name, style: AppTextStyles.title.copyWith(fontSize: 20)),
                  if (p.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(p.subtitle, style: AppTextStyles.body.copyWith(color: AppColors.primaryColor)),
                    ),
                  const SizedBox(height: 8),
                  if ((p.address ?? '').isNotEmpty) InfoLine(Icons.location_on_outlined, p.address!),
                  if ((p.location ?? '').isNotEmpty && p.location != p.address)
                    InfoLine(Icons.location_city_outlined, p.location!),
                  if ((p.yearsOfExperience ?? 0) > 0)
                    InfoLine(Icons.work_history_outlined, "${p.yearsOfExperience} ${'yrs experience'.tr}"),
                  if (p.languages.isNotEmpty) InfoLine(Icons.translate, p.languages.join(', ')),
                  const SizedBox(height: 8),
                  Row(children: [
                    if ((p.phone ?? '').isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(Uri.parse('tel:${p.phone}')),
                          icon: const Icon(Icons.call_outlined),
                          label: Text('Call'.tr),
                        ),
                      ),
                    if ((p.phone ?? '').isNotEmpty && (p.email ?? '').isNotEmpty) const SizedBox(width: 8),
                    if ((p.email ?? '').isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(Uri.parse('mailto:${p.email}')),
                          icon: const Icon(Icons.email_outlined),
                          label: Text('Email'.tr),
                        ),
                      ),
                  ]),
                  if ((p.about ?? '').isNotEmpty) ...[
                    SectionTitle('About'.tr),
                    Text(p.about!, style: AppTextStyles.body.copyWith(color: AppColors.labelColor, height: 1.5)),
                  ],
                  SectionTitle('Services'.tr),
                  if (p.services.isEmpty)
                    Text('No services listed'.tr, style: AppTextStyles.body.copyWith(color: AppColors.hintColor)),
                  ...p.services.map((s) => HVCardBox(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          const Icon(Icons.medical_services_outlined, color: AppColors.primaryColor),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.title, style: AppTextStyles.body)),
                          Text(s.priceLabel,
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
                        ]),
                      )),
                  SectionTitle('Availability'.tr),
                  _AvailabilityTable(days: c.availability),
                  const SizedBox(height: 90),
                ]),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final p = c.provider.value;
        if (p == null || !SessionService.isPatient) return const SizedBox.shrink();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: PrimaryButton(
              label: 'Book appointment'.tr,
              icon: Icons.calendar_month,
              onPressed: p.services.isEmpty ? null : () => Get.toNamed(RoutePath.bookAppointment),
            ),
          ),
        );
      }),
    );
  }
}

class _AvailabilityTable extends StatelessWidget {
  final List<AvailabilityDay> days;
  const _AvailabilityTable({required this.days});

  @override
  Widget build(BuildContext context) {
    final working = days.where((d) => d.slots.isNotEmpty).toList()
      ..sort((a, b) => AvailabilityDay.order.indexOf(a.dayOfWeek).compareTo(AvailabilityDay.order.indexOf(b.dayOfWeek)));
    if (working.isEmpty) {
      return Text('Accepts appointments at any time'.tr, style: AppTextStyles.body.copyWith(color: AppColors.hintColor));
    }
    return HVCardBox(
      child: Column(
        children: [
          ...working.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 56,
                    child: Text(d.dayOfWeek.tr, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: d.slots
                          .map((s) => StatusChip('UPCOMING', label: "${s.startTime} – ${s.endTime}"))
                          .toList(),
                    ),
                  ),
                ]),
              )),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Times are Greek time'.tr,
                style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
          ),
        ],
      ),
    );
  }
}
