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
  final int initialTabIndex;
  // Make AppBar title optional, if passed it will be used, otherwise default logic
  final String? title;

  const StatisticsScreen({super.key, this.initialTabIndex = 0, this.title});

  @override
  Widget build(BuildContext context) {
    final authRepo = getIt<AuthRepo>();
    final isAdmin = authRepo.currentUser?.role == 'admin';

    // Determine title based on index if not provided
    final String screenTitle = title ??
        (initialTabIndex == 0 ? 'إحصائيات التوزيع' : 'إجمالي الإحصائيات');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      // Add AppBar specifically for Admin views to provide context and back navigation
      appBar: isAdmin
          ? AppBar(
              title: Text(screenTitle),
              centerTitle: true,
              backgroundColor: AppColors.whiteColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DIN'),
            )
          : null,
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
            if (isAdmin) {
              // Directly return the specific content based on initialTabIndex
              // No TabBar, No TabBarView. specific content + AppBar.
              if (initialTabIndex == 0) {
                return _StatisticsContent(cases: state.cases);
              } else {
                return TotalStatisticsContent();
              }
            } else {
              // User View (Keep as is if needed, or update similarly)
              return TotalStatisticsContent();
            }
          }
          return const Center(child: Text('No statistics available'));
        },
      ),
    );
  }
}

// Deprecated: _AdminStatisticsView with Tabs is removed/refactored out since we now link directly.

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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Main Chart Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.05),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  'نسبة الإنجاز اليومي',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: totalCheckedIndividuals.toDouble(),
                              color: const Color(0xFF10B981), // Emerald Green
                              radius: 30,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: totalUndistributed.toDouble(),
                              color: const Color(0xFFF1F5F9), // Slate 100
                              radius: 25,
                              showTitle: false,
                            ),
                          ],
                          centerSpaceRadius: 70,
                          sectionsSpace: 0,
                          startDegreeOffset: -90,
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${progressPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            'مكتمل',
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
                const SizedBox(height: 30),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                        color: const Color(0xFF10B981), label: 'تم التجهيز'),
                    const SizedBox(width: 24),
                    _buildLegendItem(
                        color: const Color(0xFFCBD5E1), label: 'قيد الانتظار'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detail Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85, // Taller cards
            children: [
              _buildMetricCard(
                title: 'إجمالي الأفراد',
                value: totalIndividuals,
                icon: Icons.groups_rounded,
                color: const Color(0xFF6366F1), // Indigo
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              _buildMetricCard(
                title: 'تم التجهيز',
                value: totalCheckedIndividuals,
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF10B981), // Emerald
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              _buildMetricCard(
                title: 'المتبقي',
                value: totalUndistributed,
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFFF59E0B), // Amber
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              _buildMetricCard(
                title: 'نسبة الإنجاز',
                value: '${progressPercentage.toStringAsFixed(0)}%',
                icon: Icons.analytics_rounded,
                color: const Color(0xFFEC4899), // Pink
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required dynamic value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            offset: const Offset(0, 8),
            blurRadius: 15,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative Circle 1
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Decorative Circle 2
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          fontFamily: 'DIN',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
