import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import 'case-details_screen.dart';
import 'logic/cases_cubit.dart';
import 'logic/cases_state.dart';

class ManageCasesScreen extends StatelessWidget {
  const ManageCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CasesCubit, CasesState>(
        builder: (context, state) {
          if (state is CasesLoading) {
            return const Center(
                child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ));
          }
          if (state is CasesError) {
            return Center(child: Text(state.message));
          }
          if (state is CasesLoaded) {
            return _ManageCasesContent(cases: state.cases);
          }
          return const Center(child: Text('No cases found'));
        },
      ),
    );
  }
}

class _ManageCasesContent extends StatefulWidget {
  final List<Map<String, dynamic>> cases;
  const _ManageCasesContent({required this.cases});

  @override
  State<_ManageCasesContent> createState() => _ManageCasesContentState();
}

class _ManageCasesContentState extends State<_ManageCasesContent> {
  String? selectedFilter;
  bool? selectedFilterValue;
  final Map<String, String> filterOptions = {
    "جاهزة": "جاهزة للتوزيع",
    "هنا؟": "الشنطة هنا؟",
  };

  @override
  void initState() {
    super.initState();
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

  List<Map<String, dynamic>> get filteredCases {
    if (selectedFilter == null || selectedFilterValue == null) {
      return widget.cases;
    }
    return widget.cases
        .where((caseItem) => caseItem[selectedFilter] == selectedFilterValue)
        .toList();
  }

  void _navigateToManageDetails() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageCaseDetailsScreen(),
      ),
    );
    context.read<CasesCubit>().loadCases();
  }

  void _updateCaseState(String docId, String field, bool newValue) {
    context.read<CasesCubit>().updateCaseState(docId, field, newValue);
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: OrientationBuilder(
          builder: (context, orientation) {
            final bool isPortrait = orientation == Orientation.portrait;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterSection(isPortrait),
                const SizedBox(height: 16),
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
                _buildManageButton(isPortrait),
              ],
            );
          },
        ),
      ),
    );
  }

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
                borderSide: BorderSide(color: AppColors.secondaryColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.secondaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.secondaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
            hint: const Text("اختر نوع الفلتر"),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text("إلغاء الفلتر",
                    style: TextStyle(fontSize: isPortrait ? 14 : 16)),
              ),
              ...filterOptions.entries.map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value,
                        style: TextStyle(fontSize: isPortrait ? 14 : 16)),
                  )),
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
        label: Text("الرقم",
            style: TextStyle(
                fontSize: isPortrait ? 16 : 18, fontWeight: FontWeight.bold)),
      ),
      DataColumn(
        label: Text("الاسم",
            style: TextStyle(
                fontSize: isPortrait ? 16 : 16, fontWeight: FontWeight.bold)),
      ),
      DataColumn(
        label: Text("عدد الأفراد",
            style: TextStyle(
                fontSize: isPortrait ? 16 : 18, fontWeight: FontWeight.bold)),
      ),
      DataColumn(
        label: Text("جاهزة للتوزيع",
            style: TextStyle(
                fontSize: isPortrait ? 16 : 18, fontWeight: FontWeight.bold)),
      ),
      DataColumn(
        label: Text("الشنطة هنا؟",
            style: TextStyle(
                fontSize: isPortrait ? 16 : 18, fontWeight: FontWeight.bold)),
      ),
    ];
  }

  List<DataRow> _buildDataRows(bool isPortrait) {
    return filteredCases.map((caseItem) {
      return DataRow(
        cells: [
          DataCell(Center(
            child: Text(caseItem["الرقم"].toString(),
                style: TextStyle(fontSize: isPortrait ? 18 : 20)),
          )),
          DataCell(Text(caseItem["الاسم"],
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isPortrait ? 16 : 20))),
          DataCell(Center(
            child: Text(caseItem["عدد الأفراد"].toString(),
                style: TextStyle(
                    fontSize: isPortrait ? 18 : 20,
                    fontWeight: FontWeight.w700)),
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
                    caseItem['id'], "جاهزة", !caseItem["جاهزة"]),
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
                    _updateCaseState(caseItem['id'], "هنا؟", !caseItem["هنا؟"]),
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
