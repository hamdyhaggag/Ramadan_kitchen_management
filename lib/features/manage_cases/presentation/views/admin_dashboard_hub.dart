import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/services/firebase_auth_service.dart';
import 'package:ramadan_kitchen_management/core/cache/prefs.dart';
import 'package:ramadan_kitchen_management/core/constants/constatnts.dart';
import 'package:ramadan_kitchen_management/core/routes/app_routes.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_cubit.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_state.dart';
import 'package:ramadan_kitchen_management/features/statistics/presentation/views/statistics_screen.dart';
import 'package:ramadan_kitchen_management/features/reports/reports.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/daily_expenses.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/presentation/views/admin_cases_dashboard.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/manage_case_details_screen.dart';
import 'package:ramadan_kitchen_management/features/previous_days/presentation/views/previous_days_screen.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/presentation/views/manage_groups_screen.dart';
import '../../../donation/presentation/views/widgets/editable_donation_section.dart';
import '../../../donation/presentation/cubit/donation_cubit.dart';

import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/send_notification_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ramadan_kitchen_management/features/seasons/seasons.dart';
import 'package:ramadan_kitchen_management/features/seasons/data/services/season_service.dart';

class AdminDashboardHub extends StatefulWidget {
  const AdminDashboardHub({super.key});

  @override
  State<AdminDashboardHub> createState() => _AdminDashboardHubState();
}

class _AdminDashboardHubState extends State<AdminDashboardHub> {
  @override
  void initState() {
    super.initState();
    // Ensure cases are loaded for the stats
    final casesState = context.read<CasesCubit>().state;
    if (casesState is! CasesLoaded) {
      context.read<CasesCubit>().loadCases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<CasesCubit>().loadCases();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Modern Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                sliver: SliverToBoxAdapter(
                  child: _buildHeader(context),
                ),
              ),

              // 2. Live Stats Card (Hero Section)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildLiveStatsCard(context),
                ),
              ),

              // 3. Section Title: Operations
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                sliver: SliverToBoxAdapter(
                  child: _buildSectionTitle('العمليات اليومية'),
                ),
              ),

              // 4. Operations Grid (Distribute & Meal Setup)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildOperationsGrid(context),
                ),
              ),

              // 5. Section Title: Administration
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
                sliver: SliverToBoxAdapter(
                  child: _buildSectionTitle('الإدارة والتحكم'),
                ),
              ),

              // 6. Admin Grid
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                sliver: _buildAdminGrid(context),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3), // Border width
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withValues(alpha: 0.3)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: AppColors.primaryColor, size: 28),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلاً بك،',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              'مدير المطبخ',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'DIN',
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildLogoutButton(context),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () => _showLogoutDialog(context),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.red.withValues(alpha: 0.1), width: 1.5),
        ),
        child: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
      ),
    );
  }

  // --- Live Stats (Hero) ---
  Widget _buildLiveStatsCard(BuildContext context) {
    return BlocBuilder<CasesCubit, CasesState>(
      builder: (context, state) {
        int total = 0;
        int ready = 0;
        double progress = 0;
        bool isLoading = true;

        if (state is CasesLoaded) {
          isLoading = false;
          total = state.cases.fold(
              0,
              (sum, item) =>
                  sum + (int.tryParse(item['عدد الأفراد'].toString()) ?? 0));
          ready = state.cases.fold(
              0,
              (sum, item) => item['جاهزة'] == true
                  ? sum + (int.tryParse(item['عدد الأفراد'].toString()) ?? 0)
                  : sum);
          progress = total > 0 ? ready / total : 0;
        }

        return Container(
          width: double.infinity,
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0961F5), Color(0xFF66A2F9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0961F5).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatisticsScreen(initialTabIndex: 0),
                  ),
                );
              },
              splashColor: Colors.white.withValues(alpha: 0.1),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: Stack(
                children: [
                  // Background Decor
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'ملخص اليوم',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'توزيع الوجبات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'DIN',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isLoading
                                    ? 'جاري التحميل...'
                                    : '$ready من $total وجبة جاهزة',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Progress Indicator
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: isLoading ? null : progress,
                                    strokeWidth: 8,
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.1),
                                    valueColor: const AlwaysStoppedAnimation(
                                        Colors.white),
                                    strokeCap: StrokeCap.round,
                                  ),
                                  Center(
                                    child: Text(
                                      isLoading
                                          ? '%'
                                          : '${(progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        fontFamily: 'DIN',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Operations Section ---
  Widget _buildOperationsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // 1. Distribute Card (Main)
            Expanded(
              child: _OperationsCard(
                title: 'توزيع الوجبات',
                icon: Icons.checklist_rtl_rounded,
                color: const Color(0xFF0FAD74), // Greenish
                onTap: () => _navigateToCasesDashboard(context),
                delay: 100,
              ),
            ),
            const SizedBox(width: 16),
            // 2. Meal Setup Card
            Expanded(
              child: _OperationsCard(
                title: 'وجبة اليوم',
                icon: Icons.restaurant_menu_rounded,
                color: const Color(0xFFF59E0B), // Amber
                onTap: () => _navigateToDonationEdit(context),
                delay: 200,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 3. Expenses Card (Full Width)
        SizedBox(
          width: double.infinity,
          child: _OperationsCard(
            title: 'المصاريف اليومية',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF0EA5E9), // Sky Blue
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DailyExpensesScreen())),
            delay: 300,
            isWide: true,
          ),
        ),
      ],
    );
  }

  // --- Admin Grid (Sliver) ---
  Widget _buildAdminGrid(BuildContext context) {
    final List<_AdminItem> items = [
      _AdminItem(
        title: 'سجل الأسر',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF8B5CF6), // Purple
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ManageCaseDetailsScreen())),
      ),
      _AdminItem(
        title: 'المجموعات',
        icon: Icons.groups_3_rounded,
        color: const Color(0xFFEC4899), // Pink
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ManageGroupsScreen())),
      ),
      _AdminItem(
        title: 'الإشعارات',
        icon: Icons.notification_add_rounded,
        color: const Color(0xFFFF5722), // Deep Orange
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SendNotificationScreen())),
      ),
      _AdminItem(
        title: 'الأيام السابقة',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF64748B), // Slate
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PreviousDaysScreen())),
      ),
      _AdminItem(
        title: 'إجمالي الإحصائيات',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF14B8A6), // Teal
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const StatisticsScreen(initialTabIndex: 1))),
      ),
      _AdminItem(
        title: 'التقارير',
        icon: Icons.assignment_outlined,
        color: const Color(0xFF795548), // Brown
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => ReportsScreen())),
      ),
      _AdminItem(
        title: 'مواسم رمضان',
        icon: Icons.calendar_view_month_rounded,
        color: const Color(0xFF1E3A5F), // Dark Blue
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ManageSeasonsScreen())),
      ),
    ];

    return AnimationLimiter(
      child: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0, // Square like operations cards
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  Icon(item.icon, color: item.color, size: 32),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontFamily: 'DIN',
          ),
        ),
      ],
    );
  }

  // --- Logic Helpers ---

  void _showLogoutDialog(BuildContext context) {
    showGeneralDialog(
      barrierLabel: "تسجيل الخروج",
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.power_settings_new_rounded,
                            size: 40, color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DIN',
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('إلغاء',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('خروج',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                Navigator.pop(context);
                                await FirebaseAuthService().signOut();
                                await Prefs.removeData(key: kUserData);
                                if (!context.mounted) return;
                                if (!FirebaseAuthService().isLoggedIn()) {
                                  Navigator.pushReplacementNamed(
                                      context, AppRoutes.login);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
              parent: anim1,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  void _navigateToCasesDashboard(BuildContext context) {
    // Get current season ID from cubit
    final seasonId = context.read<CasesCubit>().currentSeasonId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamBuilder<Map<String, List<int>>>(
          stream: _getCaseGroupsStream(seasonId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(
                    title: const Text('إدارة الحالات'), centerTitle: true),
                body: Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                        color: AppColors.primaryColor, size: 50)),
              );
            }
            return BlocBuilder<CasesCubit, CasesState>(
              builder: (context, state) {
                if (state is! CasesLoaded) {
                  context.read<CasesCubit>().loadCases();
                }

                if (state is CasesLoading) {
                  return Scaffold(
                    appBar: AppBar(
                        title: const Text('إدارة الحالات'), centerTitle: true),
                    body: Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                            color: AppColors.primaryColor, size: 50)),
                  );
                } else if (state is CasesLoaded) {
                  return AdminCasesDashboard(
                    cases: state.cases,
                    caseGroups: snapshot.data!,
                  );
                } else {
                  return Scaffold(
                    appBar: AppBar(
                        title: const Text('إدارة الحالات'), centerTitle: true),
                    body:
                        const Center(child: Text('حدث خطأ في تحميل البيانات')),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  void _navigateToDonationEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar:
              AppBar(title: const Text('إعداد وجبة اليوم'), centerTitle: true),
          body: BlocBuilder<DonationCubit, DonationState>(
            builder: (context, state) {
              if (state is DonationLoaded) {
                if (state.donations.isNotEmpty) {
                  return EditableDonationSection(
                    donationData: state.donations.first,
                    documentId: state.donations.first['id'],
                  );
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('لم يتم إعداد وجبة لليوم',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<DonationCubit>().createNewDonation({
                              'mealTitle': 'وجبة جديدة',
                              'mealDescription': '',
                              'mealImageUrl': '',
                              'contacts': [],
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('إنشاء وجبة جديدة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  );
                }
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Stream<Map<String, List<int>>> _getCaseGroupsStream(String? seasonId) async* {
    if (seasonId == null) {
      yield {};
      return;
    }

    // Get the correct collection reference (root or sub-collection) handling V2 migration
    final collection =
        await SeasonService().getCollectionForSeason(seasonId, 'caseGroups');

    // Always filter by seasonId for security rules compliance
    final query = collection.where('seasonId', isEqualTo: seasonId);

    yield* query.snapshots().map((snapshot) {
      final groups = <String, List<int>>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String name = data['name'] ?? doc.id;
        final rawNumbers = data['caseNumbers'];
        // Safely parse numbers list
        if (rawNumbers is List) {
          groups[name] = rawNumbers.map((e) => e is int ? e : 0).toList();
        } else {
          groups[name] = [];
        }
      }
      return groups;
    });
  }
}

// --- Specific Widgets ---

class _OperationsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;
  final bool isWide;

  const _OperationsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.delay,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delay)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return AnimationConfiguration.synchronized(
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            horizontalOffset: 50,
            child: FadeInAnimation(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: isWide ? 100 : 140, // Shorter if wide
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: isWide
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 32),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdminItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _AdminItem(
      {required this.title,
      required this.icon,
      required this.color,
      required this.onTap});
}
