import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/manage_cases.dart';
import 'package:ramadan_kitchen_management/features/statistics/presentation/views/statistics_screen.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import 'package:ramadan_kitchen_management/core/services/service_locator.dart';

import 'package:ramadan_kitchen_management/core/widgets/custom_user_app_bar.dart';
import '../../../../previous_days/presentation/views/previous_days_screen.dart';
import '../../../../reports/reports.dart';

class ScreenLayout extends StatefulWidget {
  const ScreenLayout({super.key});

  @override
  State<ScreenLayout> createState() => _ScreenLayoutState();
}

class _ScreenLayoutState extends State<ScreenLayout> {
  int _currentIndex = 0;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    final authRepo = getIt<AuthRepo>();
    setState(() {
      isAdmin = authRepo.currentUser?.role == 'admin';
    });
  }

  @override
  Widget build(BuildContext context) {
    // ---------------- ADMIN VIEW ----------------
    // If Admin, show the Full Screen Dashboard Hub directly without BottomNav.
    // The Dashboard Hub handles its own navigation to other screens.
    if (isAdmin) {
      return const ManageCasesScreen();
    }

    // ---------------- USER VIEW ----------------
    // If User, show the standard Tabbed Layout with BottomNavigationBar
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Same as admin hub
      appBar: _currentIndex == 0 ? const CustomUserAppBar() : null,
      body: _currentIndex == 0
          ? _buildCurrentScreen()
          : SafeArea(child: _buildCurrentScreen()),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const ManageCasesScreen();
      case 1:
        return StatisticsScreen();
      case 2:
        return const PreviousDaysScreen();
      case 3:
        return ReportsScreen();
      default:
        return Container();
    }
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/home.svg',
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/home.svg',
            colorFilter:
                const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/analysis.svg',
            colorFilter: ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/analysis.svg',
            colorFilter:
                const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          label: 'الإحصائيات',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/calendar.svg',
            colorFilter: ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/calendar.svg',
            colorFilter:
                const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          label: 'الأيام السابقة',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/report.svg',
            colorFilter: ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/report.svg',
            colorFilter:
                const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          label: 'التقارير',
        ),
      ],
      showUnselectedLabels: true,
      unselectedLabelStyle: const TextStyle(fontSize: 16),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      selectedItemColor: AppColors.primaryColor,
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
    );
  }
}
