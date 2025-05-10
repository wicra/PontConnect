import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pontconnect/user/get_sensors_values.dart';
import 'package:pontconnect/auth/user_session_storage.dart';
import 'package:pontconnect/user/get_all_availabilities.dart';
import 'package:pontconnect/admin/admin_pending_reservations_management.dart';
import 'package:pontconnect/admin/admin_schedules_management.dart';
import 'package:pontconnect/core/constants.dart';

// PAGE PRINCIPALE DE L'ADMINISTRATEUR
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // VARIABLES DE GESTION
  final String userName = UserSession.userName ?? "ADMIN";
  int _currentIndex = 0;

  // CONSTRUIRE L'INTERFACE PRINCIPALE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundCream,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _getBodyContent(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // METHODE DE DECONNEXION
  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: backgroundLight,
              onSurface: textPrimary,
            ),
            dialogBackgroundColor: backgroundLight,
            textTheme: ThemeData.light().textTheme.apply(
                  fontFamily: 'DarumadropOne',
                ),
          ),
          child: AlertDialog(
            title: const Text('DÉCONNEXION'),
            content: const Text('VOULIEZ-VOUS VRAIMENT VOUS DÉCONNECTER ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ANNULER'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  UserSession.clear();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login_screen',
                    (route) => false,
                  );
                },
                child: const Text('DÉCONNECTER'),
              ),
            ],
          ),
        );
      },
    );
  }

  // CONSTRUIRE L'APP BAR
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            "assets/images/logo.svg",
            height: 55,
            color: backgroundLight,
          ),
          const SizedBox(width: 8),
          Text(
            ("| $userName").toUpperCase(),
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: backgroundLight,
            ),
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    );
  }

  // CONSTRUIRE LE CONTENU DE LA PAGE
  Widget _getBodyContent() {
    // PAGE ACCUEIL
    if (_currentIndex == 0) {
      return Column(
        children: [
          // SECTION HAUTE : CAROUSEL DES CAPTEURS
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: backgroundLight,
              height: 250,
              child: const GetSensorsValues(),
            ),
          ),
          const SizedBox(height: 16),
          // SECTION BASSE : VUE DES RÉSERVATIONS
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: backgroundLight,
                child: GetAllAvailabilities(),
              ),
            ),
          ),
        ],
      );
    }
    // PAGE CONFIRMATION DE RÉSERVATION (ADMIN)
    else if (_currentIndex == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: backgroundLight,
          child: AdminPendingReservations(),
        ),
      );
    }
    // PAGE GESTION DES PONTS
    else if (_currentIndex == 3) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: backgroundLight,
          child: AdminCreneauManagement(),
        ),
      );
    }
    // AUTRES PAGES
    else {
      return Center(
        child: Text(
          'FONCTIONNALITÉ À VENIR',
          style: TextStyle(fontSize: 20, color: textPrimary),
        ),
      );
    }
  }

  // CONSTRUIRE LA BOTTOM NAVIGATION BAR
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      backgroundColor: primaryColor,
      selectedItemColor: accentColor,
      unselectedItemColor: backgroundLight,
      selectedLabelStyle: const TextStyle(
        color: accentColor,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        color: primaryColor,
      ),
      elevation: 8,
      onTap: (index) {
        if (index == 4) {
          _logout();
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'ACCUEIL',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outlined),
          label: 'CONFIRM',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_enhance_outlined),
          label: 'CAM',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'CREN',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'DÉCO',
        ),
      ],
    );
  }
}
