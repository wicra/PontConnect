import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pontconnect/core/constants.dart';
import 'package:pontconnect/auth/user_session_storage.dart';
import 'package:pontconnect/core/notification_helper.dart';

// GESTION DES RÉSERVATIONS EN ATTENTE
class AdminPendingReservations extends StatefulWidget {
  @override
  _AdminPendingReservationsState createState() =>
      _AdminPendingReservationsState();
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

  // RÉCUPÉRATION DES RÉSERVATIONS
  Future<void> _fetchReservations() async {
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'Token JWT non trouvé');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final url = Uri.parse("${ApiConstants.baseUrl}admin/reservations/pending");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
      );

      // VÉRIFIER SI LA RÉPONSE EST DU JSON VALIDE
      if (response.statusCode != 200 || response.body.contains("<!DOCTYPE")) {
        setState(() {
          _errorMessage = "Erreur serveur: Réponse non valide";
          _isLoading = false;
        });
        return;
      }

      final data = json.decode(response.body);

      // SUCCÈS
      if (data["success"] == true) {
        setState(() {
          _reservations = data["reservations"];
        });
      }

      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        NotificationHelper.showWarning(
            context, 'Session expirée. Veuillez vous reconnecter.');
        Navigator.pushReplacementNamed(context, '/login_screen');
      } else {
        setState(() {
          _errorMessage = data["message"] ?? "Erreur inconnue";
        });
        NotificationHelper.showError(context, _errorMessage);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "ERREUR: $e";
      });
      NotificationHelper.showError(context, _errorMessage);
    }
    setState(() {
      _isLoading = false;
    });
  }

  // MISE À JOUR DU STATUT DE RÉSERVATION
  Future<void> _updateStatus(String reservationId, String newStatus) async {
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'Token JWT non trouvé');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url =
        Uri.parse("${ApiConstants.baseUrl}user/reservations-status");
    final body = json.encode({
      "reservation_id": reservationId,
      "new_status": newStatus,
    });

    try {
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      // TRAITER LA RÉPONSE
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          // SUCCÈS
          if (data["success"] == true) {
            NotificationHelper.showSuccess(context, data["message"]);
            _fetchReservations();
          }

          // SESSION EXPIREE
          else if (response.statusCode == 403) {
            NotificationHelper.showWarning(
                context, 'Session expirée. Veuillez vous reconnecter.');
            Navigator.pushReplacementNamed(context, '/login_screen');
          }

          // AUTRES ERREURS
          else {
            setState(() {
              _isLoading = false;
            });
            NotificationHelper.showError(
                context, data["message"] ?? "Erreur inconnue");
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          NotificationHelper.showError(context, "Erreur: Réponse non valide");
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        try {
          final errorData = json.decode(response.body);
          NotificationHelper.showError(context,
              "Erreur ${response.statusCode}: ${errorData['message'] ?? 'Inconnu'}");
        } catch (e) {
          NotificationHelper.showError(
              context, "Erreur ${response.statusCode}");
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      NotificationHelper.showError(context, "ERREUR: $e");
    }
  }

  // COULEUR SELON LE STATUT
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "confirmé":
        return primaryColor;
      case "annulé":
        return accentColor;
      case "en attente":
      default:
        return tertiaryColor;
    }
  }

  // FORMATAGE DE DATE (YYYY-MM-DD -> DD/MM/YYYY)
  String _formatDate(String? inputDate) {
    if (inputDate == null || inputDate.isEmpty) return "";

    try {
      final parts = inputDate.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (e) {}

    return inputDate;
  }

  // CONSTRUCTION DE LA CARTE DE RÉSERVATION
  Widget _buildReservationCard(dynamic reservation) {
    final String reservationId = reservation['reservation_id'];
    final String direction = reservation['direction'] ??
        reservation['pont_name'] ??
        "DIRECTION INCONNUE";
    final String bateauName = reservation['bateau_name'] ?? "BATEAU INCONNU";
    final String bateauImmatriculation =
        reservation['bateau_immatriculation'] ?? "IMMATRICULATION INCONNUE";
    final double bateauHauteur =
        double.tryParse(reservation['bateau_hauteur']?.toString() ?? "0") ??
            0.0;
    final String libelle = reservation['libelle'] ?? "";
    final String heureDebut = (reservation['heure_debut'] ?? "").toString();
    final String heureFin = (reservation['heure_fin'] ?? "").toString();
    final String userName = reservation['user_name'] ?? "UTILISATEUR INCONNU";
    final String reservationDate = reservation['reservation_date'] ?? "";
    final String currentStatus = reservation['statut'] ?? "en attente";
    final int confirmedCount =
        int.tryParse(reservation['confirmed_count']?.toString() ?? "0") ?? 0;
    final int capaciteMax =
        int.tryParse(reservation['capacite_max']?.toString() ?? "0") ?? 0;

    // FORMATAGE DES DONNÉES
    String formattedDate = _formatDate(reservationDate);

    String formatHeure(String heure) {
      return heure.length >= 5 ? heure.substring(0, 5) : heure;
    }

    String creneauText = libelle.isNotEmpty
        ? "$libelle · ${formatHeure(heureDebut)} - ${formatHeure(heureFin)}"
        : "${formatHeure(heureDebut)} - ${formatHeure(heureFin)}";

    double progress = capaciteMax > 0 ? confirmedCount / capaciteMax : 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      color: backgroundCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN-TÊTE AVEC DATE ET STATUT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // DATE DE RÉSERVATION MISE EN ÉVIDENCE
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: backgroundLight,
                      fontFamily: 'DarumadropOne',
                    ),
                  ),
                ),
                // STATUT ACTUEL
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LIGNE 1 - DIRECTION ET INFOS BATEAU
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.directions_boat,
                        color: primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            direction,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              fontFamily: 'DarumadropOne',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bateauName,
                            style: const TextStyle(
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
                            const Icon(Icons.badge,
                                color: secondaryColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              bateauImmatriculation,
                              style: const TextStyle(
                                fontSize: 13,
                                color: secondaryColor,
                                fontFamily: 'DarumadropOne',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.height,
                                color: secondaryColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "${bateauHauteur.toStringAsFixed(2)} M",
                              style: const TextStyle(
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

                Divider(
                    height: 24,
                    thickness: 1,
                    color: secondaryColor.withOpacity(0.3)),

                // LIGNE 2 - CRÉNEAU ET CONFIRMATIONS
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        creneauText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                          fontFamily: 'DarumadropOne',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: progress >= 0.8
                            ? Colors.red.withOpacity(0.1)
                            : progress >= 0.5
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$confirmedCount / $capaciteMax",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: progress >= 0.8
                              ? accentColor
                              : progress >= 0.5
                                  ? tertiaryColor
                                  : primaryColor,
                          fontFamily: 'DarumadropOne',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // BARRE DE PROGRESSION
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: textSecondary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(progress >= 0.8
                        ? accentColor
                        : progress >= 0.5
                            ? tertiaryColor
                            : primaryColor),
                  ),
                ),

                const SizedBox(height: 16),

                // LIGNE 3 - UTILISATEUR
                Row(
                  children: [
                    const Icon(Icons.person, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                          fontFamily: 'DarumadropOne',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // LIGNE 4 - BOUTONS D'ACTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // BOUTON CONFIRMER
                    ElevatedButton.icon(
                      onPressed: currentStatus == "confirmé"
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: backgroundLight,
                                  title: const Text(
                                    "CONFIRMATION",
                                    style: TextStyle(
                                      fontFamily: 'DarumadropOne',
                                      color: textPrimary,
                                    ),
                                  ),
                                  content: const Text(
                                    "Voulez-vous confirmer cette réservation ?",
                                    style: TextStyle(
                                      fontFamily: 'DarumadropOne',
                                      color: textSecondary,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
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
                                        _updateStatus(
                                            reservationId, "confirmé");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "CONFIRMER",
                                        style: TextStyle(
                                          fontFamily: 'DarumadropOne',
                                          color: backgroundLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                      icon: const Icon(Icons.check_circle,
                          color: backgroundLight),
                      label: const Text(
                        "CONFIRMER",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'DarumadropOne',
                          color: backgroundLight,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: Colors.green.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // BOUTON ANNULER
                    ElevatedButton.icon(
                      onPressed: currentStatus == "annulé"
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: backgroundLight,
                                  title: const Text(
                                    "CONFIRMATION",
                                    style: TextStyle(
                                      fontFamily: 'DarumadropOne',
                                      color: textPrimary,
                                    ),
                                  ),
                                  content: const Text(
                                    "Voulez-vous annuler cette réservation ?",
                                    style: TextStyle(
                                      fontFamily: 'DarumadropOne',
                                      color: textSecondary,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
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
                                        backgroundColor: accentColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "ANNULER",
                                        style: TextStyle(
                                          fontFamily: 'DarumadropOne',
                                          color: backgroundLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                      icon: const Icon(Icons.cancel, color: backgroundLight),
                      label: const Text(
                        "ANNULER",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'DarumadropOne',
                          color: backgroundLight,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        disabledBackgroundColor: Colors.red.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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

  // CONSTRUCTION DE L'INTERFACE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BARRE D'APPLICATION
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
            icon: const Icon(Icons.refresh, color: backgroundLight),
            onPressed: _fetchReservations,
            tooltip: "Actualiser",
          ),
        ],
      ),

      // CONTENU PRINCIPAL
      backgroundColor: backgroundLight,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: secondaryColor),
                  const SizedBox(height: 16),
                  const Text(
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
                      const Icon(
                        Icons.error_outline,
                        color: accentColor,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "ERREUR",
                        style: TextStyle(
                          fontSize: 18,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DarumadropOne',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: textPrimary,
                            fontFamily: 'DarumadropOne',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchReservations,
                        icon: const Icon(Icons.refresh, color: backgroundLight),
                        label: const Text(
                          "RÉESSAYER",
                          style: TextStyle(
                            color: backgroundLight,
                            fontFamily: 'DarumadropOne',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
                          const SizedBox(height: 16),
                          const Text(
                            "AUCUNE RÉSERVATION EN ATTENTE",
                            style: TextStyle(
                              fontSize: 18,
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DarumadropOne',
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchReservations,
                            icon: const Icon(Icons.refresh,
                                color: backgroundLight),
                            label: const Text(
                              "ACTUALISER",
                              style: TextStyle(
                                color: backgroundLight,
                                fontFamily: 'DarumadropOne',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReservations,
                      color: primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: _reservations.length,
                        itemBuilder: (context, index) {
                          return _buildReservationCard(_reservations[index]);
                        },
                      ),
                    ),
    );
  }
}
