import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pontconnect/auth/user_session_storage.dart';
import 'package:pontconnect/user/user_add_new_reservation.dart';
import 'package:pontconnect/user/user_view_my_reservations.dart';
import 'package:pontconnect/user/get_all_availabilities.dart';
import 'package:pontconnect/user/user_view_my_boats.dart';
import 'package:pontconnect/user/user_rgpd.dart';
import 'package:pontconnect/user/get_sensors_values.dart';
import 'package:pontconnect/core/constants.dart';

// PAGE UTILISATEUR
class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

// ETAT DE LA PAGE
class _UserPageState extends State<UserPage> {
  // VARIABLES D'ÉTAT
  final String userName = UserSession.userName ?? "USER";
  int _currentIndex = 0;

  // CONSTRUIRE L'INTERFACE PRINCIPALE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _getBodyContent(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // METHODE DECONNEXION
  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          // THEME DE LA BOITE DE DIALOGUE
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

          // BOITE DE DIALOGUE
          child: AlertDialog(
            title: const Text('DÉCONNEXION'),
            content: const Text('VOULEZ-VOUS VRAIMENT VOUS DÉCONNECTER ?'),
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

  // CONSTRUIRE APP BAR
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
            style: const TextStyle(
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

  // CONSTRUIRE LE CONTENU DU BODY
  Widget _getBodyContent() {
    // PREMIER ONGLET
    if (_currentIndex == 0) {
      return Column(
        children: [
          // SECTION HAUTE
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: backgroundLight,
              height: 250,
              child: const GetSensorsValues(),
            ),
          ),
          const SizedBox(height: 16),
          // SECTION BASSE
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

    // DEUXIEME ONGLET
    else if (_currentIndex == 1) {
      return Column(
        children: [
          // SECTION HAUTE
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: backgroundLight,
              height: 380,
              child: UserAddReservation(),
            ),
          ),
          const SizedBox(height: 16),

          // SECTION BASSE
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: backgroundLight,
                child: ViewMyReservations(),
              ),
            ),
          ),
        ],
      );
    }

    // TROISIEME ONGLET
    else if (_currentIndex == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: backgroundLight,
          child: ViewUserBateaux(),
        ),
      );
    }

    // QUATIEME ONGLET
    else if (_currentIndex == 3) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: backgroundLight,
          child: const HelpPage(),
        ),
      );
    }

    // AUTRES ONGLETS
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

      // DECONNEXION BUTTON
      onTap: (index) {
        if (index == 4) {
          // DECONNEXION
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
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Réservation',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_boat),
          label: 'Bat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.help_outline_sharp),
          label: 'Aide',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'Déco',
        ),
      ],
    );
  }
}
