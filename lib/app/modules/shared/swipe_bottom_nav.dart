import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/i_media_controller.dart';

/// Bottom navigation bar shared between photo and video swiper screens.
///
/// Shows kept/trash counts with badges, a central undo button, and routes
/// to the respective list screens. All parameters except [ctrl] are optional.
class SwipeBottomNav extends StatelessWidget {
  final IMediaController ctrl;
  final String keptLabel;
  final String trashLabel;
  final VoidCallback onKept;
  final VoidCallback onTrash;

  /// Called immediately after a successful undo action (use for snackbars, etc.)
  final VoidCallback? onAfterUndo;

  const SwipeBottomNav({
    super.key,
    required this.ctrl,
    required this.onKept,
    required this.onTrash,
    this.keptLabel = 'Mantenute',
    this.trashLabel = 'Cestino',
    this.onAfterUndo,
  });

  void _handleUndo() {
    if (!ctrl.undoLastAction()) return;
    HapticFeedback.selectionClick();
    onAfterUndo?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final kept       = ctrl.keptCount.value;
      final trash      = ctrl.trashCount.value;
      final undoActive = ctrl.canUndo.value;

      final theme = Theme.of(context);
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Expanded(child: _navItem(
            context: context,
            icon: FluentIcons.heart_20_filled,
            label: keptLabel,
            badge: kept > 0 ? '$kept' : null,
            color: const Color(0xFF34C759),
            onTap: onKept,
          )),
          GestureDetector(
            onTap: undoActive ? _handleUndo : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: undoActive
                    ? const Color(0xFF0A84FF)
                    : theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: undoActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Icon(
                FluentIcons.arrow_reply_20_filled,
                color: undoActive
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                size: 22,
              ),
            ),
          ),
          Expanded(child: _navItem(
            context: context,
            icon: FluentIcons.delete_20_filled,
            label: trashLabel,
            badge: trash > 0 ? '$trash' : null,
            color: const Color(0xFFFF3B30),
            onTap: onTrash,
          )),
        ]),
      );
    });
  }

  Widget _navItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? badge,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(
              icon,
              color: badge != null
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
              size: 22,
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: badge != null
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      );
}

/// Swipe direction hints row: "← Cestino   N   Mantieni →".
/// Hides automatically when there are no pending items.
class SwipeActionHints extends StatelessWidget {
  final IMediaController ctrl;

  const SwipeActionHints({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // allItems.refresh() is called after every swipe, so pendingCount is reactive
      if (ctrl.pendingCount == 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
        child: Row(children: [
          _hint('← Cestino', const Color(0xFFFF3B30)),
          const Spacer(),
          Text(
            '${ctrl.pendingCount}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              fontSize: 22,
              fontWeight: FontWeight.w300,
            ),
          ),
          const Spacer(),
          _hint('Mantieni →', const Color(0xFF34C759)),
        ]),
      );
    });
  }

  Widget _hint(String text, Color color) => Text(
        text,
        style: TextStyle(
          color: color.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );
}
