import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  final List<Map<String, String>> reports = [
    {'name': 'Cases Report', 'date': '2025-01-01'},
    {'name': 'Expenses Report', 'date': '2025-01-02'},
  ];

  ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reports')),
      body: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return ListTile(
            title: Text(report['name']!),
            subtitle: Text('Date: ${report['date']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () {
                    // Download report logic
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    // Share report logic
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
