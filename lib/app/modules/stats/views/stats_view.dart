import 'package:fl_chart/fl_chart.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/stats/controllers/stats_controller.dart';
import 'package:media_cleaner/app/modules/shared/media_app_bar.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';

class StatsView extends GetView<StatsController> {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeHelper.overlayStyle(context),
      child: Scaffold(
        body: SafeArea(
          child: Obx(() => ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              _appBar(),
              const SizedBox(height: 20),
              _heroCard(),
              const SizedBox(height: 16),
              _row([
                _statCard('Foto mantenute', '${controller.photoKeptCount.value}',
                    FluentIcons.heart_20_filled, const Color(0xFF34C759)),
                _statCard('Foto nel cestino', '${controller.photoTrashCount.value}',
                    FluentIcons.delete_20_filled, const Color(0xFFFF3B30)),
              ]),
              const SizedBox(height: 12),
              _row([
                _statCard('Video mantenuti', '${controller.videoKeptCount.value}',
                    FluentIcons.video_20_filled, const Color(0xFF0A84FF)),
                _statCard('Video nel cestino', '${controller.videoTrashCount.value}',
                    FluentIcons.delete_20_filled, const Color(0xFFFF9F0A)),
              ]),
              const SizedBox(height: 20),
              if (controller.totalProcessed > 0) ...[
                _sectionTitle('Distribuzione media'),
                const SizedBox(height: 12),
                _pieChartCard(),
                const SizedBox(height: 20),
              ],
              if (controller.totalFreedBytes > 0) ...[
                _sectionTitle('Spazio liberato'),
                const SizedBox(height: 12),
                _barChartCard(),
              ],
            ],
          )),
        ),
      ),
    );
  }

  Widget _appBar() => MediaAppBar(
    title: 'Statistiche',
    titleSize: 22,
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
  );

  Widget _heroCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0A84FF), Color(0xFF0050C3)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Spazio totale liberato',
          style: TextStyle(color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 8),
      Text(controller.fmt(controller.totalFreedBytes),
          style: const TextStyle(color: Colors.white, fontSize: 36,
              fontWeight: FontWeight.w900, letterSpacing: -1)),
      const SizedBox(height: 12),
      Row(children: [
        _heroTag('${controller.totalKeptCount} mantenuti', const Color(0xFF34C759)),
        const SizedBox(width: 8),
        _heroTag('${controller.totalTrashCount} nel cestino', const Color(0xFFFF3B30)),
      ]),
    ]),
  );

  Widget _heroTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white,
          fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _row(List<Widget> children) => Row(children: [
    Expanded(child: children[0]),
    const SizedBox(width: 12),
    Expanded(child: children[1]),
  ]);

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Get.theme.dividerColor)),
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: Get.theme.colorScheme.onSurface,
            fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 10)),
      ])),
    ]),
  );

  Widget _sectionTitle(String title) => Text(title,
      style: TextStyle(color: Get.theme.colorScheme.onSurface,
          fontSize: 16, fontWeight: FontWeight.w700));

  Widget _pieChartCard() {
    final kept  = (controller.totalKeptCount).toDouble();
    final trash = (controller.totalTrashCount).toDouble();
    final total = kept + trash;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Get.theme.dividerColor)),
      child: Row(children: [
        SizedBox(
          width: 120, height: 120,
          child: PieChart(PieChartData(
            sections: [
              PieChartSectionData(
                value: kept,
                color: const Color(0xFF34C759),
                title: '${(kept / total * 100).toStringAsFixed(0)}%',
                titleStyle: const TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w700),
                radius: 50,
              ),
              PieChartSectionData(
                value: trash,
                color: const Color(0xFFFF3B30),
                title: '${(trash / total * 100).toStringAsFixed(0)}%',
                titleStyle: const TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w700),
                radius: 50,
              ),
            ],
            centerSpaceRadius: 0,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(const Color(0xFF34C759), 'Mantenuti', '${controller.totalKeptCount}'),
            const SizedBox(height: 10),
            _legend(const Color(0xFFFF3B30), 'Cestino', '${controller.totalTrashCount}'),
          ],
        )),
      ]),
    );
  }

  Widget _legend(Color color, String label, String value) => Row(children: [
    Container(width: 12, height: 12,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 8),
    Text(label, style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
    const Spacer(),
    Text(value, style: TextStyle(color: Get.theme.colorScheme.onSurface,
        fontSize: 13, fontWeight: FontWeight.w700)),
  ]);

  Widget _barChartCard() {
    final pFreed = controller.photoFreedBytes.value.toDouble();
    final vFreed = controller.videoFreedBytes.value.toDouble();
    final maxVal = [pFreed, vFreed].reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Get.theme.dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 140,
          child: BarChart(BarChartData(
            maxY: maxVal * 1.3,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  const labels = ['Foto', 'Video'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[value.toInt()],
                        style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                  );
                },
              )),
            ),
            barGroups: [
              BarChartGroupData(x: 0, barRods: [
                BarChartRodData(toY: pFreed, color: const Color(0xFF0A84FF),
                    width: 32, borderRadius: BorderRadius.circular(6)),
              ]),
              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(toY: vFreed, color: const Color(0xFFFF9F0A),
                    width: 32, borderRadius: BorderRadius.circular(6)),
              ]),
            ],
          )),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _barLabel(const Color(0xFF0A84FF), 'Foto', controller.fmt(controller.photoFreedBytes.value)),
          const Spacer(),
          _barLabel(const Color(0xFFFF9F0A), 'Video', controller.fmt(controller.videoFreedBytes.value)),
        ]),
      ]),
    );
  }

  Widget _barLabel(Color color, String label, String value) => Row(children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6),
    Text('$label: ', style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
    Text(value, style: TextStyle(color: Get.theme.colorScheme.onSurface,
        fontSize: 12, fontWeight: FontWeight.w700)),
  ]);
}
