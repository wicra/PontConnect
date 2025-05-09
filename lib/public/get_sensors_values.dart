import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pontconnect/constants.dart';
import '../auth/user_session_storage.dart';

class GetSensorsValues extends StatefulWidget {
  const GetSensorsValues({Key? key}) : super(key: key);

  @override
  _GetSensorsValuesPageState createState() => _GetSensorsValuesPageState();
}

class _GetSensorsValuesPageState extends State<GetSensorsValues> {
  // VARIABLES D'ÉTAT
  List<dynamic> _capteurs = [];
  Timer? _refreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 10);
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _hasShownOutdatedWarning = false;

  @override
  void initState() {
    super.initState();
    _fetchCapteurs();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      _fetchCapteurs(silent: true);
    });
  }

  // RÉCUPÉRATION DES DONNÉES CAPTEURS
  Future<void> _fetchCapteurs({bool silent = false}) async {

    // RÉCUPÉRATION DU TOKEN
    final token = UserSession.userToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token JWT non trouvé')),
      );
      return;
    }


    try {
      // APPEL API
      final url = Uri.parse('${ApiConstants.baseUrl}user/sensor-values');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // TOKEN JWT
        },
      ).timeout(const Duration(seconds: 20));
      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          _capteurs = data['ponts'];
        });

        // VÉRIFICATION DES DONNÉES OBSOLÈTES (UNIQUEMENT UNE FOIS PAR SESSION)
        bool hasOutdatedData = false;
        for (var pont in _capteurs) {
          if (pont['DATE_AJOUT'] != null) {
            DateTime sensorDate = DateTime.parse(pont['DATE_AJOUT']);
            if (DateTime.now().difference(sensorDate).inHours >= 4) {
              hasOutdatedData = true;
              break;
            }
          }
        }

        if (hasOutdatedData && !_hasShownOutdatedWarning) {
          _hasShownOutdatedWarning = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("DONNÉES NON À JOUR DEPUIS PLUS DE 4 HEURES")),
          );
        }
      } 

      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée. Veuillez vous reconnecter.')),
        );
        Navigator.pushReplacementNamed(context, '/login_screen');
      }

      else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((data['message'] ?? "ERREUR DE RÉCUPÉRATION").toString().toUpperCase())),
        );
      }
    } catch (e) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ERREUR: ${e.toString().toUpperCase()}")),
        );
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // CONSTRUCTION D'UNE CARTE DE CAPTEUR MODERNE
  Widget _buildCapteurCard(Map<String, dynamic> pont) {
    final String niveauEau = (pont['NIVEAU_EAU'] ?? "0").toString();
    final String temperature = (pont['TEMPERATURE'] ?? "0").toString();
    final String qualiteEau = (pont['HUMIDITE'] ?? "0").toString();

    // DÉTERMINATION DE L'ÉTAT DES CAPTEURS
    final double niveauEauValue = double.tryParse(niveauEau) ?? 0;
    final double temperatureValue = double.tryParse(temperature) ?? 20;

    // ÉTAT NIVEAU D'EAU
    Color niveauEauColor = primaryColor;
    String niveauEauStatus = "NORMAL";

    if (niveauEauValue > 7) {
      niveauEauColor = accentColor;
      niveauEauStatus = "CRITIQUE";
    } else if (niveauEauValue > 5) {
      niveauEauColor = tertiaryColor;
      niveauEauStatus = "ÉLEVÉ";
    }

    // ÉTAT TEMPÉRATURE
    Color temperatureColor = primaryColor;
    String temperatureStatus = "NORMAL";

    if (temperatureValue < 0) {
      temperatureColor = secondaryColor;
      temperatureStatus = "GEL";
    } else if (temperatureValue > 30) {
      temperatureColor = accentColor;
      temperatureStatus = "ÉLEVÉE";
    }

    // ÉTAT QUALITÉ D'EAU
    final double qualiteEauValue = double.tryParse(qualiteEau) ?? 0;
    Color qualiteEauColor = Colors.green;
    String qualiteEauStatus = "BONNE";

    if (qualiteEauValue > 800) {
      qualiteEauColor = accentColor;
      qualiteEauStatus = "MAUVAISE";
    } else if (qualiteEauValue > 500) {
      qualiteEauColor = tertiaryColor;
      qualiteEauStatus = "MOYENNE";
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // INDICATEURS DE CAPTEURS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // TEMPÉRATURE
                _buildCompactSensorIndicator(
                  icon: Icons.thermostat,
                  title: "TEMPÉRATURE",
                  value: "$temperature°C",
                  status: temperatureStatus,
                  statusColor: temperatureColor,
                ),

                // NIVEAU D'EAU
                _buildCompactSensorIndicator(
                  icon: Icons.water,
                  title: "NIVEAU D'EAU",
                  value: "$niveauEau cm",
                  status: niveauEauStatus,
                  statusColor: niveauEauColor,
                ),

                // PARTICULES (QUALITÉ D'EAU)
                _buildCompactSensorIndicator(
                  icon: Icons.opacity,
                  title: "PARTICULES",
                  value: "$qualiteEau ppm",
                  status: qualiteEauStatus,
                  statusColor: qualiteEauColor,
                ),
              ],
            ),

            // DERNIÈRE MISE À JOUR - UNIQUEMENT SI ESPACE DISPONIBLE
            if (pont['DATE_AJOUT'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.update, size: 12, color: textSecondary),
                    const SizedBox(width: 2),
                    Text(
                      _formatDate(pont['DATE_AJOUT']),
                      style: TextStyle(
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // FORMATAGE DE LA DATE DE MISE À JOUR
  String _formatDate(String dateStr) {
    try {
      final DateTime date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }

  // INDICATEUR DE CAPTEUR COMPACT
  Widget _buildCompactSensorIndicator({
    required IconData icon,
    required String title,
    required String value,
    required String status,
    required Color statusColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ICÔNE
            Icon(icon, size: 18, color: statusColor),

            const SizedBox(height: 4),

            // TITRE
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 5),

            // VALEUR
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),

            const SizedBox(height: 5),

            // STATUT
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // INDICATEURS DE PAGES
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _capteurs.length,
            (index) => Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  // CONSTRUCTION DE L'INTERFACE
  @override
  Widget build(BuildContext context) {
    String currentPontName = _capteurs.isNotEmpty && _currentPage < _capteurs.length
        ? (_capteurs[_currentPage]['LIBELLE_PONT'] ?? "INCONNU").toString().toUpperCase()
        : "CAPTEURS ACTIFS";

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        title: Text(
          currentPontName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: backgroundLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: backgroundLight),
            onPressed: () => _fetchCapteurs(),
            tooltip: "ACTUALISER",
          ),
        ],
      ),
      backgroundColor: backgroundLight,
      body: _capteurs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              "CHARGEMENT DES DONNÉES...",
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // CAROUSEL DE CAPTEURS
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _capteurs.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Center(
                  child: _buildCapteurCard(_capteurs[index]),
                );
              },
            ),
          ),

          // INDICATEURS DE PAGE ET INSTRUCTION DE GLISSEMENT COMBINÉS
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe, color: textSecondary, size: 12),
                const SizedBox(width: 4),
                Text(
                  "${_currentPage + 1}/${_capteurs.length}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                _buildPageIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}