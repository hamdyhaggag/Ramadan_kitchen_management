import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Statistics')),
      body: Column(
        children: [
          Text('Distribution Progress'),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: 60, title: 'Distributed'),
                  PieChartSectionData(value: 40, title: 'Not Distributed'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Generate statistics report
        },
        child: Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
