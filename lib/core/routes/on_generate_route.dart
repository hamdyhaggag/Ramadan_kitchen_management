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
import '../../features/home/presentation/views/home_view.dart';
import '../../features/on_boarding/presentation/views/login_or_register_view.dart';
import '../../views/daily_expenses/daily_expenses.dart';
import '../../views/manage_cases/manage_cases.dart';
import '../../views/reports/reports.dart';
import '../../views/statistics/statistics_screen.dart';

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
        builder: (context) => const ManageCasesScreen(),
      );
    case AppRoutes.dailyExpenses:
      return MaterialPageRoute(
        builder: (context) => const DailyExpensesScreen(),
      );
    case AppRoutes.statistics:
      return MaterialPageRoute(
        builder: (context) => const StatisticsScreen(),
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
