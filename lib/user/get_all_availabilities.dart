import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pontconnect/core/constants.dart';
import 'package:pontconnect/auth/user_session_storage.dart';
import 'package:pontconnect/core/notification_helper.dart';

class GetAllAvailabilities extends StatefulWidget {
  @override
  _GetAllAvailabilitiesState createState() => _GetAllAvailabilitiesState();
}

class _GetAllAvailabilitiesState extends State<GetAllAvailabilities> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<dynamic> _creneaux = [];
  List<dynamic> _ponts = [];
  dynamic _selectedPont;

  @override
  void initState() {
    super.initState();
    _fetchPonts();
  }

  // RÉCUPÉRATION DES PONTS
  Future<void> _fetchPonts() async {
    final token = UserSession.userToken;
    if (token == null) return;
    final url = Uri.parse("${ApiConstants.baseUrl}sensor/mesures");
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = json.decode(response.body);
      if (data['success'] == true && data['ponts'] != null) {
        setState(() {
          _ponts = data['ponts'];
          _selectedPont = _ponts.isNotEmpty ? _ponts[0] : null;
        });
        _fetchDisponibilites();
      }
    } catch (_) {}
  }

  // RÉCUPÉRATION DES DISPONIBILITÉS
  Future<void> _fetchDisponibilites() async {
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'Token JWT non trouvé');
      return;
    }
    if (_selectedPont == null || _selectedPont['pont_id'] == null) {
      NotificationHelper.showError(context, 'Veuillez sélectionner un pont');
      return;
    }
    setState(() {
      _isLoading = true;
      _creneaux = [];
    });
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String pontId = _selectedPont['pont_id'].toString();
    final url = Uri.parse(
      "${ApiConstants.baseUrl}user/availabilities?date=$dateStr&pont_id=$pontId",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = json.decode(response.body);
      if (data["success"] == true) {
        setState(() {
          _creneaux = data["creneaux"];
        });
      } else if (response.statusCode == 403) {
        NotificationHelper.showWarning(
            context, 'Session expirée. Veuillez vous reconnecter.');
        Navigator.pushReplacementNamed(context, '/login_screen');
      } else {
        NotificationHelper.showError(
            context, data["message"].toString().toUpperCase());
      }
    } catch (e) {
      NotificationHelper.showError(context, "ERREUR: ${e.toString()}");
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: backgroundLight,
              onSurface: textPrimary,
            ),
            dialogBackgroundColor: backgroundLight,
            textTheme:
                ThemeData.light().textTheme.apply(fontFamily: 'DarumadropOne'),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchDisponibilites();
    }
  }

  // CONSTRUCTION DE LA CARTE D'UN CRÉNEAU
  Widget _buildCreneauCard(dynamic creneau) {
    final String direction = creneau['direction'] ?? "";
    final String periode = creneau['periode'] ?? "";
    final String heureDeb = creneau['heure_debut'] ?? "";
    final String passage1 = creneau['passage1'] ?? "";
    final String passage2 = creneau['passage2'] ?? "";
    final String heureFin = creneau['heure_fin'] ?? "";

    final int capacite = int.parse('${creneau['capacite_max']}');
    final int nbConfirm = int.parse('${creneau['reservations_confirmees']}');
    final double progress = (nbConfirm / capacite).clamp(0.0, 1.0);

    // COULEUR INDICATIVE SELON REMPLISSAGE
    final Color statusColor = progress >= 1.0
        ? accentColor
        : (progress < 0.5 ? primaryColor : tertiaryColor);

    // INDICATEUR DE DISPONIBILITÉ
    final String statusText = progress >= 1.0 ? "COMPLET" : "DISPONIBLE";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // EN-TÊTE AVEC LES INFORMATIONS PRINCIPALES
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITRE ET DIRECTION
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            direction.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            periode,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BADGE DE STATUT
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            progress >= 1.0
                                ? Icons.do_not_disturb
                                : Icons.check_circle_outline,
                            size: 14,
                            color: statusColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // DIVIDER LÉGER
              Divider(height: 1, thickness: 0.5),

              // SECTION HORAIRES ET CAPACITÉ
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DÉTAILS DES HORAIRES
                    Row(
                      children: [
                        // HORAIRES PRINCIPAUX
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 16, color: statusColor),
                              SizedBox(width: 4),
                              Text(
                                heureDeb,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.arrow_forward,
                                    size: 14, color: textSecondary),
                              ),
                              Text(
                                heureFin,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // CAPACITÉ
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: backgroundLight,
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Text(
                            "$nbConfirm/$capacite",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 6),

                    // PASSAGES INTERMÉDIAIRES
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        children: [
                          Text(
                            "PASSAGES:",
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            passage1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (passage2.isNotEmpty) ...[
                            Text(
                              " • ",
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              passage2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // BARRE DE PROGRESSION
              LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.grey.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CONSTRUCTION DE L'INTERFACE
  @override
  Widget build(BuildContext context) {
    // SÉPARATION DES CRÉNEAUX PAR DIRECTION
    final sorties = _creneaux.where((c) {
      final dir = (c['direction'] ?? "").toString().toLowerCase();
      return dir.contains("sortie");
    }).toList();

    final entrees = _creneaux.where((c) {
      final dir = (c['direction'] ?? "").toString().toLowerCase();
      return dir.contains("entrée") || dir.contains("entre");
    }).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DISPONIBILITÉS',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: backgroundLight),
            ),
            if (_selectedPont != null && _selectedPont['libelle_pont'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _selectedPont['libelle_pont'].toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    color: backgroundLight.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
          ],
        ),
      ),
      backgroundColor: backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // SÉLECTION DU PONT ET DE LA DATE
            Row(
              children: [
                if (_ponts.isNotEmpty)
                  Expanded(
                    flex: 8,
                    child: DropdownButtonFormField<dynamic>(
                      value: _selectedPont,
                      decoration: InputDecoration(
                        labelText: "PONT",
                        labelStyle:
                            TextStyle(fontSize: 15, color: textSecondary),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _ponts.map<DropdownMenuItem<dynamic>>((p) {
                        return DropdownMenuItem<dynamic>(
                          value: p,
                          child: Text(
                            p['libelle_pont'].toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPont = val;
                        });
                        _fetchDisponibilites();
                      },
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "DATE",
                        labelStyle:
                            TextStyle(fontSize: 15, color: textSecondary),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // AFFICHAGE DES CRÉNEAUX
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : (_creneaux.isEmpty
                      ? Center(
                          child: Text("AUCUN CRÉNEAU TROUVÉ",
                              style:
                                  TextStyle(fontSize: 16, color: textPrimary)),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SECTION SORTIE
                              if (sorties.isNotEmpty) ...[
                                Image.asset(
                                  'assets/images/direction_sortie.webp',
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: sorties
                                      .map((c) => _buildCreneauCard(c))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // SECTION ENTRÉE
                              if (entrees.isNotEmpty) ...[
                                Image.asset(
                                  'assets/images/direction_entre.webp',
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: entrees
                                      .map((c) => _buildCreneauCard(c))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
