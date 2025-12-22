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
import '../widgets/dashboard_card.dart';
import '../../../donation/presentation/views/widgets/editable_donation_section.dart';
import '../../../donation/presentation/cubit/donation_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/send_notification_screen.dart';

class AdminDashboardHub extends StatelessWidget {
  const AdminDashboardHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Light background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),

              // Section 1: Daily Workflow
              _buildSectionTitle('بيانات اليوم', Icons.wb_sunny_rounded),
              const SizedBox(height: 16),
              _buildDailyWorkflowGrid(context),

              const SizedBox(height: 32),

              // Section 2: Data Management
              _buildSectionTitle('إدارة البيانات', Icons.storage_rounded),
              const SizedBox(height: 16),
              _buildDataManagementGrid(context),

              const SizedBox(height: 32),

              // Section 3: History & Analytics
              _buildSectionTitle('الأرشيف والتحليل', Icons.history_edu_rounded),
              const SizedBox(height: 16),
              _buildHistoryAndAnalyticsGrid(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
          child: Icon(Icons.person, color: AppColors.primaryColor, size: 30),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحباً بك،',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const Text(
              'مدير المطبخ',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Actions
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => _showLogoutDialog(context),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  // 1. Daily Workflow Grid
  Widget _buildDailyWorkflowGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        DashboardCard(
          title: 'توزيع الوجبات',
          subtitle: 'متابعة وتسليم الحالات',
          icon: Icons.checklist_rtl_rounded,
          color: AppColors.primaryColor,
          onTap: () => _navigateToCasesDashboard(context),
        ),
        DashboardCard(
          title: 'وجبة اليوم',
          subtitle: 'تعديل الصورة والبيانات',
          icon: Icons.restaurant_menu_rounded,
          color: Colors.orange,
          onTap: () => _navigateToDonationEdit(context),
        ),
        DashboardCard(
          title: 'مصاريف اليوم',
          subtitle: 'تسجيل المشتريات',
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DailyExpensesScreen())),
        ),
      ],
    );
  }

  // 2. Data Management Grid (Uses Wide Layout)
  Widget _buildDataManagementGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 1, // Full Width
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 3.5, // Wide Ratio
      children: [
        DashboardCard(
          title: 'سجل الأٌسر',
          subtitle: 'إضافة وتعديل بيانات الأٌسر ',
          icon: Icons.people_alt_rounded,
          color: Colors.purple,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ManageCaseDetailsScreen())),
          isWide: true, // Triggers Horizontal Layout
        ),
        DashboardCard(
          title: 'إدارة المجموعات',
          subtitle: 'تقسيم الحالات إلى مجموعات (أ، ب، ج...)',
          icon: Icons.groups_3_rounded,
          color: Colors.redAccent,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ManageGroupsScreen())),
          isWide: true,
        ),
        DashboardCard(
          title: 'إرسال إشعارات',
          subtitle: 'إرسال تنبيهات عامة لجميع المستخدمين',
          icon: Icons.notification_add_rounded,
          color: Colors.deepOrange,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SendNotificationScreen())),
          isWide: true,
        ),
      ],
    );
  }

  // 3. History & Analytics Grid
  Widget _buildHistoryAndAnalyticsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        DashboardCard(
          title: 'الأيام السابقة',
          subtitle: 'مراجعة الأيام الماضية',
          icon: Icons.calendar_month_rounded,
          color: Colors.indigo,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PreviousDaysScreen())),
        ),
        DashboardCard(
          title: 'إحصائيات التوزيع',
          subtitle: 'تحليل توزيع الوجبات',
          icon: Icons.pie_chart_rounded,
          color: Colors.blue,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StatisticsScreen(initialTabIndex: 0))),
        ),
        DashboardCard(
          title: 'إجمالي الإحصائيات ',
          subtitle: 'ملخص عدد الوجبات',
          icon: Icons.trending_up_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StatisticsScreen(initialTabIndex: 1))),
        ),
        DashboardCard(
          title: 'التقارير',
          subtitle: 'سجلات العمل النصية',
          icon: Icons.assignment_outlined,
          color: Colors.brown,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => ReportsScreen())),
        ),
      ],
    );
  }

  // --- Helpers ---

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
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.exit_to_app_rounded,
                          size: 60, color: AppColors.primaryColor),
                      const SizedBox(height: 15),
                      Text(
                        'انتبه!',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.whiteColor,
                              side: BorderSide(color: AppColors.primaryColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                            ),
                            child: Text('إلغاء',
                                style:
                                    TextStyle(color: AppColors.primaryColor)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                            ),
                            child: const Text('تسجيل الخروج',
                                style: TextStyle(color: AppColors.whiteColor)),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamBuilder<Map<String, List<int>>>(
          stream: _getCaseGroupsStream(),
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
              if (state is DonationLoaded && state.donations.isNotEmpty) {
                return EditableDonationSection(
                  donationData: state.donations.first,
                  documentId: state.donations.first['id'],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Stream<Map<String, List<int>>> _getCaseGroupsStream() {
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
