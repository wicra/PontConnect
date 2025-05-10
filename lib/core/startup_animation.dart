import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pontconnect/auth/login.dart';
import 'package:pontconnect/auth/user_session_storage.dart'; // Ajout de cette ligne

// CENTRALISATION COULEURS & API
import 'package:pontconnect/core/constants.dart';

// PAGE DE DEMARRAGE ANIMATION
class StartupAnimation extends StatefulWidget {
  @override
  _StartupAnimation createState() => _StartupAnimation();
}

class _StartupAnimation extends State<StartupAnimation>
    with TickerProviderStateMixin {
  // VARIABLES
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // CREATION DES ANIMATIONS & CONTROLLERS
    _scaleController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    // ANIMATION MISE A ECHELLE
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    // ANIMATION DE FADE OPACITY
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeIn),
    );

    // ANIMATION DE DEPLACEMENT
    _slideController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    // ANIMATION DE DEPLACEMENT
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: Offset(0, -1.5)).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    // ANIMATION DE COULEUR
    _colorController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    // ANIMATION DE COULEUR
    _colorAnimation =
        ColorTween(begin: backgroundLight, end: primaryColor).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    // DEMARRAGE DES ANIMATIONS
    _scaleController.forward().then((_) {
      // DEMARRAGE DE L'ANIMATION DE DEPLACEMENT APRES L'ANIMATION DE FONDU
      _slideController.forward().then((_) {
        // DEMARRAGE DE L'ANIMATION DE COULEUR APRES L'ANIMATION DE DEPLACEMENT
        _colorController.forward();
      });
    });

    // REDIRECTION VERS LA PAGE DE CONNEXION
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    });

    // ATTENDRE QUE L'ANIMATION SE TERMINE
    Future.delayed(Duration(seconds: 3), () {
      if (UserSession.userToken != null) {
        // REDIRIGER SELON LE TYPE D'UTILISATEUR
        if (UserSession.typeUserId == 1) {
          Navigator.pushReplacementNamed(context, '/admin_page');
        } else {
          Navigator.pushReplacementNamed(context, '/user_page');
        }
      } else {
        // NON CONNECTÉ
        Navigator.pushReplacementNamed(context, '/login_screen');
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CORPS DE LA PAGE
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, tertiaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: AnimatedBuilder(
                  animation: _colorAnimation,
                  builder: (context, child) => SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 150,
                    color: _colorAnimation.value,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
