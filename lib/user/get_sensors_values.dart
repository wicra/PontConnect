import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pontconnect/core/constants.dart';
import 'package:pontconnect/auth/user_session_storage.dart';
import 'package:pontconnect/core/notification_helper.dart';

class GetSensorsValues extends StatefulWidget {
  const GetSensorsValues({Key? key}) : super(key: key);

  @override
  _GetSensorsValuesPageState createState() => _GetSensorsValuesPageState();
}

class _GetSensorsValuesPageState extends State<GetSensorsValues> {
  List<dynamic> _ponts = [];
  Timer? _refreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 10);
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _hasShownOutdatedWarning = false;

  // INITIALISATION ET LANCEMENT DU REFRESH AUTO
  @override
  void initState() {
    super.initState();
    _fetchPonts();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      _fetchPonts(silent: true);
    });
  }

  // RÉCUPÉRATION DES VALEURS DES CAPTEURS
  Future<void> _fetchPonts({bool silent = false}) async {
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'Token JWT non trouvé');
      return;
    }

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}sensor/mesures');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));
      final data = json.decode(response.body);

      if (data['success'] == true) {
        setState(() {
          _ponts = data['ponts'];
        });

        bool hasOutdatedData = false;
        for (var pont in _ponts) {
          if (pont['date_mesure'] != null) {
            DateTime sensorDate = DateTime.parse(pont['date_mesure']);
            if (DateTime.now().difference(sensorDate).inHours >= 4) {
              hasOutdatedData = true;
              break;
            }
          }
        }

        if (hasOutdatedData && !_hasShownOutdatedWarning) {
          _hasShownOutdatedWarning = true;
          NotificationHelper.showWarning(
              context, "DONNÉES NON À JOUR DEPUIS PLUS DE 4 HEURES");
        }
      } else if (response.statusCode == 403) {
        NotificationHelper.showWarning(
            context, 'Session expirée. Veuillez vous reconnecter.');
        Navigator.pushReplacementNamed(context, '/login_screen');
      } else if (!silent) {
        NotificationHelper.showError(
            context,
            (data['message'] ?? "ERREUR DE RÉCUPÉRATION")
                .toString()
                .toUpperCase());
      }
    } catch (e) {
      if (!silent) {
        NotificationHelper.showError(
            context, "ERREUR: ${e.toString().toUpperCase()}");
      }
    }
  }

  // NETTOYAGE DES RESSOURCES
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // CONSTRUCTION DE LA CARTE CAPTEUR
  Widget _buildCapteurCard(Map<String, dynamic> pont) {
    final String temperature = (pont['temperature'] ?? "0").toString();
    final String niveauEau = (pont['niveau_eau'] ?? "0").toString();
    final String turbinite = (pont['turbinite'] ?? "0").toString();
    final String humidite = (pont['humidite'] ?? "0").toString();

    final String uniteTemperature =
        (pont['unite_temperature'] ?? "°C").toString();
    final String uniteNiveau = (pont['unite_niveau'] ?? "cm").toString();
    final String uniteTurbinite = (pont['unite_turbinite'] ?? "ppm").toString();
    final String uniteHumidite = (pont['unite_humidite'] ?? "%").toString();

    final double niveauEauValue = double.tryParse(niveauEau) ?? 0;
    final double temperatureValue = double.tryParse(temperature) ?? 20;
    final double turbiniteValue = double.tryParse(turbinite) ?? 0;
    final double humiditeValue = double.tryParse(humidite) ?? 0;

    Color niveauEauColor = primaryColor;
    String niveauEauStatus = "NORMAL";
    if (niveauEauValue > 7) {
      niveauEauColor = accentColor;
      niveauEauStatus = "CRITIQUE";
    } else if (niveauEauValue > 5) {
      niveauEauColor = tertiaryColor;
      niveauEauStatus = "ÉLEVÉ";
    }

    Color temperatureColor = primaryColor;
    String temperatureStatus = "NORMAL";
    if (temperatureValue < 0) {
      temperatureColor = secondaryColor;
      temperatureStatus = "GEL";
    } else if (temperatureValue > 30) {
      temperatureColor = accentColor;
      temperatureStatus = "ÉLEVÉE";
    }

    Color turbiniteColor = Colors.green;
    String turbiniteStatus = "BONNE";
    if (turbiniteValue > 800) {
      turbiniteColor = accentColor;
      turbiniteStatus = "MAUVAISE";
    } else if (turbiniteValue > 500) {
      turbiniteColor = tertiaryColor;
      turbiniteStatus = "MOYENNE";
    }

    Color humiditeColor = Colors.blueGrey;
    String humiditeStatus = "OK";
    if (humiditeValue > 80) {
      humiditeColor = accentColor;
      humiditeStatus = "HUMIDE";
    } else if (humiditeValue < 30) {
      humiditeColor = secondaryColor;
      humiditeStatus = "SEC";
    }

    Widget capteurBloc({
      required IconData icon,
      required String title,
      required String value,
      required String unit,
      required String status,
      required Color statusColor,
    }) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.28), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: statusColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(9),
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
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "$value $unit",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                capteurBloc(
                  icon: Icons.thermostat,
                  title: "Température",
                  value: temperature,
                  unit: uniteTemperature,
                  status: temperatureStatus,
                  statusColor: temperatureColor,
                ),
                capteurBloc(
                  icon: Icons.water,
                  title: "Niveau d'eau",
                  value: niveauEau,
                  unit: uniteNiveau,
                  status: niveauEauStatus,
                  statusColor: niveauEauColor,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                capteurBloc(
                  icon: Icons.opacity,
                  title: "Turbidité",
                  value: turbinite,
                  unit: uniteTurbinite,
                  status: turbiniteStatus,
                  statusColor: turbiniteColor,
                ),
                capteurBloc(
                  icon: Icons.water_drop,
                  title: "Humidité",
                  value: humidite,
                  unit: uniteHumidite,
                  status: humiditeStatus,
                  statusColor: humiditeColor,
                ),
              ],
            ),
            if (pont['date_mesure'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.update, size: 11, color: textSecondary),
                    const SizedBox(width: 2),
                    Text(
                      _formatDate(pont['date_mesure']),
                      style: TextStyle(
                        fontSize: 9,
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

  // FORMATAGE DE LA DATE
  String _formatDate(String dateStr) {
    try {
      final DateTime date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }

  // INDICATEUR DE PAGE
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _ponts.length,
        (index) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
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
    String currentPontName = _ponts.isNotEmpty && _currentPage < _ponts.length
        ? (_ponts[_currentPage]['libelle_pont'] ?? "INCONNU")
            .toString()
            .toUpperCase()
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
            onPressed: () => _fetchPonts(),
            tooltip: "ACTUALISER",
          ),
        ],
      ),
      backgroundColor: backgroundLight,
      body: _ponts.isEmpty
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
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _ponts.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Center(
                        child: _buildCapteurCard(_ponts[index]),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe, color: textSecondary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        "${_currentPage + 1}/${_ponts.length}",
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
