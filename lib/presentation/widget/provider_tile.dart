import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/route_path.dart';
import '../../data/models/app_models.dart';
import '../../utils/app_colors/app_colors.dart';
import '../../utils/app_text_style/app_text_style.dart';
import '../screen/profile/favourite_profile/controller/favourite_controller.dart';
import 'hv_ui.dart';

/// Provider card used in the directory, home and favorites.
class ProviderTile extends StatelessWidget {
  final ProviderModel provider;
  final bool showFavorite;

  const ProviderTile({super.key, required this.provider, this.showFavorite = true});

  void _open() => Get.toNamed(RoutePath.infoProviderDetails, arguments: {"profileId": provider.id});

  @override
  Widget build(BuildContext context) {
    final fav = FavouriteController.to;
    final services = provider.services.take(3).map((s) => s.title).join(' • ');
    return HVCardBox(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onTap: _open,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ApiImage(
            provider.profileImage,
            width: 72,
            height: 72,
            radius: BorderRadius.circular(12),
            placeholder: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.bottomNavigationColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_hospital_outlined, color: AppColors.primaryColor, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                if (provider.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(provider.subtitle,
                        style: AppTextStyles.body.copyWith(color: AppColors.primaryColor, fontSize: 12)),
                  ),
                if ((provider.address ?? provider.location ?? '').isNotEmpty)
                  InfoLine(Icons.location_on_outlined, provider.address ?? provider.location ?? ''),
                if (provider.yearsOfExperience != null && provider.yearsOfExperience! > 0)
                  InfoLine(Icons.work_history_outlined, "${provider.yearsOfExperience} ${'yrs experience'.tr}"),
                if (services.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(services,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
                  ),
              ],
            ),
          ),
          if (showFavorite)
            Obx(() {
              final isFav = fav.ids.contains(provider.id);
              return IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => fav.toggleFavorite(provider.id, providerName: provider.name),
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? AppColors.emergencyColor : AppColors.greyColor),
              );
            }),
        ],
      ),
    );
  }
}
