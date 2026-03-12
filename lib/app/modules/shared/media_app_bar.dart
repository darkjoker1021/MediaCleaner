import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared custom AppBar used across all media screens.
///
/// Parameters:
/// - [title]        — main page title (required)
/// - [subtitle]     — optional subtitle widget shown below title
/// - [badge]        — optional pill badge shown to the right of title
/// - [badgeColor]   — color for the badge pill (default orange)
/// - [onRescan]     — if non-null, a rescan/reload button is shown
/// - [selectButton] — if non-null, a select/cancel toggle button is shown
/// - [titleSize]    — font size for the title (default 20)
/// - [padding]      — outer padding (default `EdgeInsets.fromLTRB(16, 16, 16, 16)`)
class MediaAppBar extends StatelessWidget {
  const MediaAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.badgeColor = const Color(0xFFFF9F0A),
    this.onRescan,
    this.selectButton,
    this.titleSize = 20,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
  });

  final String title;
  final Widget? subtitle;

  /// Text shown inside the badge pill next to the title.
  final String? badge;
  final Color badgeColor;

  /// Callback for the rescan/reload icon button. If null, the button is hidden.
  final VoidCallback? onRescan;

  /// Widget for the select/cancel toggle button. If null, the button is hidden.
  /// Typically an [Obx] wrapping a styled [Container] with text.
  final Widget? selectButton;

  final double titleSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final onSurface = Get.theme.colorScheme.onSurface;
    final btnBg = Get.theme.cardColor;
    final btnIcon = onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                FluentIcons.arrow_left_20_filled,
                color: btnIcon,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
    
          // Title + optional badge + optional subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                ?subtitle,
              ],
            ),
          ),
    
          // Rescan button
          if (onRescan != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRescan,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: btnBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FluentIcons.arrow_sync_20_filled,
                  color: btnIcon,
                  size: 20,
                ),
              ),
            ),
          ],
    
          // Select/cancel toggle
          if (selectButton != null) ...[
            const SizedBox(width: 8),
            selectButton!,
          ],
        ],
      ),
    );
  }
}

/// Helper that builds the standard Select/Cancel toggle button used in many screens.
///
/// - [isSelecting]    — reactive observable bool
/// - [onTap]          — callback (usually `controller.toggleSelectionMode`)
/// - [accentColor]    — the active accent color of this screen
class SelectToggleButton extends StatelessWidget {
  const SelectToggleButton({
    super.key,
    required this.isSelecting,
    required this.onTap,
    required this.accentColor,
  });

  final RxBool isSelecting;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Obx(() => Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelecting.value
                  ? accentColor.withValues(alpha: 0.15)
                  : Get.theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelecting.value
                    ? accentColor.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              isSelecting.value ? 'Annulla' : 'Seleziona',
              style: TextStyle(
                color: isSelecting.value
                    ? accentColor
                    : Get.theme.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          )),
    );
  }
}
