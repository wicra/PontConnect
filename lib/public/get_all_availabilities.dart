import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class GetAllAvailabilities extends StatefulWidget {
  @override
  _GetAllAvailabilitiesState createState() => _GetAllAvailabilitiesState();
}

class _GetAllAvailabilitiesState extends State<GetAllAvailabilities> {
  // VARIABLES D'ÉTAT
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<dynamic> _creneaux = [];

  @override
  void initState() {
    super.initState();
    _fetchDisponibilites();
  }

  // RÉCUPÉRATION DES DISPONIBILITÉS
  Future<void> _fetchDisponibilites() async {
    setState(() {
      _isLoading = true;
      _creneaux = [];
    });
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final url = Uri.parse("${ApiConstants.baseUrl}user/GetAllAvailabilities?date=$dateStr");
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      if (data["success"] == true) {
        setState(() {
          _creneaux = data["creneaux"];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"].toString().toUpperCase())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("ERREUR: ${e.toString()}")));
    }
    setState(() {
      _isLoading = false;
    });
  }

  // SÉLECTION DE DATE
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
            textTheme: ThemeData.light().textTheme.apply(fontFamily: 'DarumadropOne'),
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
    final String statusText = progress >= 1.0
        ? "COMPLET"
        : "DISPONIBLE";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // Action au tap (facultatif - navigation vers détails)
        },
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
                            progress >= 1.0 ? Icons.do_not_disturb : Icons.check_circle_outline,
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
                              Icon(Icons.schedule, size: 16, color: statusColor),
                              SizedBox(width: 4),
                              Text(
                                heureDeb,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.arrow_forward, size: 14, color: textSecondary),
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
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: backgroundLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
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
        title: const Text(
          'DISPONIBILITÉS',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: backgroundLight),
        ),
      ),
      backgroundColor: backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // SÉLECTION DE LA DATE
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "DATE",
                        labelStyle: TextStyle(fontSize: 15, color: textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : (_creneaux.isEmpty
                  ? Center(
                child: Text("AUCUN CRÉNEAU TROUVÉ", style: TextStyle(fontSize: 16, color: textPrimary)),
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
                        children: sorties.map((c) => _buildCreneauCard(c)).toList(),
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
                        children: entrees.map((c) => _buildCreneauCard(c)).toList(),
                      ),
                    ],
                  ],
                ),
              )
              ),
            ),
          ],
        ),
      ),
    );
  }
}