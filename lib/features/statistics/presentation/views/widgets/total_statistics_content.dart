import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:ramadan_kitchen_management/core/networking/firestore_constants.dart';
import 'package:ramadan_kitchen_management/features/seasons/data/services/season_service.dart';
import '../../../../../core/utils/app_colors.dart';

class TotalStatisticsContent extends StatefulWidget {
  const TotalStatisticsContent({super.key});

  @override
  State<TotalStatisticsContent> createState() => _TotalStatisticsContentState();
}

class _TotalStatisticsContentState extends State<TotalStatisticsContent> {
  int _totalIndividuals = 0;
  bool _isLoading = true;
  final int _goal = 8500;
  final SeasonService _seasonService = SeasonService();

  @override
  void initState() {
    super.initState();
    _loadDonationData();
  }

  Future<void> _loadDonationData() async {
    try {
      final activeSeason = await _seasonService.getActiveSeason();
      if (activeSeason == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final seasonId = activeSeason.id;
      final prefs = await SharedPreferences.getInstance();

      // Cache keys are now season-specific
      final historicalTotalKey = 'historicalTotal_$seasonId';
      final dailyValueKey = 'dailyValue_$seasonId';
      final lastUpdatedKey = 'lastUpdated_$seasonId';

      int historicalTotal = prefs.getInt(historicalTotalKey) ?? 0;
      int dailyValue = prefs.getInt(dailyValueKey) ?? 0;
      int cachedDateMillis = prefs.getInt(lastUpdatedKey) ?? 0;

      DateTime cachedDate = cachedDateMillis == 0
          ? DateTime(1970)
          : DateTime.fromMillisecondsSinceEpoch(cachedDateMillis);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      bool isNewDay = cachedDate.isBefore(startOfDay);

      if (isNewDay) {
        historicalTotal += dailyValue;
        dailyValue = 0;
        await prefs.setInt(historicalTotalKey, historicalTotal);
        await prefs.setInt(dailyValueKey, dailyValue);
        await prefs.setInt(lastUpdatedKey, startOfDay.millisecondsSinceEpoch);
      }

      final isOnline = await _checkConnectivity();

      if (isOnline) {
        final donationsCol =
            _seasonService.getCollection(FirestoreCollections.donations);

        Query currentDayQuery = donationsCol.where('created_at',
            isGreaterThanOrEqualTo: startOfDay);
        Query previousDaysQuery =
            donationsCol.where('created_at', isLessThan: startOfDay);

        // Only filter by season if we have an active season AND it's not migrated
        if (!activeSeason.isMigratedToV2) {
          currentDayQuery =
              currentDayQuery.where('seasonId', isEqualTo: seasonId);
          previousDaysQuery =
              previousDaysQuery.where('seasonId', isEqualTo: seasonId);
        }

        final currentDaySnapshot = await currentDayQuery.get();
        dailyValue = currentDaySnapshot.docs.fold(
          0,
          (sum, doc) => sum + (doc['numberOfIndividuals'] as int? ?? 0),
        );

        final previousDaysSnapshot = await previousDaysQuery.get();
        historicalTotal = previousDaysSnapshot.docs.fold(
          0,
          (sum, doc) => sum + (doc['numberOfIndividuals'] as int? ?? 0),
        );

        await prefs.setInt(dailyValueKey, dailyValue);
        await prefs.setInt(historicalTotalKey, historicalTotal);
        await prefs.setInt(lastUpdatedKey, now.millisecondsSinceEpoch);
      }

      if (mounted) {
        setState(() {
          _totalIndividuals = historicalTotal + dailyValue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Err loading stats: $e");
    }
  }

  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildShimmerLoading();

    final percentage = (_totalIndividuals / _goal).clamp(0.0, 1.0);
    final remaining = (_goal - _totalIndividuals).clamp(0, _goal);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 500),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // 1. Hero Summary Card
                _buildHeroCard(),
                const SizedBox(height: 24),

                // 2. Goal Progress Section
                _buildGoalSection(percentage, remaining),
                const SizedBox(height: 24),

                // 3. Stats Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildMinorStatCard(
                      title: 'الهدف الكلي',
                      value: '$_goal',
                      unit: 'وجبة',
                      icon: Iconsax.flag,
                      color: const Color(0xFF6366F1),
                    ),
                    _buildMinorStatCard(
                      title: 'متبقي للهدف',
                      value: '$remaining',
                      unit: 'وجبة',
                      icon: Iconsax.timer_1,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 4. Full Width Average Performance
                _buildMinorStatCard(
                  title: 'متوسط الأداء',
                  value: '${(_totalIndividuals / 30).toStringAsFixed(0)}',
                  unit: 'يومياً',
                  icon: Iconsax.chart_21,
                  color: const Color(0xFF8B5CF6), // Purple/Indigo
                  isFullWidth: true,
                ),
                const SizedBox(height: 32),

                // 4. Motivational Quote
                _buildQuote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, Color(0xFF063EAF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Iconsax.status_up5, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'إجمالي عدد الوجبات',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'DIN',
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCount(
            count: _totalIndividuals,
            duration: const Duration(seconds: 2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.bold,
              fontFamily: 'DIN',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'وجبة تم توزيعها بفضل الله',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSection(double percentage, int remaining) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'التقدم نحو الهدف',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DIN',
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: const Color(0xFFF1F5F9),
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Iconsax.info_circle, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                'باقي $remaining وجبة للوصول لشعار رمضان 1.2',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinorStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
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
        crossAxisAlignment:
            isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          if (isFullWidth) const SizedBox(height: 16) else const Spacer(),
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
            mainAxisAlignment: isFullWidth
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
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

  Widget _buildQuote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              '"وَمَن أَحيَاها فَكَأَنَّما أَحيَا النّاسَ جَميعاً"',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.normal,
                color: Color(0xFF334155),
                fontFamily: 'DIN',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: List.generate(
                2,
                (index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedCount extends ImplicitlyAnimatedWidget {
  final int count;
  final TextStyle? style;

  const AnimatedCount({
    super.key,
    required this.count,
    required this.style,
    required super.duration,
  });

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _AnimatedCountState();
}

class _AnimatedCountState extends AnimatedWidgetBaseState<AnimatedCount> {
  IntTween? _countTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _countTween = visitor(
      _countTween,
      widget.count,
      (dynamic value) => IntTween(begin: value as int),
    ) as IntTween;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_countTween?.evaluate(animation) ?? 0}',
      style: widget.style,
    );
  }
}
