import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/api.dart';
import 'core/auth_state.dart';
import 'screens/login_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/create_design_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.init();
  runApp(const ARTattooApp());
}

class ARTattooApp extends StatelessWidget {
  const ARTattooApp({super.key});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF6D5DF6);
    final scheme = ColorScheme.fromSeed(seedColor: color);
    return MaterialApp(
      title: 'ARTattoo', debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: scheme, textTheme: GoogleFonts.interTextTheme()),
      home: ValueListenableBuilder<AuthState>(
        valueListenable: authState,
        builder: (_, state, __) => state.isLoggedIn ? const CatalogScreen() : const LoginScreen(),
      ),
      routes: {
        CatalogScreen.route: (_) => const CatalogScreen(),
        AppointmentsScreen.route: (_) => const AppointmentsScreen(),
        '/create-design': (_) => const CreateDesignScreen(),
      },
    );
  }
}
