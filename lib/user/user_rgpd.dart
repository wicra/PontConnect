import 'package:flutter/material.dart';
import 'package:pontconnect/core/constants.dart';

// PAGE D'AIDE
class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

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
          'MENTIONS LÉGALES & RGPD',
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
            // SECTION : INTRODUCTION
            _buildSectionHeader('Protection de vos données'),
            const Text(
              'Conformément au Règlement Général sur la Protection des Données (RGPD), '
              'nous vous informons sur le traitement de vos données personnelles et vos droits.',
              style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),

            // SECTION : DONNÉES COLLECTÉES
            _buildCard(
              title: 'Données personnelles collectées',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pour permettre le bon fonctionnement de l\'application, nous collectons les données suivantes :',
                    style: TextStyle(
                        fontSize: 16, color: textSecondary, height: 1.5),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 16),
                  _buildIconInfo(
                    icon: Icons.person,
                    iconColor: primaryColor,
                    text: 'Informations de profil : nom, prénom, adresse email',
                  ),
                  const SizedBox(height: 16),
                  _buildIconInfo(
                    icon: Icons.directions_boat,
                    iconColor: secondaryColor,
                    text:
                        'Informations sur vos bateaux : nom, immatriculation, dimensions',
                  ),
                  const SizedBox(height: 16),
                  _buildIconInfo(
                    icon: Icons.calendar_today,
                    iconColor: tertiaryColor,
                    text:
                        'Historique des réservations et préférences de navigation',
                  ),
                ],
              ),
            ),

            // SECTION : DROITS DES UTILISATEURS
            _buildCard(
              title: 'Vos droits RGPD',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conformément à la réglementation, vous disposez des droits suivants :',
                    style: TextStyle(
                        fontSize: 16, color: textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  _buildIconInfo(
                    icon: Icons.visibility,
                    iconColor: primaryColor,
                    text: 'Droit d\'accès à vos données personnelles',
                  ),
                  const SizedBox(height: 12),
                  _buildIconInfo(
                    icon: Icons.edit,
                    iconColor: secondaryColor,
                    text: 'Droit de rectification des informations inexactes',
                  ),
                  const SizedBox(height: 12),
                  _buildIconInfo(
                    icon: Icons.delete,
                    iconColor: accentColor,
                    text:
                        'Droit à l\'effacement de vos données (droit à l\'oubli)',
                  ),
                  const SizedBox(height: 12),
                  _buildIconInfo(
                    icon: Icons.block,
                    iconColor: Colors.orange,
                    text: 'Droit d\'opposition au traitement de vos données',
                  ),
                  const SizedBox(height: 12),
                  _buildIconInfo(
                    icon: Icons.file_download,
                    iconColor: tertiaryColor,
                    text: 'Droit à la portabilité de vos données',
                  ),
                ],
              ),
            ),

            // SECTION : CONSERVATION DES DONNÉES
            _buildCard(
              title: 'Conservation des données',
              content: const Text(
                'Nous conservons vos données personnelles pour la durée nécessaire aux finalités du traitement :\n\n'
                '• Les données de compte sont conservées tant que votre compte est actif\n\n'
                '• L\'historique des réservations est conservé pendant 3 ans\n\n'
                '• Les données de navigation sont anonymisées après 12 mois',
                style:
                    TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
                textAlign: TextAlign.left,
              ),
            ),

            // SECTION : CONTACT DPO
            _buildCard(
              title: 'Exercer vos droits',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pour toute question relative à vos données ou pour exercer vos droits, contactez notre Délégué à la Protection des Données :',
                    style: TextStyle(
                        fontSize: 16, color: textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  _buildIconInfo(
                    icon: Icons.email,
                    iconColor: primaryColor,
                    text: 'dpo@pontconnect.fr',
                  ),
                  const SizedBox(height: 12),
                  _buildIconInfo(
                    icon: Icons.phone,
                    iconColor: secondaryColor,
                    text: '+33 (0)1 XX XX XX XX',
                  ),
                  const SizedBox(height: 12),
                  _buildIconInfo(
                    icon: Icons.location_on,
                    iconColor: tertiaryColor,
                    text: 'PontConnect SAS, 123 rue des Ponts, 75000 Paris',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // SECTION : VERSION
            Center(
              child: Text(
                'Version de l\'application : 1.2.1',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
