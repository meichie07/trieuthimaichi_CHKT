import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboards/admin_dashboard.dart';
import 'screens/dashboards/employee_dashboard.dart';
import 'screens/dashboards/parent_dashboard.dart';
import 'screens/dashboards/child_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent user session
  await AuthService.instance.initSession();

  runApp(const KidGuardApp());
}

class KidGuardApp extends StatelessWidget {
  const KidGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;

        Widget initialScreen;
        if (!auth.isLoggedIn) {
          initialScreen = const LoginScreen();
        } else {
          switch (auth.currentUser!.role) {
            case UserRole.admin:
              initialScreen = const AdminDashboard();
              break;
            case UserRole.employee:
              initialScreen = const EmployeeDashboard();
              break;
            case UserRole.child:
              initialScreen = const ChildDashboard();
              break;
            case UserRole.parent:
              initialScreen = const ParentDashboard();
              break;
          }
        }

        return MaterialApp(
          title: 'App Quản Lý Điện Thoại Trẻ Em',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          home: initialScreen,
        );
      },
    );
  }
}
