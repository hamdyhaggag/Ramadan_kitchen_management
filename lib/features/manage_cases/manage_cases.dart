import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import '../../core/services/service_locator.dart';
import 'presentation/views/admin_dashboard_hub.dart';
import 'presentation/views/user_donation_dashboard.dart';

class ManageCasesScreen extends StatefulWidget {
  const ManageCasesScreen({super.key});
  @override
  State<ManageCasesScreen> createState() => _ManageCasesScreenState();
}

class _ManageCasesScreenState extends State<ManageCasesScreen> {
  late bool isAdmin;

  @override
  void initState() {
    super.initState();
    final authRepo = getIt<AuthRepo>();
    isAdmin = authRepo.currentUser?.role == 'admin';
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      return const AdminDashboardHub();
    } else {
      return const UserDonationDashboard();
    }
  }
}
