import 'package:flutter/material.dart';
import 'package:pontconnect/user/add_reservation.dart';
import 'package:pontconnect/connexion/login.dart';
import 'package:pontconnect/connexion/register.dart';
import 'package:pontconnect/user/view_reservation.dart';
import 'package:pontconnect/user/main_view.dart';
import 'package:pontconnect/animation_ouverture.dart';
import 'package:pontconnect/visitor/visitor_main_view.dart';
import 'admin/admin_main_view.dart';

// POINT D'ENTREE
void main() {
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
      ),

      // ROUTES
      initialRoute: '/SplashScreen',
      routes: {
        '/login_screen': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/user': (context) => UserPage(),
        '/Reservation_view': (context) => ReservationsSchedulePage(),
        '/AddReservation': (context) => AddReservationPage(),
        '/SplashScreen': (context) => SplashScreen(),
        '/admin': (context) => AdminMainView(),
        '/Visitor': (context) => VisitorMainView(),
      },
    );
  }
}