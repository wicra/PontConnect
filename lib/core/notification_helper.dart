import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:pontconnect/core/constants.dart';

class NotificationHelper {
  // STOCKE LA RÉFÉRENCE DE L'OVERLAY
  static OverlayEntry? _currentNotification;
  static Timer? _autoHideTimer;

  /// AFFICHAGE DE NOTIFICATION EN HAUT DE L'ÉCRAN
  static void showTopSnackBar({
    required BuildContext context,
    required String message,
    Color backgroundColor = primaryColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    bool playSound = true,
  }) {
    _hideCurrentNotification();

    if (playSound) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
    }

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = AppBar().preferredSize.height;
    final safeTopMargin = statusBarHeight + appBarHeight + 20;

    final overlayState = Overlay.of(context);
    _currentNotification = OverlayEntry(
      builder: (context) => _AnimatedNotification(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        topPadding: safeTopMargin,
      ),
    );

    overlayState.insert(_currentNotification!);
    _autoHideTimer = Timer(duration, _hideCurrentNotification);
  }

  // MASQUER LA NOTIFICATION ACTUELLE
  static void _hideCurrentNotification() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;

    _currentNotification?.remove();
    _currentNotification = null;
  }

  // NOTIFICATIONS DE SUCCÈS
  static void showSuccess(BuildContext context, String message) {
    showTopSnackBar(
      context: context,
      message: message,
      backgroundColor: primaryColor,
      icon: Icons.check_circle,
    );
  }

  // NOTIFICATIONS D'ERREUR
  static void showError(BuildContext context, String message) {
    showTopSnackBar(
      context: context,
      message: message,
      backgroundColor: accentColor,
      icon: Icons.error,
    );
  }

  // NOTIFICATIONS D'INFORMATION
  static void showInfo(BuildContext context, String message) {
    showTopSnackBar(
      context: context,
      message: message,
      backgroundColor: tertiaryColor,
      icon: Icons.info,
    );
  }

  // NOTIFICATIONS D'AVERTISSEMENT
  static void showWarning(BuildContext context, String message) {
    showTopSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }
}

// WIDGET D'ANIMATION POUR LA NOTIFICATION
class _AnimatedNotification extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData? icon;
  final double topPadding;

  const _AnimatedNotification({
    required this.message,
    required this.backgroundColor,
    this.icon,
    required this.topPadding,
  });

  @override
  _AnimatedNotificationState createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<_AnimatedNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // ANIMATIONS FLUIDES
    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          if (mounted) setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          top: widget.topPadding + _slideAnimation.value,
          left: 20,
          right: 20,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: backgroundLight, size: 28),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: backgroundLight,
                          fontFamily: 'DarumadropOne',
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: backgroundLight, size: 20),
                      onPressed: () {
                        _animationController.reverse().then((_) {
                          NotificationHelper._hideCurrentNotification();
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
