import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import '../home/presentation/case-details_screen.dart';

class ManageCasesScreen extends StatefulWidget {
  const ManageCasesScreen({super.key});

  @override
  State<ManageCasesScreen> createState() => _ManageCasesScreenState();
}

class _ManageCasesScreenState extends State<ManageCasesScreen> {
  List<Map<String, dynamic>> casesData = [
    {
      "الرقم": 1,
      "الاسم": "أحمد علي",
      "عدد الأفراد": 4,
      "جاهزة": true,
      "هنا؟": true
    },
    {
      "الرقم": 2,
      "الاسم": "محمد محمود",
      "عدد الأفراد": 3,
      "جاهزة": false,
      "هنا؟": false
    },
    {
      "الرقم": 3,
      "الاسم": "سارة عبد الله",
      "عدد الأفراد": 5,
      "جاهزة": true,
      "هنا؟": false
    },
  ];

  void _navigateToManageDetails() async {
    final updatedCases = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageCaseDetailsScreen(casesData: casesData),
      ),
    );
    if (updatedCases != null) {
      setState(() {
        casesData = updatedCases;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحالات'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "جدول الحالات",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(Colors.grey.shade200),
                  columns: const [
                    DataColumn(label: Text("الرقم")),
                    DataColumn(label: Text("الاسم")),
                    DataColumn(label: Text("عدد الأفراد")),
                    DataColumn(label: Text("جاهزة")),
                    DataColumn(label: Text("هنا؟")),
                  ],
                  rows: casesData.map((caseItem) {
                    return DataRow(
                      cells: [
                        DataCell(Text(caseItem["الرقم"].toString())),
                        DataCell(Text(caseItem["الاسم"])),
                        DataCell(Text(caseItem["عدد الأفراد"].toString())),
                        DataCell(
                          Icon(
                            caseItem["جاهزة"]
                                ? Icons.check_circle
                                : Icons.cancel,
                            color:
                                caseItem["جاهزة"] ? Colors.green : Colors.red,
                          ),
                        ),
                        DataCell(
                          Icon(
                            caseItem["هنا؟"]
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: caseItem["هنا؟"] ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToManageDetails,
              child: const Text(
                'إدارة القيم',
                style: TextStyle(color: AppColors.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
