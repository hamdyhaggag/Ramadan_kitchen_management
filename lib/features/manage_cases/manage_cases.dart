import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import '../../core/services/service_locator.dart';
import '../donation/presentation/cubit/donation_cubit.dart';
import '../donation/presentation/views/widgets/editable_donation_section.dart';
import '../donation/presentation/views/donation_section.dart';
import 'logic/cases_cubit.dart';
import 'logic/cases_state.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';

import 'manage_case-details_screen.dart';

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
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      unselectedLabelColor: AppColors.greyColor,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                        return states.contains(WidgetState.focused)
                            ? null
                            : Colors.transparent;
                      }),
                      dividerColor: Colors.transparent,
                      labelStyle: TextStyle(
                          color: AppColors.primaryColor,
                          fontFamily: 'DIN',
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      indicatorColor: AppColors.primaryColor,
                      controller: _tabController,
                      tabs: const [
                        Tab(
                          text: 'الحالات',
                          // icon: Icon(Icons.assignment),
                        ),
                        Tab(
                          text: 'التبرعات',
                          // icon: Icon(Icons.volunteer_activism),
                        ),
                      ],
                    ),
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
                              if (state.donations.isNotEmpty) {
                                final donationData = state.donations.first;
                                final documentId = donationData['id'] as String;

                                return EditableDonationSection(
                                  donationData: donationData,
                                  documentId: documentId,
                                );
                              } else {
                                return const Center(
                                    child: Text('No donations available'));
                              }
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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: _FilterModalContent(
          currentFilter: selectedFilter,
          currentValue: selectedFilterValue,
          onFilterChanged: (newFilter, newValue) {
            setState(() {
              selectedFilter = newFilter;
              selectedFilterValue = newValue;
            });
          },
          filterOptions: filterOptions,
        ),
      ),
    );
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
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        dividerThickness: 0.2,
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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(Icons.filter_list, color: AppColors.primaryColor),
            label: Text(
              selectedFilter == null
                  ? "الفلتر"
                  : "${filterOptions[selectedFilter]} - ${_getValueText(selectedFilterValue)}",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: isPortrait ? 16 : 18,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              side: BorderSide(color: AppColors.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _showFilterModal,
          ),
        ),
        if (selectedFilter != null)
          IconButton(
            icon: Icon(Icons.clear, color: Colors.red),
            onPressed: () => setState(() {
              selectedFilter = null;
              selectedFilterValue = null;
            }),
          ),
      ],
    );
  }

  String _getValueText(bool? value) {
    if (value == null) return "الكل";
    return value ? "نعم" : "لا";
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
    List<Map<String, dynamic>> sortedCases = List.from(filteredCases);

    sortedCases.sort((a, b) {
      final numA = int.tryParse(a["الرقم"].toString()) ?? 0;
      final numB = int.tryParse(b["الرقم"].toString()) ?? 0;
      return numA.compareTo(numB);
    });

    return sortedCases.map((caseItem) {
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

class _FilterModalContent extends StatefulWidget {
  final String? currentFilter;
  final bool? currentValue;
  final Function(String?, bool?) onFilterChanged;
  final Map<String, String> filterOptions;

  const _FilterModalContent({
    required this.currentFilter,
    required this.currentValue,
    required this.onFilterChanged,
    required this.filterOptions,
  });

  @override
  State<_FilterModalContent> createState() => _FilterModalContentState();
}

class _FilterModalContentState extends State<_FilterModalContent> {
  late String? selectedFilter;
  late bool? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.currentFilter;
    selectedValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final hasFilterSelected = selectedFilter != null;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModalHeader(theme),
          const SizedBox(height: 24),
          _buildFilterTypeSection(theme, isDarkMode),
          const SizedBox(height: 24),
          _buildValueSection(theme, hasFilterSelected),
          const SizedBox(height: 32),
          _buildActionButtons(theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildModalHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'تصفية الحالات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, size: 24, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildFilterTypeSection(ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'اختر نوع التصفية',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SegmentedButton<String?>(
          segments: [
            ...widget.filterOptions.entries.map((e) => ButtonSegment(
                  value: e.key,
                  label: Text(e.value),
                  icon: const Icon(Icons.filter_alt_outlined),
                )),
            const ButtonSegment(
              value: null,
              label: Text('الكل'),
              icon: Icon(Icons.all_inclusive),
            ),
          ],
          selected: {selectedFilter},
          onSelectionChanged: (Set<String?> newSelection) {
            setState(() {
              selectedFilter = newSelection.first;
              if (selectedFilter == null) selectedValue = null;
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return theme.colorScheme.primary.withValues(alpha: 0.1);
              }
              return Colors.transparent;
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          multiSelectionEnabled: false,
        ),
      ],
    );
  }

  Widget _buildValueSection(ThemeData theme, bool hasFilterSelected) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: hasFilterSelected
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'اختر القيمة',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedValue == null
                          ? 'عرض الكل'
                          : selectedValue!
                              ? 'نعم'
                              : 'لا',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Row(
                      children: [
                        ToggleButtons(
                          isSelected: [
                            selectedValue == true,
                            selectedValue == false,
                            selectedValue == null,
                          ],
                          onPressed: (index) {
                            setState(() {
                              selectedValue = index == 0
                                  ? true
                                  : index == 1
                                      ? false
                                      : null;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          constraints: const BoxConstraints(
                            minHeight: 40,
                            minWidth: 56,
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('نعم'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('لا'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('الكل'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: GeneralButton(
              onPressed: () {
                setState(() {
                  selectedFilter = null;
                  selectedValue = null;
                });
              },
              text: 'إعادة تعيين',
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.5),
              textColor: AppColors.whiteColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GeneralButton(
              onPressed: () {
                widget.onFilterChanged(selectedFilter, selectedValue);
                Navigator.pop(context);
              },
              text: 'تطبيق التصفية',
              backgroundColor: AppColors.primaryColor,
              textColor: AppColors.whiteColor),
        )
      ],
    );
  }
}
