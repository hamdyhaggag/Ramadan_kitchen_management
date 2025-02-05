import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import '../../core/services/service_locator.dart';
import '../donation/presentation/cubit/donation_cubit.dart';
import '../donation/presentation/views/widgets/editable_donation_section.dart';
import 'case-details_screen.dart';
import '../donation/presentation/views/donation_section.dart';
import 'logic/cases_cubit.dart';
import 'logic/cases_state.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';

class ManageCasesScreen extends StatefulWidget {
  const ManageCasesScreen({super.key});

  @override
  State<ManageCasesScreen> createState() => _ManageCasesScreenState();
}

class _ManageCasesScreenState extends State<ManageCasesScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late bool isAdmin;

  @override
  void initState() {
    super.initState();
    isAdmin = false;

    _checkAdminStatus();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _checkAdminStatus() async {
    final authRepo = getIt<AuthRepo>();
    final bool adminStatus = authRepo.currentUser?.role == 'admin';
    setState(() {
      isAdmin = adminStatus;
      if (isAdmin) {
        _tabController = TabController(length: 2, vsync: this);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isAdmin
          ? SafeArea(
              child: Column(
                children: [
                  TabBar(
                    labelStyle: TextStyle(
                      color: AppColors.primaryColor,
                      fontFamily: 'DIN',
                    ),
                    indicatorColor: AppColors.primaryColor,
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.assignment), text: 'الحالات'),
                      Tab(
                          icon: Icon(Icons.volunteer_activism),
                          text: 'التبرعات'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        BlocBuilder<CasesCubit, CasesState>(
                          builder: (context, state) {
                            if (state is CasesLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryColor,
                                ),
                              );
                            }
                            if (state is CasesError) {
                              return Center(child: Text(state.message));
                            }
                            if (state is CasesLoaded) {
                              return _ManageCasesContent(
                                cases: state.cases,
                                isAdmin: isAdmin,
                              );
                            }
                            return const Center(child: Text('لا توجد حالات'));
                          },
                        ),
                        BlocBuilder<DonationCubit, DonationState>(
                          builder: (context, state) {
                            if (state is DonationLoaded) {
                              return EditableDonationSection(
                                donationData: state.donationData,
                                documentId: state.documentId,
                              );
                            }
                            if (state is DonationError) {
                              return Center(child: Text(state.message));
                            }
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const DonationSection(),
    );
  }
}

class _ManageCasesContent extends StatefulWidget {
  final List<Map<String, dynamic>> cases;
  final bool isAdmin;
  const _ManageCasesContent({required this.cases, required this.isAdmin});

  @override
  State<_ManageCasesContent> createState() => _ManageCasesContentState();
}

class _ManageCasesContentState extends State<_ManageCasesContent> {
  String? selectedFilter;
  bool? selectedFilterValue;
  final Map<String, String> filterOptions = {
    "جاهزة": "جاهزة للتوزيع",
    "هنا؟": "الشنطة هنا؟"
  };

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
            builder: (context) => const ManageCaseDetailsScreen()));
    context.read<CasesCubit>().loadCases();
  }

  void _showConfirmationDialog(
      String name, String field, bool currentValue, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.whiteColor,
        title: const Text("تأكيد التغيير",
            style: TextStyle(color: AppColors.blackColor)),
        content: Text(
            "هل أنت متأكد أنك تريد تغيير حالة \"$field\" لـ \"$name\"؟",
            style: const TextStyle(color: AppColors.blackColor, fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء",
                  style: TextStyle(color: AppColors.blackColor))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text("تأكيد",
                  style: TextStyle(color: AppColors.primaryColor))),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.whiteColor,
        title: const Text("تأكيد إعادة التعيين",
            style: TextStyle(color: AppColors.blackColor)),
        content: const Text(
            "هل أنت متأكد من أنك تريد إعادة تعيين جميع الحالات لليوم الجديد؟",
            style: TextStyle(color: AppColors.blackColor, fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء",
                  style: TextStyle(color: AppColors.blackColor))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<CasesCubit>().resetAllCases();
              },
              child: const Text("تأكيد",
                  style: TextStyle(color: AppColors.primaryColor))),
        ],
      ),
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
                if (!widget.isAdmin) _buildPermissionBanner(),
                const SizedBox(height: 8),
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
                Row(
                  children: [
                    Expanded(
                      child: GeneralButton(
                        text: 'بدء يوم جديد',
                        backgroundColor: widget.isAdmin
                            ? AppColors.secondaryColor
                            : Colors.grey,
                        textColor: AppColors.whiteColor,
                        onPressed: () {
                          if (widget.isAdmin) {
                            _showResetConfirmation();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('لا تمتلك الصلاحية لبدء يوم جديد'),
                                  duration: Duration(seconds: 2)),
                            );
                          }
                        },
                      ),
                    ),
                    if (widget.isAdmin) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: GeneralButton(
                          text: 'إدارة الحالات',
                          backgroundColor: AppColors.primaryColor,
                          textColor: AppColors.whiteColor,
                          onPressed: _navigateToManageDetails,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.primaryColor, size: 18),
          const SizedBox(width: 8),
          Text("بعض المعلومات مخفية بسبب الصلاحيات المحدودة",
              style: TextStyle(color: AppColors.primaryColor, fontSize: 14)),
        ],
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
                  borderSide: BorderSide(color: AppColors.greyColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.greyColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.greyColor)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.greyColor),
            hint: const Text("اختر نوع الفلتر"),
            items: [
              DropdownMenuItem(
                  value: null,
                  child: Text("إلغاء الفلتر",
                      style: TextStyle(fontSize: isPortrait ? 14 : 16))),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  fontSize: isPortrait ? 16 : 18,
                  fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text("الاسم",
              style: TextStyle(
                  fontSize: isPortrait ? 16 : 16,
                  fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text("عدد الأفراد",
              style: TextStyle(
                  fontSize: isPortrait ? 16 : 18,
                  fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text("جاهزة للتوزيع",
              style: TextStyle(
                  fontSize: isPortrait ? 16 : 18,
                  fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text("الشنطة هنا؟",
              style: TextStyle(
                  fontSize: isPortrait ? 16 : 18,
                  fontWeight: FontWeight.bold))),
    ];
  }

  List<DataRow> _buildDataRows(bool isPortrait) {
    return filteredCases.map((caseItem) {
      final caseData = Map<String, dynamic>.from(caseItem);
      return DataRow(
        cells: [
          DataCell(Center(
              child: Text(caseData["الرقم"].toString(),
                  style: TextStyle(fontSize: isPortrait ? 18 : 20)))),
          DataCell(
            widget.isAdmin
                ? Text(caseData["الاسم"],
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isPortrait ? 16 : 20))
                : Row(
                    children: [
                      Text("•••••",
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isPortrait ? 16 : 20,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: "مطلوب صلاحيات إدارية لعرض الأسماء",
                        child: Icon(Icons.lock_outline,
                            color: Colors.grey.shade600, size: 16),
                      )
                    ],
                  ),
          ),
          DataCell(Center(
              child: Text(caseData["عدد الأفراد"].toString(),
                  style: TextStyle(
                      fontSize: isPortrait ? 18 : 20,
                      fontWeight: FontWeight.w700)))),
          DataCell(Center(
            child: IconButton(
              iconSize: isPortrait ? 24 : 28,
              icon: Icon(caseData["جاهزة"] ? Icons.check_circle : Icons.cancel,
                  color: caseData["جاهزة"] ? Colors.green : Colors.red),
              onPressed: widget.isAdmin
                  ? () => _showConfirmationDialog(
                        caseData["الاسم"],
                        "جاهزة",
                        caseData["جاهزة"],
                        () => context.read<CasesCubit>().updateCaseState(
                            caseData['id'], "جاهزة", !caseData["جاهزة"]),
                      )
                  : null,
            ),
          )),
          DataCell(Center(
            child: IconButton(
              iconSize: isPortrait ? 24 : 28,
              icon: Icon(caseData["هنا؟"] ? Icons.check_circle : Icons.cancel,
                  color: caseData["هنا؟"] ? Colors.green : Colors.red),
              onPressed: widget.isAdmin
                  ? () => _showConfirmationDialog(
                        caseData["الاسم"],
                        "هنا؟",
                        caseData["هنا؟"],
                        () => context.read<CasesCubit>().updateCaseState(
                            caseData['id'], "هنا؟", !caseData["هنا؟"]),
                      )
                  : null,
            ),
          )),
        ],
      );
    }).toList();
  }
}
