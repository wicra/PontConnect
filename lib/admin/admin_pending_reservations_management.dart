import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AdminPendingReservations extends StatefulWidget {
  @override
  _AdminPendingReservationsState createState() => _AdminPendingReservationsState();
}

class _AdminPendingReservationsState extends State<AdminPendingReservations> {
  // VARIABLES DE GESTION
  bool _isLoading = false;
  List<dynamic> _reservations = [];
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  // FONCTION POUR RÉCUPÉRER LES RÉSERVATIONS EN ATTENTE VIA L'API
  Future<void> _fetchReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final url = Uri.parse("${ApiConstants.baseUrl}admin/getPendingReservations.php");
    try {
      final response = await http.get(url);

      // VÉRIFIER SI LA RÉPONSE EST DU JSON VALIDE
      if (response.statusCode != 200 || response.body.contains("<!DOCTYPE")) {
        setState(() {
          _errorMessage = "Erreur serveur: Réponse non valide";
          _isLoading = false;
        });
        return;
      }

      final data = json.decode(response.body);
      if (data["success"] == true) {
        setState(() {
          _reservations = data["reservations"];
        });
      } else {
        setState(() {
          _errorMessage = data["message"] ?? "Erreur inconnue";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage, style: TextStyle(color: backgroundLight))),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "ERREUR: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage, style: TextStyle(color: backgroundLight))),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  // FONCTION POUR METTRE À JOUR LE STATUT D'UNE RÉSERVATION VIA L'API
  Future<void> _updateStatus(String reservationId, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse("${ApiConstants.baseUrl}user/UpdateReservationStatus.php");
    final body = json.encode({
      "reservation_id": reservationId,
      "new_status": newStatus,
    });

    try {
      // AFFICHER LES DONNÉES ENVOYÉES POUR DÉBOGAGE
      print("URL: $url");
      print("BODY: $body");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      // AFFICHER LA RÉPONSE POUR DÉBOGAGE
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      // TRAITER LA RÉPONSE
      if (response.statusCode == 200) {
        // Tenter de décoder le JSON
        try {
          final data = json.decode(response.body);
          if (data["success"] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data["message"], style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            );
            // RECHARGER LES RÉSERVATIONS
            _fetchReservations();
          } else {
            setState(() {
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data["message"] ?? "Erreur inconnue", style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur: Réponse non valide", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Gérer les erreurs HTTP
        setState(() {
          _isLoading = false;
        });

        // Tenter d'extraire un message d'erreur JSON si disponible
        try {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur ${response.statusCode}: ${errorData['message'] ?? 'Inconnu'}", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          // Fallback pour les erreurs non-JSON
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur ${response.statusCode}", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("EXCEPTION: $e");
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ERREUR: $e", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // DÉTERMINER LA COULEUR DU STATUT
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "confirmé":
        return Colors.green;
      case "annulé":
        return Colors.red;
      case "en attente":
      default:
        return Colors.orange;
    }
  }

  // FORMATER LA DATE (YYYY-MM-DD -> DD/MM/YYYY)
  String _formatDate(String inputDate) {
    if (inputDate == null || inputDate.isEmpty) return "";

    try {
      final parts = inputDate.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}"; // jour/mois/année
      }
    } catch (e) {}

    return inputDate; // Retourner la date originale si le format est incorrect
  }

  // CONSTRUIRE LA CARTE DE RÉSERVATION
  Widget _buildReservationCard(dynamic reservation) {
    final String reservationId = reservation['reservation_id'];
    final String direction = reservation['direction'] ?? reservation['pont_name'] ?? "DIRECTION INCONNUE";
    final String bateauName = reservation['bateau_name'] ?? "BATEAU INCONNU";
    final String bateauImmatriculation = reservation['bateau_immatriculation'] ?? "IMMATRICULATION INCONNUE";
    final double bateauHauteur = double.tryParse(reservation['bateau_hauteur']?.toString() ?? "0") ?? 0.0;
    final String libelle = reservation['libelle'] ?? "";
    final String heureDebut = (reservation['heure_debut'] ?? "").toString();
    final String heureFin = (reservation['heure_fin'] ?? "").toString();
    final String userName = reservation['user_name'] ?? "UTILISATEUR INCONNU";
    final String reservationDate = reservation['reservation_date'] ?? "";
    final String currentStatus = reservation['statut'] ?? "en attente";
    final int confirmedCount = int.tryParse(reservation['confirmed_count']?.toString() ?? "0") ?? 0;
    final int capaciteMax = int.tryParse(reservation['capacite_max']?.toString() ?? "0") ?? 0;

    // FORMATER LA DATE POUR UN MEILLEUR AFFICHAGE
    String formattedDate = _formatDate(reservationDate);

    String formatHeure(String heure) {
      return heure.length >= 5 ? heure.substring(0, 5) : heure;
    }

    String creneauText = libelle.isNotEmpty
        ? "$libelle · ${formatHeure(heureDebut)} - ${formatHeure(heureFin)}"
        : "${formatHeure(heureDebut)} - ${formatHeure(heureFin)}";

    double progress = capaciteMax > 0 ? confirmedCount / capaciteMax : 0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      color: backgroundCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN-TÊTE AVEC DATE ET STATUT
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // DATE DE RÉSERVATION MISE EN ÉVIDENCE
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'DarumadropOne',
                    ),
                  ),
                ),
                // STATUT ACTUEL
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: _getStatusColor(currentStatus)),
                    borderRadius: BorderRadius.circular(8),
                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                  ),
                  child: Text(
                    currentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(currentStatus),
                      fontFamily: 'DarumadropOne',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONTENU PRINCIPAL
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LIGNE 1 - DIRECTION ET INFOS BATEAU
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.directions_boat, color: primaryColor, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            direction,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              fontFamily: 'DarumadropOne',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            bateauName,
                            style: TextStyle(
                              fontSize: 15,
                              color: textPrimary,
                              fontFamily: 'DarumadropOne',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge, color: secondaryColor, size: 16),
                            SizedBox(width: 4),
                            Text(
                              bateauImmatriculation,
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryColor,
                                fontFamily: 'DarumadropOne',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.height, color: secondaryColor, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "${bateauHauteur.toStringAsFixed(2)} M",
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryColor,
                                fontFamily: 'DarumadropOne',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                Divider(height: 24, thickness: 1, color: secondaryColor.withOpacity(0.3)),

                // LIGNE 2 - CRÉNEAU ET CONFIRMATIONS
                Row(
                  children: [
                    Icon(Icons.access_time, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        creneauText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                          fontFamily: 'DarumadropOne',
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: progress >= 0.8 ? Colors.red.withOpacity(0.1) :
                        progress >= 0.5 ? Colors.orange.withOpacity(0.1) :
                        Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$confirmedCount / $capaciteMax",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: progress >= 0.8 ? Colors.red :
                          progress >= 0.5 ? Colors.orange :
                          Colors.green,
                          fontFamily: 'DarumadropOne',
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // BARRE DE PROGRESSION
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: textSecondary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 0.8 ? Colors.red :
                        progress >= 0.5 ? Colors.orange :
                        Colors.green
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // LIGNE 3 - UTILISATEUR
                Row(
                  children: [
                    Icon(Icons.person, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                          fontFamily: 'DarumadropOne',
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // LIGNE 4 - BOUTONS D'ACTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // BOUTON CONFIRMER
                    ElevatedButton.icon(
                      onPressed: currentStatus == "confirmé" ? null : () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: backgroundLight,
                            title: Text(
                              "CONFIRMATION",
                              style: TextStyle(
                                fontFamily: 'DarumadropOne',
                                color: textPrimary,
                              ),
                            ),
                            content: Text(
                              "Voulez-vous confirmer cette réservation ?",
                              style: TextStyle(
                                fontFamily: 'DarumadropOne',
                                color: textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "ANNULER",
                                  style: TextStyle(
                                    fontFamily: 'DarumadropOne',
                                    color: secondaryColor,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _updateStatus(reservationId, "confirmé");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "CONFIRMER",
                                  style: TextStyle(
                                    fontFamily: 'DarumadropOne',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        "CONFIRMER",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'DarumadropOne',
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.green.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    SizedBox(width: 10),
                    // BOUTON ANNULER
                    ElevatedButton.icon(
                      onPressed: currentStatus == "annulé" ? null : () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: backgroundLight,
                            title: Text(
                              "CONFIRMATION",
                              style: TextStyle(
                                fontFamily: 'DarumadropOne',
                                color: textPrimary,
                              ),
                            ),
                            content: Text(
                              "Voulez-vous annuler cette réservation ?",
                              style: TextStyle(
                                fontFamily: 'DarumadropOne',
                                color: textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "RETOUR",
                                  style: TextStyle(
                                    fontFamily: 'DarumadropOne',
                                    color: secondaryColor,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _updateStatus(reservationId, "annulé");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "ANNULER",
                                  style: TextStyle(
                                    fontFamily: 'DarumadropOne',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.cancel, color: Colors.white),
                      label: Text(
                        "ANNULER",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'DarumadropOne',
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.red.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CONSTRUIRE LA PAGE DES RÉSERVATIONS EN ATTENTE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        title: const Text(
          'RÉSERVATIONS EN ATTENTE',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: backgroundLight,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: backgroundLight),
            onPressed: _fetchReservations,
            tooltip: "Actualiser",
          ),
        ],
      ),
      backgroundColor: backgroundLight,
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: secondaryColor),
            SizedBox(height: 16),
            Text(
              "CHARGEMENT...",
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.bold,
                fontFamily: 'DarumadropOne',
              ),
            ),
          ],
        ),
      )
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              "ERREUR",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DarumadropOne'
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: textPrimary,
                    fontFamily: 'DarumadropOne'
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchReservations,
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text(
                "RÉESSAYER",
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'DarumadropOne'
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      )
          : _reservations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              color: textSecondary.withOpacity(0.5),
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              "AUCUNE RÉSERVATION EN ATTENTE",
              style: TextStyle(
                  fontSize: 18,
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DarumadropOne'
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchReservations,
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text(
                "ACTUALISER",
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'DarumadropOne'
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchReservations,
        color: primaryColor,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 10),
          itemCount: _reservations.length,
          itemBuilder: (context, index) {
            return _buildReservationCard(_reservations[index]);
          },
        ),
      ),
    );
  }
}