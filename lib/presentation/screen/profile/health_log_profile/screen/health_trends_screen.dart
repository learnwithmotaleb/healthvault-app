import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/app_models.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/health_log_controller.dart';

class HealthTrendsScreen extends StatelessWidget {
  const HealthTrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HealthTrendsController());

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'Health trends'.tr),
      body: RefreshIndicator(
        onRefresh: c.fetch,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Obx(() => ChoiceBar(
                  values: HealthTrendsController.metrics.keys.toList(),
                  labels: HealthTrendsController.metrics.values.map((e) => e.$1.tr).toList(),
                  selected: c.metric.value,
                  onSelected: c.setMetric,
                )),
            Obx(() => ChoiceBar(
                  values: const ['7', '30', '90', '365'],
                  labels: ['7 days'.tr, '30 days'.tr, '3 months'.tr, '1 year'.tr],
                  selected: '${c.days.value}',
                  onSelected: (v) => c.setRange(int.parse(v)),
                )),
            Obx(() => ChoiceBar(
                  values: const ['SELF', 'FAMILY'],
                  labels: ['Myself'.tr, 'Family'.tr],
                  selected: c.forWhom.value,
                  onSelected: (v) {
                    c.forWhom.value = v;
                    c.fetch();
                  },
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Obx(() {
                if (c.isLoading.value) {
                  return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
                }
                if (c.error.value != null) {
                  return SizedBox(height: 260, child: ErrorView(message: c.error.value!, onRetry: c.fetch));
                }
                final keys = c.apiMetrics;
                final pts = c.points.where((p) => keys.any((k) => p.values[k]?.avg != null)).toList();
                if (pts.isEmpty) {
                  return SizedBox(
                    height: 260,
                    child: EmptyView(icon: Icons.show_chart, title: 'No measurements in this period'.tr),
                  );
                }
                final unit = HealthTrendsController.metrics[c.metric.value]!.$2;
                return Column(children: [
                  HVCardBox(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    child: SizedBox(height: 260, child: _Chart(points: pts, keys: keys)),
                  ),
                  if (keys.length == 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _legend(_colors[0], 'Systolic'.tr),
                        const SizedBox(width: 16),
                        _legend(_colors[1], 'Diastolic'.tr),
                      ]),
                    ),
                  SectionTitle('Summary'.tr),
                  ...keys.map((k) => _StatsRow(points: pts, metricKey: k, unit: unit)),
                ]);
              }),
            ),
          ],
        ),
      ),
    );
  }

  static const _colors = [AppColors.primaryColor, AppColors.emergencyColor];

  static Widget _legend(Color c, String t) => Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(t, style: AppTextStyles.body.copyWith(fontSize: 12)),
      ]);
}

class _Chart extends StatelessWidget {
  final List<TrendPoint> points;
  final List<String> keys;
  const _Chart({required this.points, required this.keys});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    final bars = <LineChartBarData>[];
    double minY = double.infinity, maxY = -double.infinity;
    for (var k = 0; k < keys.length; k++) {
      final spots = <FlSpot>[];
      for (var i = 0; i < points.length; i++) {
        final v = points[i].values[keys[k]]?.avg;
        if (v == null) continue;
        spots.add(FlSpot(i.toDouble(), v.toDouble()));
        if (v < minY) minY = v.toDouble();
        if (v > maxY) maxY = v.toDouble();
      }
      bars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        preventCurveOverShooting: true,
        color: HealthTrendsScreen._colors[k % 2],
        barWidth: 3,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: keys.length == 1, color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ));
    }
    final pad = ((maxY - minY).abs() * 0.15).clamp(1, 50).toDouble();
    final step = (points.length / 5).ceil().clamp(1, 1000);
    return LineChart(LineChartData(
      minY: (minY - pad).floorToDouble(),
      maxY: (maxY + pad).ceilToDouble(),
      lineBarsData: bars,
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 26,
            getTitlesWidget: (v, m) {
              final i = v.toInt();
              if (i < 0 || i >= points.length || i % step != 0 || v != i.toDouble()) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(points[i].period == null ? '' : fmt.format(points[i].period!), style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
    ));
  }
}

class _StatsRow extends StatelessWidget {
  static String _label(String k) {
    if (k == 'systolic') return 'Systolic'.tr;
    if (k == 'diastolic') return 'Diastolic'.tr;
    return (HealthTrendsController.metrics[k]?.$1 ?? k).tr;
  }

  final List<TrendPoint> points;
  final String metricKey;
  final String unit;
  const _StatsRow({required this.points, required this.metricKey, required this.unit});

  @override
  Widget build(BuildContext context) {
    final stats = points.map((p) => p.values[metricKey]).whereType<TrendStat>().toList();
    num? min, max;
    num sum = 0;
    int n = 0;
    for (final s in stats) {
      if (s.min != null && (min == null || s.min! < min)) min = s.min;
      if (s.max != null && (max == null || s.max! > max)) max = s.max;
      if (s.avg != null) {
        sum += s.avg!;
        n++;
      }
    }
    final avg = n == 0 ? null : sum / n;
    Widget cell(String l, num? v) => Expanded(
          child: Column(children: [
            Text(v == null ? '-' : HealthLogModel.fmt(v), style: AppTextStyles.title.copyWith(fontSize: 16)),
            Text(l, style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
          ]),
        );
    return HVCardBox(
      child: Column(children: [
        Text("${_label(metricKey)} ($unit)", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [cell('Average'.tr, avg), cell('Lowest'.tr, min), cell('Highest'.tr, max)]),
      ]),
    );
  }
}
