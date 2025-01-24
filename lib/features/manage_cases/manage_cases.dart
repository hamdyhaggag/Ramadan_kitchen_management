import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    "جاهزة": "جاهزة للتوزيع",
    "هنا؟": "الشنطة هنا؟",
  };

  @override
  void initState() {
    super.initState();
    loadCasesData();
    // Lock orientation to landscape if tablet, else allow both
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
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

  void _updateCaseState(int index, String field, bool newValue) {
    setState(() {
      casesData[index][field] = newValue;
      saveCasesData();
    });
  }

  void _showConfirmationDialog(
      String name, String field, bool currentValue, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تأكيد التغيير",
              style: TextStyle(color: AppColors.blackColor)),
          content: Text(
            "هل أنت متأكد أنك تريد تغيير حالة \"$field\" لـ \"$name\"؟",
            style: const TextStyle(color: AppColors.blackColor, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء",
                  style: TextStyle(color: AppColors.blackColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text("تأكيد",
                  style: TextStyle(color: AppColors.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: OrientationBuilder(
            builder: (context, orientation) {
              final bool isPortrait = orientation == Orientation.portrait;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // // Header Section
                  // _buildHeaderSection(isPortrait),
                  // const SizedBox(height: 16),

                  // Filter Section
                  _buildFilterSection(isPortrait),
                  const SizedBox(height: 16),

                  // Data Table Section
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(Colors.grey.shade200),
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 60,
                        columnSpacing: isPortrait ? 20 : 40,
                        columns: _buildDataColumns(isPortrait),
                        rows: _buildDataRows(isPortrait),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Manage Cases Button
                  _buildManageButton(isPortrait),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Widget _buildHeaderSection(bool isPortrait) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: Text(
  //           "جدول الحالات",
  //           style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                 fontSize: isPortrait ? 24 : 28,
  //               ),
  //         ),
  //       ),
  //       if (!isPortrait) const Spacer(),
  //     ],
  //   );
  // }

  Widget _buildFilterSection(bool isPortrait) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: isPortrait ? double.infinity : 200,
          child: DropdownButtonFormField<String?>(
            value: selectedFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: AppColors.secondaryColor), // Default border
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: AppColors.secondaryColor), // When enabled
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: AppColors.secondaryColor), // When focused
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryColor, // Match dropdown arrow to border
            ),
            hint: const Text("اختر نوع الفلتر"),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  "إلغاء الفلتر",
                  style: TextStyle(fontSize: isPortrait ? 14 : 16),
                ),
              ),
              ...filterOptions.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(fontSize: isPortrait ? 14 : 16),
                  ),
                );
              }),
            ],
            onChanged: (value) => setState(() {
              selectedFilter = value;
              selectedFilterValue = null;
            }),
          ),
        ),
        if (selectedFilter != null)
          SizedBox(
            width: isPortrait ? double.infinity : 150,
            child: DropdownButtonFormField<bool?>(
              value: selectedFilterValue,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text("اختر القيمة"),
              items: const [
                DropdownMenuItem(value: null, child: Text("الكل")),
                DropdownMenuItem(value: true, child: Text("نعم")),
                DropdownMenuItem(value: false, child: Text("لا")),
              ],
              onChanged: (value) => setState(() => selectedFilterValue = value),
            ),
          ),
      ],
    );
  }

  List<DataColumn> _buildDataColumns(bool isPortrait) {
    return [
      DataColumn(
        label: Text(
          "الرقم",
          style: TextStyle(
            fontSize: isPortrait ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      DataColumn(
        label: Text(
          "الاسم",
          style: TextStyle(
            fontSize: isPortrait ? 16 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      DataColumn(
        label: Text(
          "عدد الأفراد",
          style: TextStyle(
            fontSize: isPortrait ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      DataColumn(
        label: Text(
          "جاهزة للتوزيع",
          style: TextStyle(
            fontSize: isPortrait ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      DataColumn(
        label: Text(
          "الشنطة هنا؟",
          style: TextStyle(
            fontSize: isPortrait ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  List<DataRow> _buildDataRows(bool isPortrait) {
    return filteredCases.map((caseItem) {
      final originalIndex =
          casesData.indexWhere((item) => item["الرقم"] == caseItem["الرقم"]);

      return DataRow(
        cells: [
          DataCell(Center(
            child: Text(
              caseItem["الرقم"].toString(),
              style: TextStyle(fontSize: isPortrait ? 18 : 20),
            ),
          )),
          DataCell(Text(
            caseItem["الاسم"],
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: isPortrait ? 16 : 20),
          )),
          DataCell(Center(
            child: Text(
              caseItem["عدد الأفراد"].toString(),
              style: TextStyle(
                fontSize: isPortrait ? 18 : 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          )),
          DataCell(Center(
            child: IconButton(
              iconSize: isPortrait ? 24 : 28,
              icon: Icon(
                caseItem["جاهزة"] ? Icons.check_circle : Icons.cancel,
                color: caseItem["جاهزة"] ? Colors.green : Colors.red,
              ),
              onPressed: () => _showConfirmationDialog(
                caseItem["الاسم"],
                "جاهزة",
                caseItem["جاهزة"],
                () => _updateCaseState(
                    originalIndex, "جاهزة", !caseItem["جاهزة"]),
              ),
            ),
          )),
          DataCell(Center(
            child: IconButton(
              iconSize: isPortrait ? 24 : 28,
              icon: Icon(
                caseItem["هنا؟"] ? Icons.check_circle : Icons.cancel,
                color: caseItem["هنا؟"] ? Colors.green : Colors.red,
              ),
              onPressed: () => _showConfirmationDialog(
                caseItem["الاسم"],
                "هنا؟",
                caseItem["هنا؟"],
                () =>
                    _updateCaseState(originalIndex, "هنا؟", !caseItem["هنا؟"]),
              ),
            ),
          )),
        ],
      );
    }).toList();
  }

  Widget _buildManageButton(bool isPortrait) {
    return SizedBox(
      width: isPortrait ? double.infinity : null,
      child: GeneralButton(
        text: 'إدارة الحالات',
        backgroundColor: AppColors.primaryColor,
        textColor: AppColors.whiteColor,
        onPressed: _navigateToManageDetails,
      ),
    );
  }
}
