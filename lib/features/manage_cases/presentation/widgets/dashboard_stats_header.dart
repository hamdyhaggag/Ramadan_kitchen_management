import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class DashboardStatsHeader extends StatelessWidget {
  final int totalCases;
  final int readyCases;
  final int deliveredCases;
  final VoidCallback? onBackTap;

  const DashboardStatsHeader({
    super.key,
    required this.totalCases,
    required this.readyCases,
    required this.deliveredCases,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    final double readyProgress = totalCases > 0 ? readyCases / totalCases : 0;
    final double deliveredProgress =
        totalCases > 0 ? deliveredCases / totalCases : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
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
            // Top Header Row (Back Button + Title)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  if (onBackTap != null)
                    InkWell(
                      onTap: onBackTap,
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
                ],
              ),
            ),

            // Main Stats Content
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$deliveredCases / $totalCases',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DIN',
                        ),
                      ),
                      const Text(
                        'تم الاستلام',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Circular Progress
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      CircularProgressIndicator(
                        value: readyProgress,
                        strokeWidth: 8,
                        color: const Color(0xFF4CAF50),
                        backgroundColor: Colors.transparent,
                      ),
                      CircularProgressIndicator(
                        value: deliveredProgress,
                        strokeWidth: 8,
                        color: Colors.white,
                        backgroundColor: Colors.transparent,
                      ),
                      Center(
                        child: Text(
                          '${(deliveredProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Detail Cards
            Row(
              children: [
                _buildMiniStat(
                  label: 'جاهز للتوزيع',
                  count: readyCases.toString(),
                  color: const Color(0xFF4CAF50),
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                _buildMiniStat(
                  label: 'المتبقي',
                  count: (totalCases - deliveredCases).toString(),
                  color: const Color(0xFFFFC107),
                  textColor: Colors.black87,
                  icon: Icons.pending_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String count,
    required Color color,
    Color textColor = Colors.white,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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
}
