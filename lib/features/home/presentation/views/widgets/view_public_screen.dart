import 'package:flutter/material.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_colors.dart';

class ViewPublicScreen extends StatelessWidget {
  const ViewPublicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخيارات المتاحة',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        centerTitle: true,
        flexibleSpace: Container(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.0,
          children: [
            _buildActionTile(
              context,
              icon: Icons.person,
              title: 'قسم التبرعات',
              color: AppColors.primaryColor,
              onTap: () => Navigator.pushReplacementNamed(
                  context, AppRoutes.donationSection),
            ),
            _buildActionTile(
              context,
              icon: Icons.history,
              title: 'الأيام السابقة',
              color: AppColors.primaryColor,
              onTap: () => Navigator.pushReplacementNamed(
                  context, AppRoutes.previousDailyExpenses),
            ),
            _buildActionTile(
              context,
              icon: Icons.notifications_active,
              title: 'إرسال إشعار',
              color: AppColors.primaryColor,
              onTap: () => Navigator.pushReplacementNamed(
                  context, AppRoutes.sendNotificationScreen),
            ),
            _buildActionTile(
              context,
              icon: Icons.circle_notifications_rounded,
              title: ' الإشعارات ',
              color: AppColors.primaryColor,
              onTap: () => Navigator.pushReplacementNamed(
                  context, AppRoutes.notificationScreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        hoverColor: color.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        )
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
