import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/cache/prefs.dart';
import '../../../../../core/constants/constatnts.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/services/firebase_auth_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../daily_expenses/daily_expenses.dart';
import '../../../../manage_cases/manage_cases.dart';
import '../../../../reports/reports.dart';
import '../../../../statistics/statistics_screen.dart';

class ScreenLayout extends StatefulWidget {
  const ScreenLayout({super.key});

  @override
  State<ScreenLayout> createState() => _ScreenLayoutState();
}

class _ScreenLayoutState extends State<ScreenLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentIndex == 0
          ? AppBar(
              title: _getAppBarTitle(),
              centerTitle: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await FirebaseAuthService().signOut();
                      await Prefs.removeData(key: kUserData);
                      if (!FirebaseAuthService().isLoggedIn()) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.login);
                      }
                    },
                  ),
                ),
              ],
            )
          : _currentIndex == 3
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
        final cachedCases = Prefs.getString('casesData');
        final data = cachedCases.isNotEmpty
            ? List<Map<String, dynamic>>.from(jsonDecode(cachedCases))
            : [];

        final names =
            data.map((caseItem) => caseItem["الاسم"] as String).toList();
        final checkboxValues =
            data.map((caseItem) => caseItem["جاهزة"] as bool).toList();
        final serialNumbers =
            data.map((caseItem) => caseItem["الرقم"] as int).toList();
        final numberOfIndividuals =
            data.map((caseItem) => caseItem["عدد الأفراد"] as int).toList();

        return StatisticsScreen(
          names: names,
          checkboxValues: checkboxValues,
          serialNumbers: serialNumbers,
          numberOfIndividuals: numberOfIndividuals,
        );
      case 2:
        return const DailyExpensesScreen();
      case 3:
        return ReportsScreen();
      default:
        return Container();
    }
  }

  Widget _getAppBarTitle() {
    const defaultStyle = TextStyle(
      fontSize: 18,
      fontFamily: 'DIN',
      fontWeight: FontWeight.w300,
    );

    switch (_currentIndex) {
      case 0:
        return const Text('الرئيسية', style: defaultStyle);
      case 1:
        return const Text('الإحصائيات', style: defaultStyle);
      case 2:
        return const Text('المصاريف', style: defaultStyle);
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
            'assets/icons/wallet.svg',
            colorFilter: ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/wallet.svg',
            colorFilter:
                const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
            width: 28,
            height: 28,
          ),
          label: 'المصروفات',
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
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontSize: 11),
      selectedItemColor: AppColors.primaryColor,
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
    );
  }
}
