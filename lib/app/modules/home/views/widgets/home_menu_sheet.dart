import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/modules/video/controllers/video_controller.dart';
import 'package:media_cleaner/app/routes/app_pages.dart';
import 'package:media_cleaner/core/theme/theme_controller.dart';

/// Bottom-sheet menu that replaces the side drawer.
/// Call [HomeMenuSheet.show] to open it.
class HomeMenuSheet {
  const HomeMenuSheet._();

  static void show() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: Get.context!,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      useSafeArea: true,
      builder: (_) => const _DraggableSheet(),
    );
  }
}

// ── Draggable wrapper ────────────────────────────────────────────────────────

class _DraggableSheet extends StatefulWidget {
  const _DraggableSheet();

  @override
  State<_DraggableSheet> createState() => _DraggableSheetState();
}

class _DraggableSheetState extends State<_DraggableSheet> {
  final _ctrl = DraggableScrollableController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _ctrl,
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 1.0,
      // expand: false → the widget only occupies its current height,
      // so taps above the sheet hit the modal barrier which dismisses it.
      expand: false,
      snap: true,
      snapSizes: const [0.62],
      builder: (_, sc) => _SheetContent(scrollController: sc, dsController: _ctrl),
    );
  }
}

// ── Sheet body ───────────────────────────────────────────────────────────────

class _SheetContent extends StatelessWidget {
  final ScrollController scrollController;
  final DraggableScrollableController dsController;

  const _SheetContent({
    required this.scrollController,
    required this.dsController,
  });

  @override
  Widget build(BuildContext context) {
    // Obx is the OUTER wrapper so theme/mode changes trigger a full rebuild.
    // AnimatedBuilder.child is cached between drag frames so the expensive
    // content tree (header + scrollview) is NOT rebuilt on every drag pixel —
    // only the Container decoration and topPad SizedBox rebuild during drag.
    return Obx(() {
      final th      = Theme.of(context);
      final mode    = ThemeController.to.themeMode.value;
      final ctrl    = Get.find<HomeController>();
      final isVideo = ctrl.isVideoMode.value;
      final vc      = isVideo ? Get.find<VideoController>() : null;
      final btmPad  = MediaQuery.paddingOf(context).bottom;

      return AnimatedBuilder(
        animation: dsController,
        // ↓ built once per Obx-tick, reused on every drag frame
        child: Column(children: [
          _Header(th: th, isVideo: isVideo),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(16, 20, 16, btmPad + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isVideo) ...[
                    _SectionLabel(th: th, text: 'Strumenti'),
                    const SizedBox(height: 10),
                    _ToolsGrid(th: th),
                    const SizedBox(height: 24),
                  ],
                  _SectionLabel(th: th, text: 'Tema'),
                  const SizedBox(height: 8),
                  _ThemeControl(th: th, current: mode),
                  const SizedBox(height: 24),
                  _SectionLabel(th: th, text: 'Generali'),
                  const SizedBox(height: 8),
                  _GroupedList(th: th, items: [
                    _GroupedItem(
                      th: th,
                      icon: FluentIcons.data_bar_vertical_20_filled,
                      label: 'Statistiche',
                      color: const Color(0xFF0A84FF),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                        Get.toNamed(Routes.STATS);
                      },
                    ),
                    _GroupedItem(
                      th: th,
                      icon: FluentIcons.arrow_clockwise_20_filled,
                      label: isVideo ? 'Ricarica video' : 'Ricarica libreria',
                      color: const Color(0xFF64D2FF),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                        isVideo ? vc!.loadVideos() : ctrl.loadPhotos();
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _SectionLabel(th: th, text: 'Pericoloso'),
                  const SizedBox(height: 8),
                  _GroupedList(th: th, items: [
                    _GroupedItem(
                      th: th,
                      icon: FluentIcons.replay_20_filled,
                      label: 'Reset sessione',
                      color: const Color(0xFFFF9F0A),
                      isDestructive: true,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        isVideo ? vc!.resetSession() : ctrl.resetSession();
                      },
                    ),
                    _GroupedItem(
                      th: th,
                      icon: FluentIcons.delete_dismiss_20_filled,
                      label: 'Reset completo',
                      color: const Color(0xFFFF3B30),
                      isDestructive: true,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        isVideo ? vc!.resetAllStats() : ctrl.resetAllStats();
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ]),
        builder: (context, staticChild) {
          final topInset = MediaQuery.paddingOf(context).top;
          final screenH  = MediaQuery.sizeOf(context).height;
          final sheetPx  = dsController.isAttached ? dsController.pixels : screenH * 0.62;
          final topPad   = (sheetPx - (screenH - topInset)).clamp(0.0, topInset);
          final radius   = (1.0 - topPad / topInset.clamp(1.0, double.infinity)) * 26.0;

          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: th.scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            ),
            child: Column(
              children: [
                SizedBox(height: topPad),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: th.colorScheme.onSurface.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(child: staticChild!),
              ],
            ),
          );
        },
      );
    });
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ThemeData th;
  final bool isVideo;

  const _Header({required this.th, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/icon/icon.png',
              width: 42,
              height: 42,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MediaCleaner',
                  style: TextStyle(
                    color: th.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isVideo ? 'Modalita` Video' : 'Modalita` Foto',
                  style: TextStyle(
                    color: isVideo
                        ? const Color(0xFFFF9F0A).withValues(alpha: 0.8)
                        : const Color(0xFF0A84FF).withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: th.colorScheme.onSurface.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentIcons.dismiss_20_filled,
                size: 13,
                color: th.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final ThemeData th;
  final String text;

  const _SectionLabel({required this.th, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: th.colorScheme.onSurface.withValues(alpha: 0.35),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Grouped list (iOS-style) ──────────────────────────────────────────────────

class _GroupedList extends StatelessWidget {
  final ThemeData th;
  final List<_GroupedItem> items;

  const _GroupedList({required this.th, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: th.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 54,
                endIndent: 0,
                color: th.dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _GroupedItem extends StatelessWidget {
  final ThemeData th;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _GroupedItem({
    required this.th,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDestructive
        ? const Color(0xFFFF3B30)
        : th.colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                FluentIcons.chevron_right_20_regular,
                size: 14,
                color: th.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tools grid ────────────────────────────────────────────────────────────────

class _ToolsGrid extends StatelessWidget {
  final ThemeData th;

  const _ToolsGrid({required this.th});

  static const _tools = [
    (FluentIcons.copy_20_filled,        'Duplicati',  Color(0xFFFF9F0A), Routes.DUPLICATES),
    (FluentIcons.scan_camera_20_filled, 'Screenshot', Color(0xFF5AC8FA), Routes.SCREENSHOT),
    (FluentIcons.eye_off_20_filled,     'Sfocate',    Color(0xFFBF5AF2), Routes.BLUR),
    (FluentIcons.chat_20_filled,        'Social',     Color(0xFF34C759), Routes.SOCIAL),
    (FluentIcons.timer_20_filled,       'Sequenze',   Color(0xFFFF6B35), Routes.BURST),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        for (final t in _tools)
          _ToolCard(th: th, icon: t.$1, label: t.$2, color: t.$3, route: t.$4),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final ThemeData th;
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _ToolCard({
    required this.th,
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: th.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
          Get.toNamed(route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: th.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Theme control ─────────────────────────────────────────────────────────────

class _ThemeControl extends StatelessWidget {
  final ThemeData th;
  final AppThemeMode current;

  const _ThemeControl({required this.th, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: th.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Seg(th: th, icon: Icons.brightness_auto_rounded,      label: 'Auto',   selected: current == AppThemeMode.system, mode: AppThemeMode.system),
          _Seg(th: th, icon: FluentIcons.weather_moon_20_filled,  label: 'Scuro',  selected: current == AppThemeMode.dark,   mode: AppThemeMode.dark),
          _Seg(th: th, icon: FluentIcons.weather_sunny_20_filled, label: 'Chiaro', selected: current == AppThemeMode.light,  mode: AppThemeMode.light),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final ThemeData th;
  final IconData icon;
  final String label;
  final bool selected;
  final AppThemeMode mode;

  const _Seg({
    required this.th,
    required this.icon,
    required this.label,
    required this.selected,
    required this.mode,
  });

  static const _accent = Color(0xFF0A84FF);

  @override
  Widget build(BuildContext context) {
    final c = selected
        ? _accent
        : th.colorScheme.onSurface.withValues(alpha: 0.35);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ThemeController.to.setTheme(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: c,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
