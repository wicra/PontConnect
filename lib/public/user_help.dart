import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pontconnect/constants.dart';

// PAGE D'AIDE
class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  // WIDGETS POUR LES ICONES SVG
  Widget _buildSvgIconInfo({
    required String svgAsset,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          svgAsset,
          color: iconColor,
          width: 28,
          height: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  // WIDGET POUR LES ICONES
  Widget _buildIconInfo({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  // WIDGET POUR LES CARTES
  Widget _buildCard({
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  // WIDGET POUR LES TITRES DE SECTION
  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: secondaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,

      // BARRE DE NAVIGATION
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        title: const Text(
          'AIDE & INFORMATIONS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: backgroundLight,
          ),
        ),
      ),

      // CORPS DE LA PAGE
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // SECTION : PRESENTATION
            _buildSectionHeader('Présentation'),
            const Text(
              'Découvrez une application moderne et épurée pour consulter les ponts et gérer vos réservations. '
                  'Une interface intuitive et agréable pour faciliter votre navigation.',
              style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),

            // SECTION : FONCTIONNALITES
            _buildCard(
              title: 'Page d\'Accueil - Informations sur les Ponts',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Un carrousel interactif présente divers ponts avec des informations essentielles :',
                    style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 16),
                  _buildSvgIconInfo(
                    svgAsset: 'assets/images/boat.svg',
                    iconColor: primaryColor,
                    text: 'Pont ouvert pour le passage des bateaux et engins navigables.',
                  ),
                  const SizedBox(height: 16),
                  _buildSvgIconInfo(
                    svgAsset: 'assets/images/car.svg',
                    iconColor: secondaryColor,
                    text: 'Pont fermé pour la navigation, accessible via voie routière.',
                  ),
                  const SizedBox(height: 16),
                  _buildIconInfo(
                    icon: Icons.thermostat,
                    iconColor: accentColor,
                    text: 'Affichage de la température ambiante.',
                  ),
                  const SizedBox(height: 16),
                  _buildIconInfo(
                    icon: Icons.water_damage,
                    iconColor: tertiaryColor,
                    text: 'Indication du taux d\'humidité pour une vue complète.',
                  ),
                ],
              ),
            ),

            // SECTION : FONCTIONNALITES
            _buildCard(
              title: 'Page d\'Accueil - Disponibilités',
              content: const Text(
                'Consultez les disponibilités en sélectionnant le pont et en choisissant une date. '
                    'La barre de recherche vous guide pour trouver le créneau idéal.',
                style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
                textAlign: TextAlign.left,
              ),
            ),

            // SECTION : FONCTIONNALITES
            _buildCard(
              title: 'Réservation',
              content: const Text(
                'Planifiez vos réservations en deux étapes :\n\n'
                    '• Ajoutez une réservation en sélectionnant la date, l’heure et le pont souhaité.\n\n'
                    '• Suivez vos réservations récentes et annulez-les si nécessaire.',
                style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 40),

            // SECTION : REMERCIEMENTS
            Center(
              child: Text(
                'Merci d\'utiliser notre application !',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
