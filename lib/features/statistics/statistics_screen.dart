import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              _buildPieChart(totalCheckedIndividuals, totalUndistributed),
              const SizedBox(height: 45),
              _buildStatisticsCard(
                  context, 'إجمالي عدد الأفراد', totalIndividuals),
              _buildStatisticsCard(
                context,
                'نسبة الإكتمال',
                double.parse(progressPercentage.toStringAsFixed(2)),
                percentage: true,
              ),
              _buildStatisticsCard(
                context,
                'عدد الشنط المتبقية',
                calculateTotalSerialNumbers(checkboxValues),
              ),
              _buildStatisticsCard(
                context,
                'عدد الأفراد المتبقي',
                totalUndistributed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
    );
  }

  Widget _buildPieChart(int totalChecked, int totalUndistributed) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[200],
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: totalChecked.toDouble(),
              title: 'تم التوزيع\n$totalChecked',
              color: AppColors.primaryColor,
              radius: 100,
              titleStyle: const TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              value: totalUndistributed.toDouble(),
              title: 'لم يتم التوزيع\n$totalUndistributed',
              color: Colors.grey[350],
              radius: 100,
              titleStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
          centerSpaceRadius: 60,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, String title, dynamic value,
      {bool percentage = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              percentage ? '$value%' : '$value',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: percentage ? AppColors.primaryColor : Colors.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }

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
