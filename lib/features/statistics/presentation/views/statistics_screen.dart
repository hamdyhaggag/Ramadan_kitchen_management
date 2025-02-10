import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_kitchen_management/core/services/service_locator.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_cubit.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_state.dart';
import 'package:ramadan_kitchen_management/features/statistics/presentation/views/widgets/total_statistics_content.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = getIt<AuthRepo>();
    final isAdmin = authRepo.currentUser?.role == 'admin';

    return Scaffold(
      body: BlocBuilder<CasesCubit, CasesState>(
        builder: (context, state) {
          if (state is CasesLoading) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryColor));
          }
          if (state is CasesError) {
            return Center(child: Text(state.message));
          }
          if (state is CasesLoaded) {
            return isAdmin
                ? _AdminStatisticsView(cases: state.cases)
                : TotalStatisticsContent();
          }
          return const Center(child: Text('No statistics available'));
        },
      ),
    );
  }
}

class _AdminStatisticsView extends StatefulWidget {
  final List<Map<String, dynamic>> cases;
  const _AdminStatisticsView({required this.cases});

  @override
  State<_AdminStatisticsView> createState() => _AdminStatisticsViewState();
}

class _AdminStatisticsViewState extends State<_AdminStatisticsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              Tab(text: 'التفاصيل اليومية'),
              Tab(text: 'الإحصائيات العامة'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _StatisticsContent(cases: widget.cases),
              TotalStatisticsContent(),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatisticsContent extends StatefulWidget {
  final List<Map<String, dynamic>> cases;
  const _StatisticsContent({required this.cases});

  @override
  State<_StatisticsContent> createState() => _StatisticsContentState();
}

class _StatisticsContentState extends State<_StatisticsContent> {
  late int totalIndividuals;
  late int totalCheckedIndividuals;
  late int totalUndistributed;
  late double progressPercentage;

  @override
  void initState() {
    super.initState();
    _calculateStatistics();
  }

  void _calculateStatistics() {
    totalIndividuals = widget.cases.fold(
        0,
        (sum, e) =>
            sum + (e['عدد الأفراد'] is int ? e['عدد الأفراد'] as int : 0));
    totalCheckedIndividuals = widget.cases.fold(
        0,
        (sum, e) => e['جاهزة'] == true
            ? sum + (e['عدد الأفراد'] is int ? e['عدد الأفراد'] as int : 0)
            : sum);
    totalUndistributed = totalIndividuals - totalCheckedIndividuals;
    progressPercentage = totalIndividuals > 0
        ? (totalCheckedIndividuals / totalIndividuals) * 100
        : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 8,
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 185,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: totalCheckedIndividuals.toDouble(),
                          color: AppColors.customColors[0],
                          radius: 45,
                          title: '$totalCheckedIndividuals',
                          titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: totalUndistributed.toDouble(),
                          color: Colors.blue[100],
                          radius: 45,
                          title: '$totalUndistributed',
                          titleStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800]),
                        ),
                      ],
                      centerSpaceRadius: 56,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                      centerSpaceColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('تم التسليم',
                            style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Row(
                      children: [
                        Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                                color: Colors.blue[100]!,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('قيد الانتظار',
                            style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _buildMetricCard(
                  title: 'إجمالي الأفراد',
                  value: totalIndividuals,
                  icon: Icons.people_alt_rounded,
                  color: Colors.purple.shade200),
              _buildMetricCard(
                  title: 'تم التوزيع',
                  value: totalCheckedIndividuals,
                  icon: Icons.check_circle_rounded,
                  color: Colors.green),
              _buildMetricCard(
                  title: 'النسبة المئوية',
                  value: '${progressPercentage.toStringAsFixed(1)}%',
                  icon: Icons.percent_rounded,
                  color: Colors.blue.shade400),
              _buildMetricCard(
                  title: 'المتبقي',
                  value: totalUndistributed,
                  icon: Icons.pending_actions_rounded,
                  color: Colors.orange.shade800),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required dynamic value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
