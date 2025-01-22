import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/cache/prefs.dart';
import '../../../../../core/constants/constatnts.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/services/firebase_auth_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../daily_expenses/daily_expenses.dart';
import '../../../../manage_cases/manage_cases.dart';
import 'package:ramadan_kitchen_management/features/reports/reports.dart';
import '../../../../statistics/statistics_screen.dart';

class ScreenLayout extends StatefulWidget {
  const ScreenLayout({super.key});

  @override
  State<ScreenLayout> createState() => _ScreenLayoutState();
}

class _ScreenLayoutState extends State<ScreenLayout> {
  final List<Widget> _screens = [
    ManageCasesScreen(),
    Builder(
      builder: (context) {
        final casesData = Prefs.getString('casesData');
        final data = casesData.isNotEmpty
            ? List<Map<String, dynamic>>.from(jsonDecode(casesData))
            : [
                {
                  "الرقم": 1,
                  "الاسم": "أحمد علي",
                  "عدد الأفراد": 4,
                  "جاهزة": true,
                  "هنا؟": true,
                },
                {
                  "الرقم": 2,
                  "الاسم": "محمد محمود",
                  "عدد الأفراد": 3,
                  "جاهزة": false,
                  "هنا؟": false,
                },
                {
                  "الرقم": 3,
                  "الاسم": "سارة عبد الله",
                  "عدد الأفراد": 80,
                  "جاهزة": true,
                  "هنا؟": false,
                },
              ];

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
      },
    ),
    const DailyExpensesScreen(),
    ReportsScreen(),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentIndex == 0
          ? AppBar(title: _getAppBarTitle(), centerTitle: false, actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuthService().signOut();
                    log(FirebaseAuthService().isLoggedIn().toString());

                    await Prefs.removeData(key: kUserData);
                    log(Prefs.getString(kUserData).toString());

                    if (!FirebaseAuthService().isLoggedIn()) {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    } else {
                      log('Logout failed!');
                    }
                  },
                ),
              ),
            ])
          : _currentIndex == 3
              ? null
              : AppBar(
                  title: _getAppBarTitle(),
                  centerTitle: true,
                ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _getAppBarTitle() {
    TextStyle defaultStyle = const TextStyle(
      fontSize: 18,
      fontFamily: 'DIN',
      fontWeight: FontWeight.w600,
      color: Color(0xFF2A2A2A),
    );

    switch (_currentIndex) {
      case 0:
        return _buildTitle('الرئيسية', defaultStyle);
      case 1:
        return _buildTitle('الإحصائيات', defaultStyle);
      case 2:
        return _buildTitle('المصاريف', defaultStyle);

      default:
        return _buildTitle('التقارير', defaultStyle);
    }
  }

  Widget _buildTitle(String title, TextStyle style) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'DIN',
        fontSize: 18,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/home.svg',
                width: 28,
                height: 28,
                colorFilter:
                    ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/home.svg',
                colorFilter: const ColorFilter.mode(
                    AppColors.primaryColor, BlendMode.srcIn),
                width: 28,
                height: 28,
              ),
              label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/analysis.svg',
                colorFilter:
                    ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
                width: 28,
                height: 28,
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/analysis.svg',
                colorFilter: const ColorFilter.mode(
                    AppColors.primaryColor, BlendMode.srcIn),
                width: 28,
                height: 28,
              ),
              label: 'الإحصائيات'),
          BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/wallet.svg',
                colorFilter:
                    ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
                width: 28,
                height: 28,
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/wallet.svg',
                colorFilter: const ColorFilter.mode(
                    AppColors.primaryColor, BlendMode.srcIn),
                width: 28,
                height: 28,
              ),
              label: 'المصاريف'),
          BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/report.svg',
                colorFilter:
                    ColorFilter.mode(AppColors.greyColor, BlendMode.srcIn),
                width: 28,
                height: 28,
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/report.svg',
                colorFilter: const ColorFilter.mode(
                    AppColors.primaryColor, BlendMode.srcIn),
                width: 28,
                height: 28,
              ),
              label: 'التقارير'),
        ],
        showUnselectedLabels: true,
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 11),
        selectedItemColor: AppColors.primaryColor,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        });
  }

  Widget buildBottomButton(int index, String iconPath, double size) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: SvgPicture.asset(
        iconPath,
        colorFilter:
            const ColorFilter.mode(AppColors.whiteColor, BlendMode.srcIn),
        width: size,
        height: size,
      ),
    );
  }
}
