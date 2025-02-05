import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ramadan_kitchen_management/core/routes/app_routes.dart';
import 'core/cache/prefs.dart';
import 'core/routes/on_generate_route.dart';
import 'core/services/service_locator.dart';
import 'core/utils/app_colors.dart';
import 'features/daily_expenses/logic/expense_cubit.dart';
import 'features/donation/presentation/cubit/donation_cubit.dart';
import 'features/donation/presentation/views/donation_section.dart';
import 'features/manage_cases/logic/cases_cubit.dart';
import 'firebase_options.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await Prefs.init();
  setupGetit();
  runApp(const KitchenApp());
}

class KitchenApp extends StatelessWidget {
  const KitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CasesCubit()),
        BlocProvider(create: (context) => ExpenseCubit()),
        BlocProvider(
          create: (context) => DonationCubit(context.read<CasesCubit>()),
          child: DonationSection(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: 'DIN',
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.whiteColor,
          ),
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('ar'),
        supportedLocales: S.delegate.supportedLocales,
        onGenerateRoute: onGenerateRoutes,
        initialRoute: AppRoutes.splash,
      ),
    );
  }
}
// this is develompent branch
