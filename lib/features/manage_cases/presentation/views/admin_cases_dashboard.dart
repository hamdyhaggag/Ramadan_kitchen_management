import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';

import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_cubit.dart';
import '../widgets/case_card.dart';
import '../widgets/dashboard_stats_header.dart';

class AdminCasesDashboard extends StatefulWidget {
  final List<Map<String, dynamic>> cases;
  final Map<String, List<int>> caseGroups;

  const AdminCasesDashboard({
    super.key,
    required this.cases,
    required this.caseGroups,
  });

  @override
  State<AdminCasesDashboard> createState() => _AdminCasesDashboardState();
}

class _AdminCasesDashboardState extends State<AdminCasesDashboard> {
  String searchQuery = '';
  String? activeFilter; // 'ready', 'delivered', 'pending', or specific group

  @override
  Widget build(BuildContext context) {
    final filteredCases = _getFilteredCases();
    final totalCases = widget.cases.length;
    final readyCases = widget.cases.where((c) => c['جاهزة'] == true).length;
    final deliveredCases = widget.cases.where((c) => c['هنا؟'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Modern light background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Stats Header (Full width at top)
          SliverToBoxAdapter(
            child: DashboardStatsHeader(
              totalCases: totalCases,
              readyCases: readyCases,
              deliveredCases: deliveredCases,
              onBackTap: () => Navigator.pop(context),
            ),
          ),

          // 3. Actions Row (Between Stats and Search)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'تصدير Excel',
                      icon: Icons.file_download_outlined,
                      color: Colors.green[700]!,
                      onTap: () => _exportToExcel(filteredCases),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      label: 'بدء يوم جديد',
                      icon: Icons.restart_alt_rounded,
                      color: Colors.red[700]!,
                      onTap: _showResetConfirmation,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Search & Filter Section (Pinned for easy access)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverSearchFilterDelegate(
              searchQuery: searchQuery,
              onSearchChanged: (val) => setState(() => searchQuery = val),
              activeFilter: activeFilter,
              caseGroups: widget.caseGroups,
              onFilterChanged: (val) => setState(() => activeFilter = val),
            ),
          ),

          // 4. Cases List with Animation
          filteredCases.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: AnimationLimiter(
                    child: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final caseItem = filteredCases[index];
                          final caseNumberStr = caseItem['الرقم'].toString();
                          final caseNumber = int.tryParse(caseNumberStr) ?? 0;

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: CaseCard(
                                  caseData: caseItem,
                                  groupName: _getGroupForCase(caseNumber),
                                  onStatusChanged: (field, value) {
                                    context.read<CasesCubit>().updateCaseState(
                                          caseItem['id'],
                                          field,
                                          value,
                                        );
                                  },
                                  onTap: () {
                                    // Optional Detail View or Edit Dialog could go here
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: filteredCases.length,
                      ),
                    ),
                  ),
                ),

          // 5. Bottom Padding for FAB space
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'لا توجد حالات تطابق البحث',
          style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Logic Helpers ---

  List<Map<String, dynamic>> _getFilteredCases() {
    return widget.cases.where((caseItem) {
      final name = caseItem['الاسم']?.toString().toLowerCase() ?? '';
      final number = caseItem['الرقم']?.toString() ?? '';
      final group = _getGroupForCase(int.tryParse(number) ?? 0) ?? '';

      final matchesSearch = searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase()) ||
          number.contains(searchQuery) ||
          group.contains(searchQuery);

      if (!matchesSearch) return false;

      if (activeFilter == 'ready') return caseItem['جاهزة'] == true;
      if (activeFilter == 'delivered') return caseItem['هنا؟'] == true;
      if (activeFilter == 'pending') return caseItem['جاهزة'] != true;

      if (activeFilter != null && widget.caseGroups.containsKey(activeFilter)) {
        final caseNum = int.tryParse(number);
        return widget.caseGroups[activeFilter]?.contains(caseNum) ?? false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final numA = int.tryParse(a['الرقم'].toString()) ?? 0;
        final numB = int.tryParse(b['الرقم'].toString()) ?? 0;
        return numA.compareTo(numB);
      });
  }

  String? _getGroupForCase(int caseNumber) {
    for (var entry in widget.caseGroups.entries) {
      if (entry.value.contains(caseNumber)) {
        return entry.key;
      }
    }
    return null;
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
        'تم الاستلام',
        'المجموعة',
      ]);

      for (var caseItem in cases) {
        sheet.appendRow([
          caseItem['الرقم'].toString(),
          caseItem['الاسم'] ?? '',
          caseItem['عدد الأفراد'].toString(),
          caseItem['جاهزة'] ? 'نعم' : 'لا',
          caseItem['هنا؟'] ? 'نعم' : 'لا',
          _getGroupForCase(int.tryParse(caseItem['الرقم'].toString()) ?? 0) ??
              'غير محدد',
        ]);
      }

      final directory = await getTemporaryDirectory();
      final file = io.File('${directory.path}/cases_export.xlsx');
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(file.path)],
            text: 'تصدير بيانات الحالات');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصدير: ${e.toString()}')),
        );
      }
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text("تأكيد بدء يوم جديد",
            style: TextStyle(
                color: AppColors.blackColor, fontWeight: FontWeight.bold)),
        content: const Text(
            "هل أنت متأكد من أنك تريد تصفير جميع الحالات لليوم الجديد؟\n(سيتم إعادة الحالات لـ غير جاهزة / لم تستلم)",
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
              child: const Text("تأكيد ومسح",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// --- Header Delegate ---

class _SliverSearchFilterDelegate extends SliverPersistentHeaderDelegate {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? activeFilter;
  final Map<String, List<int>> caseGroups;
  final ValueChanged<String?> onFilterChanged;

  _SliverSearchFilterDelegate({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.caseGroups,
    required this.onFilterChanged,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF8F9FE), // Matches scaffold background
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Field
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، الرقم، أو المجموعة...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('الكل', null),
                _buildFilterChip('تم التجهيز', 'ready', color: Colors.green),
                _buildFilterChip('خرجت للتوزيع', 'delivered',
                    color: AppColors.primaryColor),
                _buildFilterChip('قيد الانتظار', 'pending',
                    color: Colors.orange),
                const VerticalDivider(width: 20, indent: 8, endIndent: 8),
                ...caseGroups.keys.map((g) => _buildFilterChip('مجموعة $g', g)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, {Color? color}) {
    final isSelected = activeFilter == value;
    final baseColor = color ?? AppColors.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: () => onFilterChanged(isSelected ? null : value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? baseColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected ? baseColor : Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: baseColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 120; // 50 (search) + 12 (gap) + 40 (chips) + padding

  @override
  double get minExtent => 120;

  @override
  bool shouldRebuild(covariant _SliverSearchFilterDelegate oldDelegate) {
    return oldDelegate.searchQuery != searchQuery ||
        oldDelegate.activeFilter != activeFilter ||
        oldDelegate.caseGroups != caseGroups;
  }
}
