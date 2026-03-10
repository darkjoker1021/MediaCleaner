import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../video/views/video_view.dart';
import '../controllers/media_shell_controller.dart';
import 'home_view.dart';

class MediaShellView extends GetView<MediaShellController> {
  const MediaShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller.pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (page) => controller.currentPage.value = page,
      children: const [
        HomeView(),
        VideoView(),
      ],
    );
  }
}
