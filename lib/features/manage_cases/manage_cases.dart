import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import '../../core/widgets/general_button.dart';
import '../../core/cache/prefs.dart';
import 'case-details_screen.dart';

class ManageCasesScreen extends StatefulWidget {
  const ManageCasesScreen({super.key});

  @override
  State<ManageCasesScreen> createState() => _ManageCasesScreenState();
}

class _ManageCasesScreenState extends State<ManageCasesScreen> {
  List<Map<String, dynamic>> casesData = [];
  String? selectedFilter;
  bool? selectedFilterValue;

  final Map<String, String> filterOptions = {
    "جاهزة": "جاهزة",
    "هنا؟": "هنا؟",
  };

  @override
  void initState() {
    super.initState();
    loadCasesData();
  }

  void loadCasesData() {
    final cachedCases = Prefs.getString('casesData');
    if (cachedCases.isNotEmpty) {
      casesData = List<Map<String, dynamic>>.from(jsonDecode(cachedCases));
    } else {
      casesData = [
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
          "عدد الأفراد": 8,
          "جاهزة": true,
          "هنا؟": false
        },
      ];
      saveCasesData();
    }
  }

  void saveCasesData() {
    Prefs.setString('casesData', jsonEncode(casesData));
  }

  List<Map<String, dynamic>> get filteredCases {
    if (selectedFilter == null || selectedFilterValue == null) {
      return casesData;
    }
    return casesData.where((caseItem) {
      return caseItem[selectedFilter] == selectedFilterValue;
    }).toList();
  }

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
        saveCasesData();
      });
    }
  }

  void _showConfirmationDialog(
      String name, String field, bool currentValue, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "تأكيد التغيير",
            style: TextStyle(color: AppColors.blackColor),
          ),
          content: Text(
            "هل أنت متأكد أنك تريد تغيير حالة \"$field\" لـ \"$name\"؟",
            style: TextStyle(color: AppColors.blackColor, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "إلغاء",
                style: TextStyle(color: AppColors.blackColor, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text(
                "تأكيد",
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "جدول الحالات",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                DropdownButton<String?>(
                  value: selectedFilter,
                  hint: const Text("اختر نوع الفلتر"),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: const Text("إلغاء الفلتر"),
                    ),
                    ...filterOptions.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value;
                      selectedFilterValue = null;
                    });
                  },
                ),
                const SizedBox(width: 16),
                if (selectedFilter != null)
                  DropdownButton<bool?>(
                    value: selectedFilterValue,
                    hint: const Text("اختر القيمة"),
                    items: const [
                      DropdownMenuItem(value: null, child: Text("الكل")),
                      DropdownMenuItem(value: true, child: Text("نعم")),
                      DropdownMenuItem(value: false, child: Text("لا")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedFilterValue = value;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(Colors.grey.shade200),
                  columns: const [
                    DataColumn(
                        label: Text(
                      "الرقم",
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    )),
                    DataColumn(
                        label: Text(
                      "الاسم",
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    )),
                    DataColumn(
                        label: Text(
                      "عدد الأفراد",
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    )),
                    DataColumn(
                        label: Text(
                      "جاهزة للتوزيع",
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    )),
                    DataColumn(
                        label: Text(
                      "هنا؟",
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    )),
                  ],
                  rows: filteredCases.map((caseItem) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Center(
                            child: Text(
                              caseItem["الرقم"].toString(),
                              style: const TextStyle(
                                  fontSize: 16), // Example font size
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            caseItem["الاسم"],
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              caseItem["عدد الأفراد"].toString(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                _showConfirmationDialog(
                                  caseItem["الاسم"],
                                  "جاهزة",
                                  caseItem["جاهزة"],
                                  () {
                                    setState(() {
                                      caseItem["جاهزة"] = !caseItem["جاهزة"];
                                      saveCasesData();
                                    });
                                  },
                                );
                              },
                              child: Icon(
                                caseItem["جاهزة"]
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: caseItem["جاهزة"]
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                _showConfirmationDialog(
                                  caseItem["الاسم"],
                                  "هنا؟",
                                  caseItem["هنا؟"],
                                  () {
                                    setState(() {
                                      caseItem["هنا؟"] = !caseItem["هنا؟"];
                                      saveCasesData();
                                    });
                                  },
                                );
                              },
                              child: Icon(
                                caseItem["هنا؟"]
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: caseItem["هنا؟"]
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _navigateToManageDetails,
              child: GeneralButton(
                text: 'إدارة الحالات',
                backgroundColor: AppColors.primaryColor,
                textColor: AppColors.whiteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
