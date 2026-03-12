import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_cleaner/app/routes/app_pages.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';

/// Manages onboarding page state and the "mark as done" side-effect.
/// Business logic is kept here so [OnboardingView] stays declarative.
class OnboardingController extends GetxController {
  late final PageController pageController;
  final currentPage = 0.obs;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
    ThemeHelper.applySystemUI(ThemeMode.dark);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) => currentPage.value = index;

  void next(int totalPages) {
    if (currentPage.value < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      finish();
    }
  }

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    Get.offAllNamed(Routes.HOME);
  }
}
