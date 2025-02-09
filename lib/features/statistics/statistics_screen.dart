import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_kitchen_management/core/services/service_locator.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_cubit.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_state.dart';

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
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            );
          }
          if (state is CasesError) {
            return Center(child: Text(state.message));
          }
          if (state is CasesLoaded) {
            return isAdmin
                ? _AdminStatisticsView(cases: state.cases)
                : _StatisticsContent(cases: state.cases);
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
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
          ),
          indicatorColor: AppColors.primaryColor,
          controller: _tabController,
          tabs: const [
            Tab(text: 'الإحصائيات العامة'),
            Tab(text: 'الإحصائيات التفصيلية'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _StatisticsContent(cases: widget.cases),
              _TotalStatisticsContent(cases: widget.cases),
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

  @override
  void didUpdateWidget(covariant _StatisticsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cases != oldWidget.cases) {
      _calculateStatistics();
    }
  }

  void _calculateStatistics() {
    totalIndividuals = widget.cases.fold(0, (sum, e) {
      final individuals = e['عدد الأفراد'] is int ? e['عدد الأفراد'] as int : 0;
      return sum + individuals;
    });

    totalCheckedIndividuals = widget.cases.fold(0, (sum, e) {
      if (e['جاهزة'] == true) {
        final individuals =
            e['عدد الأفراد'] is int ? e['عدد الأفراد'] as int : 0;
        return sum + individuals;
      }
      return sum;
    });

    totalUndistributed = totalIndividuals - totalCheckedIndividuals;
    progressPercentage = totalIndividuals > 0
        ? (totalCheckedIndividuals / totalIndividuals) * 100
        : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            _buildPieChart(),
            const SizedBox(height: 45),
            _buildStatisticsCard('إجمالي عدد الأفراد', totalIndividuals),
            _buildStatisticsCard(
              'نسبة الإكتمال',
              progressPercentage,
              percentage: true,
            ),
            _buildStatisticsCard(
              'عدد الشنط المتبقية',
              widget.cases.where((e) => e['جاهزة'] != true).length,
            ),
            _buildStatisticsCard('عدد الأفراد المتبقي', totalUndistributed),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[200],
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: totalCheckedIndividuals.toDouble(),
              title: 'تم التوزيع\n$totalCheckedIndividuals',
              color: AppColors.primaryColor,
              radius: 100,
              titleStyle: const TextStyle(
                color: AppColors.whiteColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            PieChartSectionData(
              value: totalUndistributed.toDouble(),
              title: 'لم يتم التوزيع\n$totalUndistributed',
              color: Colors.grey[350],
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          centerSpaceRadius: 60,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(String title, dynamic value,
      {bool percentage = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              percentage ? '${value.toStringAsFixed(2)}%' : '$value',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: percentage ? AppColors.primaryColor : Colors.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalStatisticsContent extends StatelessWidget {
  final List<Map<String, dynamic>> cases;
  const _TotalStatisticsContent({required this.cases});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'الإحصائيات التفصيلية للمسؤولين',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
