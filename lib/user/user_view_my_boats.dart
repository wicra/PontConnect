import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../auth/user_session_storage.dart';
import '../core/constants.dart';
import '../core/notification_helper.dart';

// PAGE DES BATEAUX DE L'UTILISATEUR
class ViewUserBateaux extends StatefulWidget {
  @override
  _ViewUserBateauxState createState() => _ViewUserBateauxState();
}

class _ViewUserBateauxState extends State<ViewUserBateaux> {
  // VARIABLES DE GESTION
  bool _isLoading = false;
  List<dynamic> _bateaux = [];

  @override
  void initState() {
    super.initState();
    _fetchBateaux();
  }

  // RÉCUPÉRATION DES BATEAUX DE L'UTILISATEUR
  Future<void> _fetchBateaux() async {
    // RÉCUPÉRATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'TOKEN JWT NON TROUVÉ');
      return;
    }

    final int? userId = UserSession.userId;
    if (userId == null) {
      NotificationHelper.showWarning(context, "UTILISATEUR NON CONNECTÉ");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // APPEL API
    final url = Uri.parse("${ApiConstants.baseUrl}user/boats?user_id=$userId");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
      );
      final data = json.decode(response.body);

      // SUCCÈS
      if (data["success"] == true && data["bateaux"] != null) {
        setState(() {
          _bateaux = data["bateaux"];
        });
      }
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        NotificationHelper.showWarning(
            context, 'SESSION EXPIRÉE. VEUILLEZ VOUS RECONNECTER.');
        Navigator.pushReplacementNamed(context, '/login_screen');
      }
      // AUTRES ERREURS
      else {
        NotificationHelper.showError(
            context, "ERREUR LORS DE LA RÉCUPÉRATION DES BATEAUX");
      }
    } catch (e) {
      NotificationHelper.showError(context, "ERREUR : ${e.toString()}");
    }

    setState(() {
      _isLoading = false;
    });
  }

  // SUPPRESSION D'UN BATEAU
  Future<void> _deleteBateau(int bateauId) async {
    // RÉCUPÉRATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'TOKEN JWT NON TROUVÉ');
      return;
    }

    final int? userId = UserSession.userId;
    if (userId == null) return;

    final url = Uri.parse(
        "${ApiConstants.baseUrl}user/boats?bateau_id=$bateauId&user_id=$userId");

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      // SUPPRESSION DU BATEAU RÉUSSIE
      if (data["success"] == true) {
        NotificationHelper.showSuccess(context, "BATEAU SUPPRIMÉ AVEC SUCCÈS");
        _fetchBateaux();
      }
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        NotificationHelper.showWarning(
            context, 'SESSION EXPIRÉE. VEUILLEZ VOUS RECONNECTER.');
        Navigator.pushReplacementNamed(context, '/login_screen');
      } else {
        NotificationHelper.showError(context, "ERREUR : ${data["message"]}");
      }
    } catch (e) {
      NotificationHelper.showError(context, "ERREUR : ${e.toString()}");
    }
  }

  // DIALOGUE DE CONFIRMATION DE SUPPRESSION
  void _showDeleteConfirmation(int bateauId, String bateauName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundLight,
          title: const Text("SUPPRIMER LE BATEAU"),
          content: Text(
              "LA SUPPRESSION DE \"$bateauName\" SUPPRIMERA VOS RÉSERVATIONS LIÉES À CE BATEAU ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ANNULER"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBateau(bateauId);
              },
              style: TextButton.styleFrom(
                foregroundColor: backgroundLight,
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "SUPPRIMER",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: backgroundLight,
                    fontFamily: 'DarumadropOne'),
              ),
            ),
          ],
        );
      },
    );
  }

  // DIALOGUE D'AJOUT D'UN BATEAU
  void _showAddBateauDialog() {
    String nom = "";
    String immatriculation = "";
    String hauteur = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundLight,
          title: const Text("AJOUTER UN BATEAU"),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // CHAMP NOM DU BATEAU
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Nom du bateau",
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                        fontFamily: 'DarumadropOne',
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: primaryColor,
                        fontFamily: 'DarumadropOne',
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: backgroundCream),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: backgroundLight,
                      prefixIcon: const Icon(Icons.directions_boat,
                          color: primaryColor),
                    ),
                    onChanged: (value) => nom = value,
                  ),
                  const SizedBox(height: 16),

                  // CHAMP IMMATRICULATION
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Immatriculation",
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                        fontFamily: 'DarumadropOne',
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: primaryColor,
                        fontFamily: 'DarumadropOne',
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: backgroundCream),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: backgroundLight,
                      prefixIcon: const Icon(Icons.email, color: primaryColor),
                    ),
                    onChanged: (value) => immatriculation = value,
                  ),
                  const SizedBox(height: 16),

                  // CHAMP HAUTEUR
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Hauteur (en mètres)",
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                        fontFamily: 'DarumadropOne',
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: primaryColor,
                        fontFamily: 'DarumadropOne',
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: backgroundCream),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: backgroundLight,
                      prefixIcon:
                          const Icon(Icons.straighten, color: primaryColor),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => hauteur = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "ANNULER",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: textPrimary,
                    fontFamily: 'DarumadropOne'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addBateau(nom, immatriculation, hauteur);
              },
              style: TextButton.styleFrom(
                foregroundColor: backgroundLight,
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "AJOUTER",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: backgroundLight,
                    fontFamily: 'DarumadropOne'),
              ),
            ),
          ],
        );
      },
    );
  }

  // AJOUT D'UN NOUVEAU BATEAU
  Future<void> _addBateau(
      String nom, String immatriculation, String hauteur) async {
    // RÉCUPÉRATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'TOKEN JWT NON TROUVÉ');
      return;
    }

    final int? userId = UserSession.userId;
    if (userId == null) {
      return;
    }

    final url = Uri.parse("${ApiConstants.baseUrl}user/boats");
    final body = {
      "user_id": userId.toString(),
      "nom": nom,
      "immatriculation": immatriculation,
      "hauteur_max": hauteur
    };

    try {
      final response = await http.post(url,
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body));

      final data = json.decode(response.body);

      // AJOUT DU BATEAU RÉUSSI
      if (data["success"] == true) {
        NotificationHelper.showSuccess(context, "BATEAU AJOUTÉ AVEC SUCCÈS");
        await _fetchBateaux();
      }
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        NotificationHelper.showWarning(
            context, 'SESSION EXPIRÉE. VEUILLEZ VOUS RECONNECTER.');
        Navigator.pushReplacementNamed(context, '/login_screen');
      } else {
        NotificationHelper.showError(
            context, "ERREUR: ${data["message"] ?? "Une erreur est survenue"}");
      }
    } catch (e) {
      NotificationHelper.showError(context, "ERREUR: ${e.toString()}");
    }
  }

  // CARTE D'UN BATEAU
  Widget _buildBateauCard(dynamic bateau) {
    final int bateauId = bateau['bateau_id'];
    final String libelleBateau = bateau['nom'] ?? "";
    final String immatriculation = bateau['immatriculation'] ?? "";

    String dateText = "-";
    if (bateau['created_at'] != null &&
        bateau['created_at'].toString().isNotEmpty) {
      try {
        dateText = DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(bateau['created_at']));
      } catch (e) {
        dateText = "-";
      }
    }
    final double hauteur =
        double.tryParse(bateau['hauteur_max']?.toString() ?? "0") ?? 0.0;

    return Card(
      color: backgroundCard,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.directions_boat,
                size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libelleBateau,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("IMMATRICUL : $immatriculation",
                      style: const TextStyle(fontSize: 14, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text("HAUTEUR : ${hauteur.toStringAsFixed(2)} M",
                      style: const TextStyle(fontSize: 14, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text("AJOUTÉ LE : $dateText",
                      style:
                          const TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: accentColor),
              onPressed: () => _showDeleteConfirmation(bateauId, libelleBateau),
            ),
          ],
        ),
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
          'MES BATEAUX',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: backgroundLight,
          ),
        ),
      ),

      // CONTENU PRINCIPAL
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bateaux.isEmpty
              ? const Center(child: Text("AUCUN BATEAU ENREGISTRÉ"))
              : RefreshIndicator(
                  onRefresh: _fetchBateaux,
                  child: ListView.builder(
                    itemCount: _bateaux.length,
                    itemBuilder: (context, index) =>
                        _buildBateauCard(_bateaux[index]),
                  ),
                ),

      // BOUTON D'AJOUT
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: _showAddBateauDialog,
        child: const Icon(Icons.add, color: backgroundLight),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
