import 'package:flutter/material.dart';
import 'package:pontconnect/auth/login.dart';
import 'package:pontconnect/auth/register.dart';
import 'package:pontconnect/public/user_main_view.dart';
import 'package:pontconnect/startup_animation.dart';
import 'package:pontconnect/auth/user_session_storage.dart'; // Ajout de cette ligne

// CENTRALISATION COULEURS & API
import 'package:pontconnect/constants.dart';

import 'admin/admin_main_view.dart';

// POINT D'ENTREE
void main() async {
  // INITIALISATION OBLIGATOIRE POUR FLUTTER
  WidgetsFlutterBinding.ensureInitialized();

  // VERIFICATION SI SESSION EXISTE
  await UserSession.loadSession();

  // LANCEMENT DE L'APPLICATION
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // CONSTRUCTION DE L'APPLICATION
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // THEME GLOBAL
      theme: ThemeData(
        fontFamily: 'DarumadropOne',

        // STYLE DES TEXTES SELECTIONNES
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: primaryColor,
          selectionColor: primaryColor.withOpacity(0.5),
          selectionHandleColor: primaryColor,
        ),
      ),

      // ROUTES
      initialRoute: '/startup_animation',
      routes: {
        '/login_screen': (context) => LoginPage(),
        '/register_screen': (context) => RegisterPage(),
        '/startup_animation': (context) => StartupAnimation(),
        '/user_page': (context) => UserPage(),
        '/admin_page': (context) => AdminPage(),
      },
    );
  }
}
