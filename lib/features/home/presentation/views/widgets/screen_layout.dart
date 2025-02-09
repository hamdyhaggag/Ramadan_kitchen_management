import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ramadan_kitchen_management/core/cache/prefs.dart';
import 'package:ramadan_kitchen_management/core/constants/constatnts.dart';
import 'package:ramadan_kitchen_management/core/routes/app_routes.dart';
import 'package:ramadan_kitchen_management/core/services/firebase_auth_service.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/daily_expenses.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/manage_cases.dart';
import 'package:ramadan_kitchen_management/features/statistics/presentation/views/statistics_screen.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import 'package:ramadan_kitchen_management/core/services/service_locator.dart';

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
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: _currentIndex == 0
          ? AppBar(
              title: _getAppBarTitle(),
              centerTitle: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.blackColor),
                    onPressed: () => _showCreativeLogoutDialog(context),
                  ),
                ),
              ],
            )
          : _currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3
              ? null
              : AppBar(
                  title: _getAppBarTitle(),
                  centerTitle: true,
                ),
      body: SafeArea(
        child: _buildCurrentScreen(),
      ),
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
        return isAdmin
            ? const DailyExpensesScreen()
            : const PreviousDaysScreen();
      case 3:
        return ReportsScreen();
      default:
        return Container();
    }
  }

  Widget _getAppBarTitle() {
    const defaultStyle = TextStyle(
      fontSize: 20,
      fontFamily: 'DIN',
      fontWeight: FontWeight.w500,
    );
    switch (_currentIndex) {
      case 0:
        return const Text('الرئيسية', style: defaultStyle);
      case 1:
        return const Text('الإحصائيات', style: defaultStyle);
      case 2:
        return Text(isAdmin ? 'المصاريف' : 'الأيام السابقة',
            style: defaultStyle);
      case 3:
        return const Text('التقارير', style: defaultStyle);
      default:
        return const Text('', style: defaultStyle);
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
            isAdmin ? 'assets/icons/wallet.svg' : 'assets/icons/calendar.svg',
            colorFilter: ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          activeIcon: SvgPicture.asset(
            isAdmin
                ? 'assets/icons/wallet.svg'
                : 'assets/icons/previous_days.svg',
            colorFilter:
                const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          label: isAdmin ? 'المصاريف' : 'الأيام السابقة',
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

  void _showCreativeLogoutDialog(BuildContext context) {
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
                    color: AppColors.whiteColor, // White background
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
                      Icon(
                        Icons.exit_to_app_rounded,
                        size: 60,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'انتبه!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.whiteColor,
                              side: BorderSide(
                                color: AppColors.primaryColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: Text(
                              'إلغاء',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: const Text(
                              'تسجيل الخروج',
                              style: TextStyle(color: AppColors.whiteColor),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              await FirebaseAuthService().signOut();
                              await Prefs.removeData(key: kUserData);
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
            reverseCurve: Curves.easeInBack,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }
}
