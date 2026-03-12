import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

// â”€â”€ Page data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

// â”€â”€ View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  static const _pages = [
    _OPage(
      icon: FluentIcons.image_20_filled,
      color: Color(0xFF0A84FF),
      title: 'Benvenuto in\nMedia Cleaner',
      subtitle:
          'Libera spazio velocemente revisionando le tue foto e video con un semplice swipe.',
    ),
    _OPage(
      icon: FluentIcons.arrow_swap_20_filled,
      color: Color(0xFF34C759),
      title: 'Swipe per\nordinarle',
      subtitle:
          'Scorri a destra per mantenere, a sinistra per mettere nel cestino. Come Tinder, ma per le foto!',
    ),
    _OPage(
      icon: FluentIcons.scan_type_20_filled,
      color: Color(0xFFFF9F0A),
      title: 'Categorie\nspeciali',
      subtitle:
          'Trova duplicati, screenshot, media social, foto sfocate e sequenze burst in un click.',
    ),
    _OPage(
      icon: FluentIcons.shield_checkmark_20_filled,
      color: Color(0xFF5AC8FA),
      title: 'Privacy\ngarantita',
      subtitle:
          'Tutto avviene sul tuo dispositivo. Nessun dato viene caricato online.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Column(children: [
          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
              child: GestureDetector(
                onTap: controller.finish,
                child: Text(
                  'Salta',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          // Pages
          Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (ctx, i) => _buildPage(_pages[i]),
            ),
          ),
          // Dots
          _Dots(pages: _pages, currentPage: controller.currentPage),
          const SizedBox(height: 24),
          // Next / Inizia button
          Obx(() => Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: GestureDetector(
              onTap: () => controller.next(_pages.length),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: _pages[controller.currentPage.value].color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _pages[controller.currentPage.value]
                          .color
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  controller.currentPage.value == _pages.length - 1
                      ? 'Inizia!'
                      : 'Continua',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _buildPage(_OPage page) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: page.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: page.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: page.icon != FluentIcons.image_20_filled
              ? Icon(page.icon, color: page.color, size: 50)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        const SizedBox(height: 40),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          page.subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 15,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

// â”€â”€ Dots indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Dots extends StatelessWidget {
  final List<_OPage> pages;
  final RxInt currentPage;

  const _Dots({required this.pages, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pages.length, (i) {
        final isActive = i == currentPage.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? pages[currentPage.value].color
                : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    ));
  }
}
