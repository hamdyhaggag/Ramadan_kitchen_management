import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/service_locator.dart';
import '../donation/presentation/cubit/donation_cubit.dart';
import '../donation/presentation/views/widgets/editable_donation_section.dart';
import '../donation/presentation/views/donation_section.dart';
import 'logic/cases_cubit.dart';
import 'logic/cases_state.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import 'manage_case_details_screen.dart';

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
    final authRepo = getIt<AuthRepo>();
    isAdmin = authRepo.currentUser?.role == 'admin';
    if (isAdmin) {
      _tabController = TabController(length: 2, vsync: this);
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
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
                        borderRadius: BorderRadius.circular(16)),
                    child: TabBar(
                      unselectedLabelColor: AppColors.greyColor,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (states) => states.contains(WidgetState.focused)
                              ? null
                              : Colors.transparent),
                      dividerColor: Colors.transparent,
                      labelStyle: TextStyle(
                          color: AppColors.primaryColor,
                          fontFamily: 'DIN',
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      indicatorColor: AppColors.primaryColor,
                      controller: _tabController,
                      tabs: const [Tab(text: 'الحالات'), Tab(text: 'التبرعات')],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        StreamBuilder<Map<String, List<int>>>(
                          stream: getCaseGroupsStream(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: AppColors.primaryColor,
                                  size: 50,
                                ),
                              );
                            }
                            return BlocBuilder<CasesCubit, CasesState>(
                              builder: (context, state) {
                                if (state is CasesLoading) {
                                  return Center(
                                    child: LoadingAnimationWidget
                                        .staggeredDotsWave(
                                      color: AppColors.primaryColor,
                                      size: 50,
                                    ),
                                  );
                                } else if (state is CasesLoaded) {
                                  return _ManageCasesContent(
                                    cases: state.cases,
                                    isAdmin: isAdmin,
                                    caseGroups: snapshot.data!,
                                  );
                                } else if (state is CasesError) {
                                  return Center(child: Text(state.message));
                                } else {
                                  return Container();
                                }
                              },
                            );
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
                                    documentId: documentId);
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
                                    color: AppColors.primaryColor));
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

  Stream<Map<String, List<int>>> getCaseGroupsStream() {
    return FirebaseFirestore.instance
        .collection('caseGroups')
        .snapshots()
        .map((snapshot) {
      final groups = <String, List<int>>{};
      for (var doc in snapshot.docs) {
        groups[doc.id] = List<int>.from(doc.get('caseNumbers') ?? []);
      }
      return groups;
    });
  }
}

class _ManageCasesContent extends StatefulWidget {
  final List<Map<String, dynamic>> cases;
  final bool isAdmin;
  final Map<String, List<int>> caseGroups;
  const _ManageCasesContent(
      {required this.cases, required this.isAdmin, required this.caseGroups});
  @override
  State<_ManageCasesContent> createState() => _ManageCasesContentState();
}

class _ManageCasesContentState extends State<_ManageCasesContent> {
  String? selectedFilter;
  String searchQuery = '';
  dynamic selectedFilterValue;
  final Map<String, String> filterOptions = {
    "جاهزة": "جاهزة للتوزيع",
    "هنا؟": "الشنطة هنا؟",
    "عدد الأفراد": "عدد الأفراد",
    "المجموعة": "المجموعة"
  };
  List<Map<String, dynamic>> get filteredCases {
    List<Map<String, dynamic>> filtered = widget.cases;
    if (selectedFilter != null && selectedFilterValue != null) {
      filtered = filtered.where((caseItem) {
        if (selectedFilter == "المجموعة") {
          final caseNumber = int.tryParse(caseItem["الرقم"].toString());
          return widget.caseGroups[selectedFilterValue]?.contains(caseNumber) ??
              false;
        }
        if (selectedFilter == "عدد الأفراد") {
          final filterNumber = selectedFilterValue as int?;
          final caseNumber = caseItem[selectedFilter] is int
              ? caseItem[selectedFilter]
              : int.tryParse(caseItem[selectedFilter].toString());
          return caseNumber == filterNumber;
        } else {
          return caseItem[selectedFilter] == selectedFilterValue;
        }
      }).toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((caseItem) {
        final name = caseItem["الاسم"].toString().toLowerCase();
        final caseNumber = caseItem["الرقم"].toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase()) ||
            caseNumber.contains(searchQuery.toLowerCase());
      }).toList();
    }
    return filtered;
  }

  Future<void> _exportToExcel(List<Map<String, dynamic>> cases) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Cases'];

      sheet.appendRow([
        'الرقم',
        'الاسم',
        'عدد الأفراد',
        'جاهزة للتوزيع',
        'الشنطة هنا؟',
        'المجموعة'
      ]);

      for (var caseItem in cases) {
        sheet.appendRow([
          caseItem['الرقم'].toString(),
          caseItem['الاسم'],
          caseItem['عدد الأفراد'].toString(),
          caseItem['جاهزة'] ? 'نعم' : 'لا',
          caseItem['هنا؟'] ? 'نعم' : 'لا',
          _getGroupForCase(int.parse(caseItem['الرقم'].toString())) ??
              'غير محدد',
        ]);
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/cases_export.xlsx');
      final fileBytes = excel.save();
      await file.writeAsBytes(fileBytes!);
      await Share.shareXFiles([XFile(file.path)], text: 'تصدير بيانات الحالات');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التصدير: ${e.toString()}')),
      );
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterModalContent(
        currentFilter: selectedFilter,
        currentValue: selectedFilterValue,
        onFilterChanged: (newFilter, newValue) {
          setState(() {
            selectedFilter = newFilter;
            selectedFilterValue = newValue;
          });
        },
        filterOptions: filterOptions,
        caseGroups: widget.caseGroups,
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
      String name, String field, dynamic currentValue, VoidCallback onConfirm) {
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

  late TextEditingController _searchController;
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchQuery = value.trim()),
        decoration: InputDecoration(
          hintStyle: TextStyle(color: Colors.grey.shade600),
          hintText: 'ابحث بالاسم أو الرقم ...', // Updated hint text
          suffixIcon: _searchController.text.isEmpty
              ? IconButton(
                  icon: Icon(Icons.search),
                  color: Colors.grey.shade600,
                  disabledColor: Colors.grey.shade600,
                  onPressed: null)
              : IconButton(
                  icon: Icon(Icons.clear),
                  color: Colors.grey.shade600,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                    FocusScope.of(context).unfocus();
                  },
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.white,
        ),
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
                  fontSize: isPortrait ? 16 : 18),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              side: BorderSide(color: AppColors.primaryColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                  })),
      ],
    );
  }

  String _getValueText(dynamic value) {
    if (value == null) return "الكل";
    if (value is bool) {
      return value ? "نعم" : "لا";
    } else if (value is int) {
      return value.toString();
    } else if (value is String && widget.caseGroups.containsKey(value)) {
      return value;
    }
    return "الكل";
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
      DataColumn(
          label: Text("المجموعة",
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
          DataCell(Text(caseData["الاسم"],
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isPortrait ? 16 : 20,
                  decoration: caseData["جاهزة"]
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationStyle: TextDecorationStyle.solid,
                  color: caseData["جاهزة"] ? Colors.grey : Colors.black))),
          DataCell(Center(
              child: Text(caseData["عدد الأفراد"].toString(),
                  style: TextStyle(
                      fontSize: isPortrait ? 18 : 20,
                      fontWeight: FontWeight.w700)))),
          DataCell(Center(
            child: IconButton(
                iconSize: isPortrait ? 24 : 28,
                icon: Icon(
                    caseData["جاهزة"] ? Icons.check_circle : Icons.cancel,
                    color: caseData["جاهزة"] ? Colors.green : Colors.red),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _showConfirmationDialog(
                    caseData["الاسم"],
                    "جاهزة",
                    caseData["جاهزة"],
                    () => context.read<CasesCubit>().updateCaseState(
                        caseData['id'], "جاهزة", !caseData["جاهزة"]),
                  );
                }),
          )),
          DataCell(Center(
            child: IconButton(
                iconSize: isPortrait ? 24 : 28,
                icon: Icon(caseData["هنا؟"] ? Icons.check_circle : Icons.cancel,
                    color: caseData["هنا؟"] ? Colors.green : Colors.red),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _showConfirmationDialog(
                    caseData["الاسم"],
                    "هنا؟",
                    caseData["هنا؟"],
                    () => context.read<CasesCubit>().updateCaseState(
                        caseData['id'], "هنا؟", !caseData["هنا؟"]),
                  );
                }),
          )),
          DataCell(Center(
              child: Text(
                  _getGroupForCase(int.parse(caseData["الرقم"].toString())) ??
                      "غير محدد",
                  style: TextStyle(fontSize: isPortrait ? 16 : 18)))),
        ],
      );
    }).toList();
  }

  String? _getGroupForCase(int caseNumber) {
    for (var entry in widget.caseGroups.entries) {
      if (entry.value.contains(caseNumber)) {
        return entry.key;
      }
    }
    return null;
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(),
                const SizedBox(height: 16),
                _buildFilterSection(isPortrait),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        dividerThickness: 0.2,
                        headingRowColor:
                            WidgetStateProperty.all(Colors.grey.shade200),
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 60,
                        columnSpacing: isPortrait ? 24 : 32,
                        columns: _buildDataColumns(isPortrait),
                        rows: _buildDataRows(isPortrait),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GeneralButton(
                        text: 'بدء يوم جديد',
                        backgroundColor: AppColors.secondaryColor,
                        textColor: AppColors.whiteColor,
                        onPressed: () {
                          if (widget.isAdmin) _showResetConfirmation();
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
                const SizedBox(height: 12),
                GeneralButton(
                  text: 'تصدير إلى إكسل',
                  backgroundColor: AppColors.secondaryColor,
                  textColor: AppColors.whiteColor,
                  onPressed: () => _exportToExcel(filteredCases),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterModalContent extends StatefulWidget {
  final String? currentFilter;
  final dynamic currentValue;
  final Function(String?, dynamic) onFilterChanged;
  final Map<String, String> filterOptions;
  final Map<String, List<int>> caseGroups;
  const _FilterModalContent(
      {required this.currentFilter,
      required this.currentValue,
      required this.onFilterChanged,
      required this.filterOptions,
      required this.caseGroups});
  @override
  State<_FilterModalContent> createState() => _FilterModalContentState();
}

class _FilterModalContentState extends State<_FilterModalContent> {
  late String? selectedFilter;
  late dynamic selectedValue;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    selectedFilter = widget.currentFilter;
    selectedValue = widget.currentValue;
    if (selectedFilter == "عدد الأفراد" && selectedValue != null) {
      _textController.text = selectedValue.toString();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Container(
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
          maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 16, bottom: viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModalHeader(theme),
            const SizedBox(height: 24),
            _buildFilterTypeSection(theme),
            const SizedBox(height: 24),
            _buildValueSection(theme),
            const SizedBox(height: 32),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('تصفية الحالات',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
        IconButton(
            icon:
                Icon(Icons.close, size: 24, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildFilterTypeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('اختر نوع التصفية',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary.withAlpha(200),
                    fontWeight: FontWeight.w500))),
        SegmentedButton<String?>(
          segments: [
            ...widget.filterOptions.entries
                .map((e) => ButtonSegment(value: e.key, label: Text(e.value))),
            const ButtonSegment(
                value: null,
                label: Text('الكل'),
                icon: Icon(Icons.all_inclusive)),
          ],
          selected: {selectedFilter},
          onSelectionChanged: (Set<String?> newSelection) {
            setState(() {
              selectedFilter = newSelection.first;
              if (selectedFilter == null) selectedValue = null;
              if (selectedFilter == "عدد الأفراد" && selectedValue != null) {
                _textController.text = selectedValue.toString();
              }
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) =>
                states.contains(WidgetState.selected)
                    ? theme.colorScheme.primary.withAlpha(25)
                    : Colors.transparent),
            shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ),
      ],
    );
  }

  Widget _buildValueSection(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: selectedFilter != null
          ? Column(
              key: ValueKey(selectedFilter),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('اختر القيمة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary.withAlpha(200),
                            fontWeight: FontWeight.w500))),
                if (selectedFilter == "المجموعة")
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: widget.caseGroups.keys.length,
                      itemBuilder: (context, index) {
                        final customOrder = [
                          'الشنط الفردية',
                          'المجموعة الأولى',
                          'المجموعة الخامسة',
                          'المجموعة السابعة',
                          'المجموعة الثانية',
                          'المجموعة الثالثة',
                          'المجموعة الرابعة',
                          'المجموعة السادسة',
                          'المجموعة الثامنة',
                        ];
                        List<String> sortedKeys =
                            widget.caseGroups.keys.toList();
                        sortedKeys.sort((a, b) {
                          int indexA = customOrder.indexOf(a);
                          int indexB = customOrder.indexOf(b);
                          if (indexA == -1) indexA = 9999;
                          if (indexB == -1) indexB = 9999;
                          return indexA.compareTo(indexB);
                        });
                        final groupKey = sortedKeys[index];
                        return RadioListTile<dynamic>(
                          title: Text(groupKey),
                          value: groupKey,
                          groupValue: selectedValue,
                          onChanged: (value) {
                            setState(() => selectedValue = value);
                          },
                        );
                      },
                    ),
                  )
                else if (selectedFilter == "عدد الأفراد")
                  SizedBox(
                    height: 80,
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                          hintText: 'أدخل عدد الأفراد',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16)),
                      onChanged: (value) {
                        setState(() {
                          selectedValue = int.tryParse(value);
                        });
                      },
                    ),
                  )
                else
                  SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(
                                selectedValue == null
                                    ? 'عرض الكل'
                                    : (selectedValue is bool
                                        ? (selectedValue ? 'نعم' : 'لا')
                                        : 'الكل'),
                                style: theme.textTheme.bodyLarge)),
                        Flexible(
                          child: ToggleButtons(
                            isSelected: [
                              selectedValue == true,
                              selectedValue == false,
                              selectedValue == null
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
                                minHeight: 40, minWidth: 56),
                            children: const [
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('نعم')),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('لا')),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('الكل')),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                  _textController.clear();
                });
              },
              text: 'إعادة تعيين',
              backgroundColor: AppColors.primaryColor.withAlpha(125),
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
