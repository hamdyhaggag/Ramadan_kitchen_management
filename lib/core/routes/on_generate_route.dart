import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/routes/app_routes.dart';
import 'package:ramadan_kitchen_management/features/auth/presentation/views/register_view.dart';
import 'package:ramadan_kitchen_management/features/auth/presentation/views/reset_password_view.dart';
import 'package:ramadan_kitchen_management/features/auth/presentation/views/verify_view.dart';
import 'package:ramadan_kitchen_management/features/home/presentation/views/widgets/screen_layout.dart';
import 'package:ramadan_kitchen_management/features/on_boarding/presentation/views/on_boarding_view.dart';
import 'package:ramadan_kitchen_management/features/splash/presentation/views/splash_view.dart';
import '../../features/auth/presentation/views/forget_password_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/daily_expenses/daily_expenses.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/manage_cases/manage_cases.dart';
import '../../features/on_boarding/presentation/views/login_or_register_view.dart';
import '../../features/reports/reports.dart';
import '../../features/statistics/statistics_screen.dart';
import 'dart:convert';

import '../cache/prefs.dart';

Route<dynamic> onGenerateRoutes(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return MaterialPageRoute(builder: (context) => const SplashView());
    case AppRoutes.onBoarding:
      return MaterialPageRoute(builder: (context) => const OnBoardingView());
    case AppRoutes.loginOrRegister:
      return MaterialPageRoute(
        builder: (context) => const LoginOrRegisterView(),
      );
    case AppRoutes.login:
      return MaterialPageRoute(builder: (context) => const LoginView());
    case AppRoutes.register:
      return MaterialPageRoute(builder: (context) => const RegisterView());
    case AppRoutes.forgetPassword:
      return MaterialPageRoute(
        builder: (context) => const ForgetPasswordView(),
      );
    case AppRoutes.verify:
      return MaterialPageRoute(
        builder: (context) => const VerifyView(),
      );
    case AppRoutes.resetPassword:
      return MaterialPageRoute(
        builder: (context) => const ResetPasswordView(),
      );
    case AppRoutes.home:
      return MaterialPageRoute(
        builder: (context) => const HomeView(),
      );
    case AppRoutes.manageCases:
      return MaterialPageRoute(
        builder: (context) => ManageCasesScreen(),
      );
    case AppRoutes.dailyExpenses:
      return MaterialPageRoute(
        builder: (context) => const DailyExpensesScreen(),
      );
    // Inside the onGenerateRoute function
    case AppRoutes.statistics:
      // Retrieve casesData from Prefs
      final cachedCases = Prefs.getString('casesData');
      final data = cachedCases.isNotEmpty
          ? List<Map<String, dynamic>>.from(jsonDecode(cachedCases))
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
                "عدد الأفراد": 5,
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

      return MaterialPageRoute(
        builder: (context) => StatisticsScreen(
          names: names,
          checkboxValues: checkboxValues,
          serialNumbers: serialNumbers,
          numberOfIndividuals: numberOfIndividuals,
        ),
      );

    case AppRoutes.reports:
      return MaterialPageRoute(
        builder: (context) => ReportsScreen(),
      );

    case AppRoutes.layout:
      return MaterialPageRoute(
        builder: (context) => ScreenLayout(),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(
            child: Text('Page not found'),
          ),
        ),
      );
  }
}
