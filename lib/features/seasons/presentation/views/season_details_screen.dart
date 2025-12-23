import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/models/ramadan_season_model.dart';

/// Detailed view of a specific season's data
/// Shows meals history, expenses summary, and statistics
class SeasonDetailsScreen extends StatefulWidget {
  final RamadanSeasonModel season;

  const SeasonDetailsScreen({super.key, required this.season});

  @override
  State<SeasonDetailsScreen> createState() => _SeasonDetailsScreenState();
}

class _SeasonDetailsScreenState extends State<SeasonDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: _buildOverviewTab(),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Iconsax.arrow_right_3, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                const Color(0xFF1E3A5F),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Iconsax.moon5,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.season.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'DIN',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.season.dateRangeFormatted,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
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
  }

  Widget _buildOverviewTab() {
    final stats = widget.season.statistics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: AnimationLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 500),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              // Hero Stats Card
              _buildHeroStatsCard(stats),
              const SizedBox(height: 20),

              // Stats Grid
              Row(
                children: [
                  _buildStatCard(
                    icon: Iconsax.people,
                    label: 'الحالات المستفيدة',
                    value: '${stats?.totalCases ?? 0}',
                    color: const Color(0xFF667eea),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Iconsax.category,
                    label: 'المجموعات',
                    value: '${stats?.totalGroups ?? 0}',
                    color: const Color(0xFF11998e),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    icon: Iconsax.calendar,
                    label: 'أيام العمل',
                    value: '${stats?.totalDays ?? 0}',
                    color: const Color(0xFFff6b6b),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Iconsax.money_4,
                    label: 'إجمالي المصروفات',
                    value: '${_formatCurrency(stats?.totalExpenses ?? 0)} جنية',
                    color: const Color(0xFF4facfe),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Section
              _buildSummarySection(stats),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Keep helper methods for Overview Tab)

  Widget _buildHeroStatsCard(SeasonStatistics? stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, const Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.chart_success,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'إجمالي الوجبات المقدمة',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatNumber(stats?.totalMealsServed ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'DIN',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'وجبة إفطار',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'DIN',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(SeasonStatistics? stats) {
    final avgMealsPerDay = stats != null && stats.totalDays > 0
        ? stats.totalMealsServed / stats.totalDays
        : 0.0;

    final costPerMeal = stats != null && stats.totalMealsServed > 0
        ? stats.totalExpenses / stats.totalMealsServed
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.status_up, color: AppColors.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'ملخص الإحصائيات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DIN',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(
            label: 'متوسط الوجبات اليومية',
            value: avgMealsPerDay.toStringAsFixed(0),
            icon: Iconsax.chart_21,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            label: 'تكلفة الوجبة الواحدة',
            value: '${costPerMeal.toStringAsFixed(2)} جنية',
            icon: Iconsax.money,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            label: 'مدة الموسم',
            value: '${widget.season.durationInDays} يوم',
            icon: Iconsax.calendar_1,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'DIN',
          ),
        ),
      ],
    );
  }

  String _formatNumber(num number) {
    if (number >= 1000000) {
      double val = number / 1000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} مليون';
    }
    if (number >= 1000) {
      double val = number / 1000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} ألف';
    }
    return number is int
        ? NumberFormat('#,###').format(number)
        : number.toStringAsFixed(0);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      double val = amount / 1000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} مليون';
    }
    if (amount >= 1000) {
      double val = amount / 1000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} ألف';
    }
    return NumberFormat('#,###').format(amount);
  }
}
