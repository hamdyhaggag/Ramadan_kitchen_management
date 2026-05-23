import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/utils/app_colors.dart';
import '../../core/widgets/general_button.dart';
import '../donation/presentation/views/case_details_screen.dart';
import 'logic/cases_cubit.dart';
import 'logic/cases_state.dart';

class ManageCaseDetailsScreen extends StatelessWidget {
  const ManageCaseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: BlocBuilder<CasesCubit, CasesState>(
        builder: (context, state) {
          if (state is CasesLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: AppColors.primaryColor,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  const Text('جاري تحميل سجل الأسر...',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
                ],
              ),
            );
          }
          if (state is CasesError) {
            return Center(child: Text(state.message));
          }
          if (state is CasesLoaded) {
            return _ManageCaseDetailsContent(cases: state.cases);
          }
          return const Center(child: Text('لا توجد بيانات'));
        },
      ),
    );
  }
}

class _ManageCaseDetailsContent extends StatefulWidget {
  final List<Map<String, dynamic>> cases;
  const _ManageCaseDetailsContent({required this.cases});
  @override
  State<_ManageCaseDetailsContent> createState() =>
      _ManageCaseDetailsContentState();
}

class _ManageCaseDetailsContentState extends State<_ManageCaseDetailsContent> {
  late ScrollController _scrollController;
  int _previousCasesLength = 0;
  late TextEditingController _searchController;
  String searchQuery = '';
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _previousCasesLength = widget.cases.length;
    _searchController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant _ManageCaseDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cases.length > _previousCasesLength) {
      _previousCasesLength = widget.cases.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addNewCase() {
    final currentState = context.read<CasesCubit>().state;
    if (currentState is! CasesLoaded) return;
    final currentCases = currentState.cases;
    final numberController = TextEditingController();
    final nameController = TextEditingController();
    final membersController = TextEditingController();
    final areaController = TextEditingController();
    final brokerController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
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
                            color: AppColors.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.family_restroom_rounded,
                              color: AppColors.primaryColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إضافة أسرة جديدة',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B))),
                            Text('أدخل بيانات الأسرة بالكامل',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Row: الرقم + عدد الأفراد ───
                    Row(
                      children: [
                        Expanded(
                          child: _SheetField(
                            controller: numberController,
                            label: 'الرقم',
                            icon: Icons.tag_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SheetField(
                            controller: membersController,
                            label: 'عدد الأفراد',
                            icon: Icons.people_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ─── الاسم ───
                    _SheetField(
                      controller: nameController,
                      label: 'اسم الأسرة',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 14),

                    // ─── Row: المنطقة + الوسيط ───
                    Row(
                      children: [
                        Expanded(
                          child: _SheetField(
                            controller: areaController,
                            label: 'المنطقة',
                            icon: Icons.location_on_rounded,
                            color: const Color(0xFF0EA5E9),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SheetField(
                            controller: brokerController,
                            label: 'الوسيط',
                            icon: Icons.handshake_rounded,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ─── Buttons ───
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                          child: const Text('إلغاء',
                              style: TextStyle(color: Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final number =
                                  int.tryParse(numberController.text.trim());
                              final members =
                                  int.tryParse(membersController.text.trim()) ??
                                      0;
                              if (number == null || number <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'الرجاء إدخال رقم صحيح موجب')));
                                return;
                              }
                              if (currentCases
                                  .any((c) => c['الرقم'] == number)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('رقم الحالة موجود مسبقًا')));
                                return;
                              }
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('الرجاء إدخال اسم الحالة')));
                                return;
                              }
                              if (members <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'الرجاء إدخال عدد أفراد صحيح')));
                                return;
                              }
                              context.read<CasesCubit>().addCase({
                                'الرقم': number,
                                'id': number.toString(),
                                'الاسم': nameController.text.trim(),
                                'عدد الأفراد': members,
                                'المنطقة': areaController.text.trim(),
                                'الوسيط': brokerController.text.trim(),
                                'جاهزة': false,
                                'هنا؟': false,
                              });
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(Icons.check_rounded,
                                size: 18, color: Colors.white),
                            label: const Text('حفظ الأسرة',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _editCase(Map<String, dynamic> caseData) {
    if (caseData['id'] == null) return;
    final nameController =
        TextEditingController(text: caseData['الاسم']);
    final membersController =
        TextEditingController(text: caseData['عدد الأفراد'].toString());
    final areaController =
        TextEditingController(text: caseData['المنطقة']?.toString() ?? '');
    final brokerController =
        TextEditingController(text: caseData['الوسيط']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.blue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تعديل بيانات الأسرة',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B))),
                            Text('رقم الحالة: ${caseData['الرقم']}',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SheetField(
                      controller: nameController,
                      label: 'اسم الأسرة',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 14),
                    _SheetField(
                      controller: membersController,
                      label: 'عدد الأفراد',
                      icon: Icons.people_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SheetField(
                            controller: areaController,
                            label: 'المنطقة',
                            icon: Icons.location_on_rounded,
                            color: const Color(0xFF0EA5E9),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SheetField(
                            controller: brokerController,
                            label: 'الوسيط',
                            icon: Icons.handshake_rounded,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                          child: const Text('إلغاء',
                              style: TextStyle(color: Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<CasesCubit>().updateCase(
                                caseData['id'],
                                {
                                  'الاسم': nameController.text.trim(),
                                  'عدد الأفراد':
                                      int.tryParse(membersController.text) ?? 1,
                                  'المنطقة': areaController.text.trim(),
                                  'الوسيط': brokerController.text.trim(),
                                },
                              );
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(Icons.check_rounded,
                                size: 18, color: Colors.white),
                            label: const Text('حفظ التعديلات',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الحالة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذه الحالة نهائياً؟',
            style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.black45))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CasesCubit>().deleteCase(docId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              elevation: 0,
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredCases = widget.cases.where((caseItem) {
      final name = caseItem["الاسم"].toString().toLowerCase();
      final number = caseItem["الرقم"].toString();
      return name.contains(searchQuery.toLowerCase()) ||
          number.contains(searchQuery);
    }).toList();

    // Sort by case number
    filteredCases
        .sort((a, b) => (a['الرقم'] as int).compareTo(b['الرقم'] as int));

    final totalMembers = widget.cases
        .fold<int>(0, (sum, item) => sum + (item['عدد الأفراد'] as int? ?? 0));

    return Column(
      children: [
        // Custom Header
        _buildHeader(widget.cases.length, totalMembers),

        // Search Field
        Transform.translate(
          offset: const Offset(0, -25),
          child: _buildSearchField(),
        ),

        // List Content
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              itemCount: filteredCases.length,
              itemBuilder: (context, index) {
                final caseData = filteredCases[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildCaseCard(caseData),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Footer Action Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: GeneralButton(
              text: 'إضافة أسرة جديدة',
              backgroundColor: AppColors.primaryColor,
              textColor: AppColors.whiteColor,
              onPressed: _addNewCase,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int totalCases, int totalMembers) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'سجل الأسر',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DIN',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatItem('إجمالي الأٌسر', '$totalCases',
                    Icons.groups_rounded, Colors.orange),
                const SizedBox(width: 16),
                _buildStatItem('إجمالي الأفراد', '$totalMembers',
                    Icons.person_rounded, Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    final isWhite = color == Colors.white;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isWhite ? 0.15 : 1.0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: isWhite ? 0.1 : 0.0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isWhite ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, color: isWhite ? Colors.white : color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isWhite ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: isWhite ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => searchQuery = value.trim()),
          decoration: InputDecoration(
            hintText: 'ابحث عن أسرة بالاسم أو الرقم...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: AppColors.primaryColor, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => searchQuery = '');
                    })
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final area = caseData['المنطقة']?.toString() ?? '';
    final broker = caseData['الوسيط']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: BlocProvider.of<CasesCubit>(context),
                child: CaseDetailsScreen(caseData: caseData),
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Case Number Badge
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${caseData["الرقم"]}',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'DIN',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caseData["الاسم"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people_alt_outlined,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '${caseData["عدد الأفراد"]} أفراد',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Row(
                      children: [
                        _buildIconButton(
                          icon: Icons.edit_rounded,
                          color: Colors.blue,
                          onTap: () => _editCase(caseData),
                        ),
                        const SizedBox(width: 8),
                        _buildIconButton(
                          icon: Icons.delete_rounded,
                          color: Colors.red,
                          onTap: () => _confirmDelete(caseData['id']),
                        ),
                      ],
                    ),
                  ],
                ),
                // ─── Area & Broker badges ───
                if (area.isNotEmpty || broker.isNotEmpty) ...
                [
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (area.isNotEmpty)
                        _InfoBadge(
                          icon: Icons.location_on_rounded,
                          label: area,
                          color: const Color(0xFF0EA5E9),
                        ),
                      if (broker.isNotEmpty)
                        _InfoBadge(
                          icon: Icons.handshake_rounded,
                          label: broker,
                          color: const Color(0xFF8B5CF6),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class ManageCaseGroupsScreen extends StatefulWidget {
  const ManageCaseGroupsScreen({super.key});
  @override
  State<ManageCaseGroupsScreen> createState() => _ManageCaseGroupsScreenState();
}

class _ManageCaseGroupsScreenState extends State<ManageCaseGroupsScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _caseNumbersController = TextEditingController();
  Future<void> _addOrUpdateGroup({String? groupId}) async {
    final groupName = _groupNameController.text.trim();
    final caseNumbersString = _caseNumbersController.text.trim();
    if (groupName.isEmpty || caseNumbersString.isEmpty) return;
    final caseNumbers = caseNumbersString
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
    final docId = groupId ?? groupName;
    await FirebaseFirestore.instance
        .collection('caseGroups')
        .doc(docId)
        .set({'caseNumbers': caseNumbers});
    _groupNameController.clear();
    _caseNumbersController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة المجموعات",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('caseGroups')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_off, size: 64, color: theme.hintColor),
                        const SizedBox(height: 16),
                        Text("لا توجد مجموعات مضافة",
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  );
                }

                final customOrder = [/* your custom order */];
                final groups = snapshot.data!.docs
                  ..sort((a, b) => customOrder
                      .indexOf(a.id)
                      .compareTo(customOrder.indexOf(b.id)));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = groups[index];
                    final groupName = doc.id;
                    final caseNumbers =
                        List<int>.from(doc.get('caseNumbers') ?? []);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(Icons.group_work, color: theme.primaryColor),
                        ),
                        title: Text(groupName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            caseNumbers.isEmpty
                                ? "لا توجد أرقام حالات"
                                : caseNumbers.join(', '),
                            style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.7)),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue[600]),
                              onPressed: () => _showEditDialog(
                                  context, groupName, caseNumbers),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red[600]),
                              onPressed: () =>
                                  _confirmDelete(context, groupName),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 24),
              label: const Text("إضافة مجموعة جديدة",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showEditDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context,
      [String? groupName, List<int>? caseNumbers]) {
    _groupNameController.text = groupName ?? '';
    _caseNumbersController.text = caseNumbers?.join(', ') ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(groupName == null ? "إضافة مجموعة جديدة" : "تعديل المجموعة",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: "اسم المجموعة",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.group),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _caseNumbersController,
                decoration: InputDecoration(
                  labelText: "أرقام الحالات (مفصولة بفاصلة)",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("إلغاء"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (_validateInputs()) {
                        _addOrUpdateGroup(groupId: groupName);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      groupName == null ? "إضافة" : "حفظ التعديلات",
                      style: TextStyle(color: AppColors.whiteColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String groupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: Text("هل أنت متأكد من رغبتك في حذف مجموعة '$groupName'؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("تراجع"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('caseGroups')
                  .doc(groupName)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text("حذف"),
          ),
        ],
      ),
    );
  }

  bool _validateInputs() {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى إدخال اسم المجموعة")));
      return false;
    }

    final numbers = _caseNumbersController.text
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .toList();

    if (numbers.any((n) => n == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يوجد أرقام حالات غير صالحة")));
      return false;
    }

    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI components for Add / Edit bottom sheets
// ─────────────────────────────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final Color? color;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fieldColor = color ?? const Color(0xFF64748B);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: fieldColor, fontSize: 13),
          prefixIcon: Icon(icon, color: fieldColor, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
