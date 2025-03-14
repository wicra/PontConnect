import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pontconnect/auth/user_session_storage.dart';

// IMPORT DES CONSTANTES (API & COULEURS)
import 'package:pontconnect/constants.dart';

// PAGE DE MES RÉSERVATIONS POUR L'UTILISATEUR
class ViewMyReservations extends StatefulWidget {
  @override
  _ViewMyReservationsState createState() => _ViewMyReservationsState();
}

class _ViewMyReservationsState extends State<ViewMyReservations> {
  // VARIABLES DE GESTION
  bool _isLoading = false;
  List<dynamic> _reservations = [];

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  // FONCTION POUR RÉCUPÉRER LES RÉSERVATIONS DE L'UTILISATEUR VIA L'API
  Future<void> _fetchReservations() async {
    final int? userId = UserSession.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("UTILISATEUR NON CONNECTÉ")));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse("${ApiConstants.baseUrl}user/getUserReservations.php?user_id=$userId");
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      if (data["success"] == true) {
        setState(() {
          _reservations = data["reservations"];
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("ERREUR API")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("ERREUR : ${e.toString()}")));
    }
    setState(() {
      _isLoading = false;
    });
  }

  // FONCTION POUR DÉTERMINER LA COULEUR APPROPRIÉE EN FONCTION DU STATUT DE LA RÉSERVATION
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "CONFIRMÉ":
        return primaryColor;
      case "ANNULÉ":
        return accentColor;
      case "MAINTENANCE":
        return secondaryColor;
      case "EN ATTENTE":
        return tertiaryColor;
      default:
        return tertiaryColor;
    }
  }

  // FONCTION POUR METTRE À JOUR LE STATUT D'UNE RÉSERVATION VIA L'API
  Future<void> _updateStatus(String reservationId, String newStatus) async {
    final url = Uri.parse("${ApiConstants.baseUrl}user/updateReservationStatus.php");
    final body = json.encode({
      "reservation_id": reservationId,
      "new_status": newStatus.toLowerCase(),
    });
    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);
      final data = json.decode(response.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("STATUT MIS À JOUR")));
        _fetchReservations();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("ERREUR LORS DE LA MISE À JOUR: ${data["message"]}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("ERREUR : ${e.toString()}")));
    }
  }

  // FONCTION POUR VÉRIFIER SI LA RÉSERVATION EST DÉPASSÉE
  bool _isReservationPast(dynamic reservation) {
    final String dateStr = reservation['reservation_date'] ?? "";
    if (dateStr.isEmpty) return false;
    DateTime reservationDate;
    try {
      reservationDate = DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (e) {
      return false;
    }
    final String creneauStr = reservation['creneau'] ?? "";
    if (creneauStr.contains("-")) {
      final parts = creneauStr.split("-");
      if (parts.length > 1) {
        final lastPart = parts.last.trim();
        if (lastPart.contains(":")) {
          final timeParts = lastPart.split(":");
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);
            if (hour != null && minute != null) {
              try {
                final endDateTime = DateTime(
                  reservationDate.year,
                  reservationDate.month,
                  reservationDate.day,
                  hour,
                  minute,
                );
                return DateTime.now().isAfter(endDateTime);
              } catch (e) {
                return DateTime.now().isAfter(reservationDate);
              }
            }
          }
        }
      }
    }
    return DateTime.now().isAfter(reservationDate);
  }

  // CONSTRUIRE LA CARTE DE CHAQUE RÉSERVATION
  Widget _buildReservationCard(dynamic reservation) {
    final String reservationId = reservation['reservation_id'] ?? "";
    final String pontName = reservation['pont_name'] ?? "PONT INCONNU";
    final String creneau = reservation['creneau'] ?? "";
    final String reservationDateStr = reservation['reservation_date'] ?? "";
    final String realStatus = (reservation['statut'] ?? "EN ATTENTE").toUpperCase();
    // INFORMATION SUPPLÉMENTAIRE : NOM DU BATEAU ASSOCIÉ
    final String bateauName = reservation['bateau_name'] ?? "BATEAU INCONNU";

    final List<String> allowedStatusOptions = ["EN ATTENTE", "ANNULÉ"];
    final bool currentStatusAllowed = allowedStatusOptions.contains(realStatus);
    final bool isPast = _isReservationPast(reservation);
    final Color cardBackground = isPast ? backgroundCard : backgroundLight;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LIGNE 1 : EN-TÊTE AVEC NOM DU PONT ET DU BATEAU, ET STATUT
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pontName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DarumadropOne',
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "BATEAU : $bateauName",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'DarumadropOne',
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                isPast
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _getStatusColor(realStatus)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    realStatus,
                    style: TextStyle(
                      fontFamily: 'DarumadropOne',
                      color: _getStatusColor(realStatus),
                      fontSize: 14,
                    ),
                  ),
                )
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  decoration: BoxDecoration(
                    border: Border.all(color: _getStatusColor(realStatus)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: currentStatusAllowed ? realStatus : null,
                    hint: Text(
                      realStatus,
                      style: TextStyle(
                        fontFamily: 'DarumadropOne',
                        color: _getStatusColor(realStatus),
                        fontSize: 14,
                      ),
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(realStatus)),
                    style: TextStyle(
                      fontFamily: 'DarumadropOne',
                      color: _getStatusColor(realStatus),
                      fontSize: 14,
                    ),
                    dropdownColor: backgroundCream,
                    underline: Container(),
                    items: allowedStatusOptions.map((statusOption) {
                      return DropdownMenuItem<String>(
                        value: statusOption,
                        child: Text(
                          statusOption,
                          style: TextStyle(
                            fontFamily: 'DarumadropOne',
                            color: _getStatusColor(statusOption),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newStatus) {
                      if (newStatus != null && newStatus != realStatus) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: backgroundLight,
                              title: Text(
                                "CONFIRMER",
                                style: TextStyle(fontFamily: 'DarumadropOne', color: textPrimary),
                              ),
                              content: Container(
                                width: 450,
                                child: Text(
                                  "CHANGER LE STATUT EN '$newStatus' ?",
                                  style: TextStyle(fontFamily: 'DarumadropOne'),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text("ANNULER", style: TextStyle(fontFamily: 'DarumadropOne')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _updateStatus(reservationId, newStatus);
                                  },
                                  child: Text("CONFIRMER", style: TextStyle(fontFamily: 'DarumadropOne')),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // LIGNE 2 : AFFICHAGE DU CRÉNEAU
            Text(
              creneau,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: textSecondary,
                fontFamily: 'DarumadropOne',
              ),
            ),
            const SizedBox(height: 8),
            // LIGNE 3 : AFFICHAGE DE LA DATE DE RÉSERVATION
            Text(
              "DATE : ${DateFormat('yyyy-MM-dd').format(DateTime.tryParse(reservationDateStr) ?? DateTime.now())}",
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontFamily: 'DarumadropOne',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CONSTRUIRE LA PAGE MES RÉSERVATIONS
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        title: const Text(
          'MES RÉSERVATIONS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: backgroundLight,
          ),
        ),
      ),
      backgroundColor: backgroundLight,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _reservations.isEmpty
          ? Center(
        child: Text(
          "AUCUNE RÉSERVATION",
          style: TextStyle(
              fontSize: 16,
              fontFamily: 'DarumadropOne',
              color: textPrimary),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchReservations,
        child: ListView.builder(
          itemCount: _reservations.length,
          itemBuilder: (context, index) {
            return _buildReservationCard(_reservations[index]);
          },
        ),
      ),
    );
  }
}