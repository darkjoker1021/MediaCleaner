import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MediaShellController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  void goToVideo() {
    currentPage.value = 1;
    pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void goToPhoto() {
    currentPage.value = 0;
    pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
