import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  final List<String> names;
  final List<bool> checkboxValues;
  final List<int> serialNumbers;
  final List<int> numberOfIndividuals;

  const StatisticsScreen({
    super.key,
    required this.names,
    required this.checkboxValues,
    required this.serialNumbers,
    required this.numberOfIndividuals,
  });

  @override
  Widget build(BuildContext context) {
    int totalIndividuals = calculateTotalIndividuals(numberOfIndividuals);
    int totalCheckedIndividuals =
        calculateTotalCheckedIndividuals(checkboxValues, numberOfIndividuals);
    int totalUndistributed = totalIndividuals - totalCheckedIndividuals;
    double progressPercentage =
        calculateProgress(checkboxValues, numberOfIndividuals) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات التوزيع',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalCheckedIndividuals.toDouble(),
                      title: 'تم التوزيع',
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: totalUndistributed.toDouble(),
                      title: 'لم يتم التوزيع',
                      color: Colors.red,
                    ),
                  ],
                  centerSpaceRadius: 50,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'إجمالي عدد الأفراد: $totalIndividuals',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'نسبة الإكتمال: ${progressPercentage.toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'عدد الشنط المتبقية: ${calculateTotalSerialNumbers(checkboxValues)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'عدد الأفراد المتبقي: $totalUndistributed',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Utility methods for calculations
  int calculateTotalIndividuals(List<int> numberOfIndividuals) =>
      numberOfIndividuals.reduce((value, element) => value + element);

  int calculateTotalSerialNumbers(List<bool> checkboxValues) =>
      checkboxValues.where((value) => !value).length;

  int calculateTotalCheckedIndividuals(
      List<bool> checkboxValues, List<int> numberOfIndividuals) {
    int totalChecked = 0;
    for (int i = 0; i < checkboxValues.length; i++) {
      if (checkboxValues[i]) totalChecked += numberOfIndividuals[i];
    }
    return totalChecked;
  }

  double calculateProgress(
      List<bool> checkboxValues, List<int> numberOfIndividuals) {
    int totalIndividuals = calculateTotalIndividuals(numberOfIndividuals);
    int totalChecked =
        calculateTotalCheckedIndividuals(checkboxValues, numberOfIndividuals);
    return totalIndividuals == 0 ? 0.0 : totalChecked / totalIndividuals;
  }
}
