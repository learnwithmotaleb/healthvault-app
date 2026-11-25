import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../../../../widget/provider_tile.dart';
import '../controller/favourite_controller.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = FavouriteController.to;
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.favourite.tr),
      body: Obx(() => AsyncList(
            loading: c.isLoading.value,
            error: c.error.value,
            isEmpty: c.favorites.isEmpty,
            onRefresh: c.fetchFavorites,
            empty: EmptyView(
              icon: Icons.favorite_border,
              title: 'No favorites yet'.tr,
              subtitle: 'Tap the heart on a provider to save it here.'.tr,
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: c.favorites.length,
              itemBuilder: (_, i) {
                final p = c.favorites[i].provider;
                if (p == null) return const SizedBox.shrink();
                return ProviderTile(provider: p);
              },
            ),
          )),
    );
  }
}
