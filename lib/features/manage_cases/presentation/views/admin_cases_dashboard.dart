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
  RangeValues membersRange = const RangeValues(1, 20);
  static const double _membersMin = 1;
  static const double _membersMax = 20;

  double _lastPercentage = 0;

  @override
  void initState() {
    super.initState();
    _lastPercentage = _calculatePercentage(widget.cases);
  }

  @override
  void didUpdateWidget(AdminCasesDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentPercentage = _calculatePercentage(widget.cases);
    if (_lastPercentage != currentPercentage) {
      _checkMilestones(_lastPercentage, currentPercentage);
      _lastPercentage = currentPercentage;
    }
  }

  double _calculatePercentage(List<Map<String, dynamic>> cases) {
    if (cases.isEmpty) return 0;
    final total = cases.fold<int>(
        0,
        (sum, c) =>
            sum + (int.tryParse(c['عدد الأفراد']?.toString() ?? '0') ?? 0));
    final delivered = cases.where((c) => c['هنا؟'] == true).fold<int>(
        0,
        (sum, c) =>
            sum + (int.tryParse(c['عدد الأفراد']?.toString() ?? '0') ?? 0));
    if (total == 0) return 0;
    return (delivered / total) * 100;
  }

  void _checkMilestones(double oldP, double newP) {
    if (oldP < 25 && newP >= 25 && newP < 50) {
      _showMilestoneDialog(25);
    } else if (oldP < 50 && newP >= 50 && newP < 75) {
      _showMilestoneDialog(50);
    } else if (oldP < 75 && newP >= 75 && newP < 100) {
      _showMilestoneDialog(75);
    } else if (oldP < 100 && newP >= 100) {
      _showMilestoneDialog(100);
    }
  }

  void _showMilestoneDialog(int percentage) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => _MilestoneDialog(percentage: percentage),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCases = _getFilteredCases();
    final totalCases = widget.cases.fold<int>(
        0,
        (sum, c) =>
            sum + (int.tryParse(c['عدد الأفراد']?.toString() ?? '0') ?? 0));
    final readyCases = widget.cases.where((c) => c['جاهزة'] == true).fold<int>(
        0,
        (sum, c) =>
            sum + (int.tryParse(c['عدد الأفراد']?.toString() ?? '0') ?? 0));
    final deliveredCases = widget.cases
        .where((c) => c['هنا؟'] == true)
        .fold<int>(
            0,
            (sum, c) =>
                sum + (int.tryParse(c['عدد الأفراد']?.toString() ?? '0') ?? 0));

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
              membersRange: membersRange,
              isMembersFilterActive: membersRange.start > _membersMin ||
                  membersRange.end < _membersMax,
              onMembersFilterTap: () => _showMembersFilterSheet(),
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

      // Apply members range filter
      final members =
          int.tryParse(caseItem['عدد الأفراد']?.toString() ?? '0') ?? 0;
      final effectiveMax =
          membersRange.end >= _membersMax ? 999 : membersRange.end.toInt();
      if (members < membersRange.start.toInt() || members > effectiveMax) {
        return false;
      }

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

  void _showMembersFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MembersFilterSheet(
        initialRange: membersRange,
        min: _membersMin,
        max: _membersMax,
        onApply: (range) => setState(() => membersRange = range),
        onReset: () => setState(
            () => membersRange = const RangeValues(_membersMin, _membersMax)),
      ),
    );
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
      // Avoid using excel.rename() because it causes a crash in this version 
      // of the excel package ("Cannot remove from an unmodifiable list").
      final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[defaultSheet];

      // Define header format
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final headers = [
        'الرقم',
        'الاسم',
        'عدد الأفراد',
        'المنطقة',
        'الوسيط',
        'جاهزة للتوزيع',
        'تم الاستلام',
        'المجموعة'
      ];

      // Append headers
      sheet.appendRow(headers);

      // Apply style to header row setup
      for (int i = 0; i < headers.length; i++) {
        var cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = headerStyle;
      }

      // Append data
      for (var caseItem in cases) {
        sheet.appendRow([
          caseItem['الرقم'].toString(),
          caseItem['الاسم'] ?? '',
          caseItem['عدد الأفراد'].toString(),
          caseItem['المنطقة']?.toString() ?? '',
          caseItem['الوسيط']?.toString() ?? '',
          caseItem['جاهزة'] ? 'نعم' : 'لا',
          caseItem['هنا؟'] ? 'نعم' : 'لا',
          _getGroupForCase(int.tryParse(caseItem['الرقم'].toString()) ?? 0) ??
              'غير محدد',
        ]);
      }

      // Add simple data padding/alignment style
      final dataStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      for (int i = 0; i < headers.length; i++) {
        for (int j = 1; j <= cases.length; j++) {
          var cell = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: j));
          cell.cellStyle = dataStyle;
        }
      }

      final directory = await getTemporaryDirectory();
      final file = io.File('${directory.path}/تقرير_سجل_الأسر.xlsx');
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(file.path)],
            text: 'تصدير تقرير بيانات الأسر');
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
  final RangeValues membersRange;
  final bool isMembersFilterActive;
  final VoidCallback onMembersFilterTap;

  _SliverSearchFilterDelegate({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.caseGroups,
    required this.onFilterChanged,
    required this.membersRange,
    required this.isMembersFilterActive,
    required this.onMembersFilterTap,
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
                _buildMembersChip(),
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

  Widget _buildMembersChip() {
    final isActive = isMembersFilterActive;
    const color = Color(0xFF6366F1); // Indigo accent
    final maxVal =
        membersRange.end >= 20 ? '∞' : membersRange.end.toInt().toString();
    final label = isActive
        ? '👨‍👩‍👧‍👦 ${membersRange.start.toInt()} - $maxVal'
        : '👨‍👩‍👧‍👦 عدد الأفراد';
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onMembersFilterTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? color : Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[700],
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
        oldDelegate.caseGroups != caseGroups ||
        oldDelegate.membersRange != membersRange ||
        oldDelegate.isMembersFilterActive != isMembersFilterActive;
  }
}

class _MilestoneDialog extends StatefulWidget {
  final int percentage;
  const _MilestoneDialog({required this.percentage});

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    String title;
    String subtitle;
    IconData icon;

    switch (widget.percentage) {
      case 25:
        color = const Color(0xFF0EA5E9);
        title = '  ما شاء الله!';
        subtitle = 'خلصنا 25% من التوزيع ';
        icon = Icons.rocket_launch_rounded;
        break;
      case 50:
        color = const Color(0xFFF59E0B);
        title = 'نص السكة! ';
        subtitle = '  وصلنا للنصف 50%.';
        icon = Icons.star_rounded;
        break;
      case 75:
        color = const Color(0xFF8B5CF6);
        title = 'فاضل تكّة! ';
        subtitle = 'خلاص هانت.. 75% تمت على خير، شدوا حيلكم!';
        icon = Icons.local_fire_department_rounded;
        break;
      case 100:
      default:
        color = const Color(0xFF10B981);
        title = 'تمت بحمد الله! ';
        subtitle = 'الله ينور عليكم، التوزيع خلص 100%.. في ميزان حسناتكم.';
        icon = Icons.workspace_premium_rounded;
        break;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'DIN', // Assuming 'DIN' is used across your app
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'عاش.. يلا نكمّل',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Members Filter Bottom Sheet ---

class _MembersFilterSheet extends StatefulWidget {
  final RangeValues initialRange;
  final double min;
  final double max;
  final ValueChanged<RangeValues> onApply;
  final VoidCallback onReset;

  const _MembersFilterSheet({
    required this.initialRange,
    required this.min,
    required this.max,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_MembersFilterSheet> createState() => _MembersFilterSheetState();
}

class _MembersFilterSheetState extends State<_MembersFilterSheet> {
  late RangeValues _range;

  static const _accent = Color(0xFF6366F1);

  static const _presets = [
    {'label': 'فرد واحد', 'min': 1.0, 'max': 1.0},
    {'label': 'فردان', 'min': 2.0, 'max': 3.0},
    {'label': '٤ - ٥ أفراد', 'min': 4.0, 'max': 5.0},
    {'label': '٦ أفراد فأكثر', 'min': 6.0, 'max': 20.0},
  ];

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
  }

  bool _presetMatches(Map<String, double> p) {
    return _range.start == p['min'] && _range.end == p['max'];
  }

  String get _rangeLabel {
    final start = _range.start.toInt();
    final end = _range.end.toInt();
    if (start == end) return '$start فرد';
    if (end >= widget.max.toInt()) return 'من $start فرد فأكثر';
    return 'من $start إلى $end أفراد';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.group_rounded, color: _accent, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فلتر عدد الأفراد',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    Text(
                      'اختر نطاق عدد أفراد الأسرة',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Live preview badge
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(_rangeLabel),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Text(
                    _rangeLabel,
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Range Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _accent,
                inactiveTrackColor: _accent.withValues(alpha: 0.15),
                thumbColor: _accent,
                overlayColor: _accent.withValues(alpha: 0.1),
                rangeThumbShape:
                    const RoundRangeSliderThumbShape(enabledThumbRadius: 12),
                trackHeight: 6,
                activeTickMarkColor: Colors.transparent,
                inactiveTickMarkColor: Colors.transparent,
              ),
              child: RangeSlider(
                values: _range,
                min: widget.min,
                max: widget.max,
                divisions: (widget.max - widget.min).toInt(),
                onChanged: (v) => setState(() => _range = v),
              ),
            ),

            // Min / Max labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.min.toInt()}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  Text('${widget.max.toInt()}+',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick-select presets
            const Text(
              'اختيار سريع',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                final pp = p.map((k, v) =>
                    MapEntry(k, v is String ? v : (v as num).toDouble()));
                final numMap = {
                  'min': pp['min'] as double,
                  'max': pp['max'] as double,
                };
                final isActive = _presetMatches(numMap);
                return GestureDetector(
                  onTap: () => setState(() =>
                      _range = RangeValues(numMap['min']!, numMap['max']!)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? _accent : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? _accent
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      p['label'] as String,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                // Reset
                OutlinedButton.icon(
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.refresh_rounded,
                      size: 18, color: Color(0xFF64748B)),
                  label: const Text('إعادة تعيين',
                      style: TextStyle(color: Color(0xFF64748B))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                // Apply
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onApply(_range);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white),
                    label: const Text(
                      'تطبيق الفلتر',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
