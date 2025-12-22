import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_kitchen_management/core/services/service_locator.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_cubit.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_state.dart';
import 'package:ramadan_kitchen_management/features/statistics/presentation/views/widgets/total_statistics_content.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StatisticsScreen extends StatelessWidget {
  final int initialTabIndex;
  final String? title;

  const StatisticsScreen({super.key, this.initialTabIndex = 0, this.title});

  @override
  Widget build(BuildContext context) {
    final authRepo = getIt<AuthRepo>();
    final isAdmin = authRepo.currentUser?.role == 'admin';

    final String screenTitle = title ??
        (initialTabIndex == 0
            ? 'إحصائيات التوزيع اليومي'
            : 'إجمالي الإحصائيات');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: isAdmin
          ? AppBar(
              title: Text(screenTitle),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              titleTextStyle: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DIN'),
            )
          : null,
      body: BlocBuilder<CasesCubit, CasesState>(
        builder: (context, state) {
          if (state is CasesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CasesError) {
            return Center(child: Text(state.message));
          }
          if (state is CasesLoaded) {
            if (isAdmin) {
              if (initialTabIndex == 0) {
                return _StatisticsContent(cases: state.cases);
              } else {
                return const TotalStatisticsContent();
              }
            } else {
              return const TotalStatisticsContent();
            }
          }
          return const Center(child: Text('لا توجد بيانات متاحة'));
        },
      ),
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
    return AnimationLimiter(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 500),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              // 1. Progress Gauge Card
              _buildProgressGauge(),
              const SizedBox(height: 24),

              // 2. Metrics Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildMetricCard(
                    title: 'إجمالي الأفراد',
                    value: '$totalIndividuals',
                    unit: 'فرد',
                    icon: Iconsax.user,
                    color: AppColors.primaryColor,
                  ),
                  _buildMetricCard(
                    title: 'تم التجهيز',
                    value: '$totalCheckedIndividuals',
                    unit: 'وجبة',
                    icon: Iconsax.tick_circle,
                    color: const Color(0xFF14B8A6), // Cyan/Teal
                  ),
                  _buildMetricCard(
                    title: 'المتبقي',
                    value: '$totalUndistributed',
                    unit: 'وجبة',
                    icon: Iconsax.timer_1,
                    color: const Color(0xFFF59E0B), // Amber
                  ),
                  _buildMetricCard(
                    title: 'نسبة الإنجاز',
                    value: '${progressPercentage.toStringAsFixed(0)}%',
                    unit: 'اليوم',
                    icon: Iconsax.chart_21,
                    color: const Color(0xFF8B5CF6), // Purple
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 3. Status Summary
              _buildStatusSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressGauge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'نسبة الإنجاز اليومي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontFamily: 'DIN',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 75,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: totalCheckedIndividuals.toDouble(),
                        color: AppColors.primaryColor,
                        radius: 20,
                        showTitle: false,
                        badgeWidget: _buildBadgeIcon(Iconsax.tick_circle5),
                        badgePositionPercentageOffset: 1.3,
                      ),
                      PieChartSectionData(
                        value: totalUndistributed.toDouble(),
                        color: const Color(0xFFF1F5F9),
                        radius: 12,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${progressPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                        fontFamily: 'DIN',
                      ),
                    ),
                    Text(
                      'مكتمل العمل',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: AppColors.primaryColor,
                label: 'تم التجهيز',
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                color: const Color(0xFFCBD5E1),
                label: 'قيد الانتظار',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Icon(icon, color: AppColors.primaryColor, size: 20),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontFamily: 'DIN',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    bool isComplete = progressPercentage >= 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.primaryColor.withValues(alpha: 0.05)
            : const Color(0xFFF59E0B).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isComplete
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : const Color(0xFFF59E0B).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Iconsax.verify5 : Iconsax.info_circle5,
            color:
                isComplete ? AppColors.primaryColor : const Color(0xFFF59E0B),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isComplete
                  ? 'تم اكتمال توزيع جميع وجبات اليوم بفضل الله.'
                  : 'جاري العمل الآن.. المتبقي $totalUndistributed وجبة ليكتمل التوزيع.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                fontFamily: 'DIN',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
