import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pontconnect/core/constants.dart';
import 'package:pontconnect/auth/user_session_storage.dart';
import 'package:pontconnect/core/notification_helper.dart';

// PAGE DE RÉSERVATION DES CRÉNEAUX
class UserAddReservation extends StatefulWidget {
  @override
  _UserAddReservationState createState() => _UserAddReservationState();
}

class _UserAddReservationState extends State<UserAddReservation> {
  // VARIABLES D'ÉTAT
  List<dynamic> _creneaux = [];
  List<dynamic> _bateaux = [];
  List<dynamic> _ponts = [];
  int? _selectedCreneauId;
  int? _selectedBateauId;
  int? _selectedPontId;
  DateTime? _selectedDate;
  bool _isLoadingBateaux = false;
  bool _isLoadingCreneaux = false;
  bool _isLoadingPonts = false;

  @override
  void initState() {
    super.initState();
    _fetchPonts();
    _fetchBateaux();
  }

  // RÉCUPÉRATION DES PONTS
  Future<void> _fetchPonts() async {
    final token = UserSession.userToken;
    if (token == null) return;
    setState(() {
      _isLoadingPonts = true;
    });
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
      setState(() {
        _ponts = data['ponts'] ?? [];
        _selectedPontId = _ponts.isNotEmpty ? _ponts[0]['pont_id'] : null;
        _isLoadingPonts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPonts = false;
      });
      NotificationHelper.showError(context, "ERREUR: $e");
    }
  }

  // RÉCUPÉRATION DES CRÉNEAUX DISPONIBLES
  Future<void> _fetchCreneaux() async {
    // RÉCUPÉRATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'TOKEN JWT NON TROUVÉ');
      return;
    }

    if (_selectedDate == null || _selectedPontId == null) return;

    setState(() {
      _isLoadingCreneaux = true;
    });

    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final url = Uri.parse(
        "${ApiConstants.baseUrl}user/creneaux?date=$dateStr&pont_id=$_selectedPontId");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _creneaux = data["creneaux"];
          if (_selectedCreneauId != null &&
              !_creneaux.any((c) => c['creneau_id'] == _selectedCreneauId)) {
            _selectedCreneauId = null;
          }
          _isLoadingCreneaux = false;
        });
      }
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        NotificationHelper.showWarning(
            context, 'SESSION EXPIRÉE. VEUILLEZ VOUS RECONNECTER.');
        Navigator.pushReplacementNamed(context, '/login_screen');
      } else {
        setState(() {
          _isLoadingCreneaux = false;
        });
        NotificationHelper.showError(
            context, "ERREUR LORS DE LA RÉCUPÉRATION DES CRÉNEAUX");
      }
    } catch (e) {
      setState(() {
        _isLoadingCreneaux = false;
      });
      NotificationHelper.showError(context, "ERREUR: $e");
    }
  }

  // RÉCUPÉRATION DES BATEAUX DE L'UTILISATEUR
  Future<void> _fetchBateaux() async {
    // RÉCUPÉRATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'TOKEN JWT NON TROUVÉ');
      return;
    }

    setState(() {
      _isLoadingBateaux = true;
    });

    final int? userId = UserSession.userId;
    if (userId == null) {
      setState(() {
        _isLoadingBateaux = false;
      });
      NotificationHelper.showWarning(context, "UTILISATEUR NON CONNECTÉ");
      return;
    }

    final url = Uri.parse("${ApiConstants.baseUrl}user/boats?user_id=$userId");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _bateaux = data["bateaux"] ?? [];
          _isLoadingBateaux = false;
        });
      }
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        NotificationHelper.showWarning(
            context, 'SESSION EXPIRÉE. VEUILLEZ VOUS RECONNECTER.');
        Navigator.pushReplacementNamed(context, '/login_screen');
      } else {
        setState(() {
          _isLoadingBateaux = false;
        });
        NotificationHelper.showError(
            context, "ERREUR LORS DE LA RÉCUPÉRATION DES BATEAUX");
      }
    } catch (e) {
      setState(() {
        _isLoadingBateaux = false;
      });
      NotificationHelper.showError(context, "ERREUR: $e");
    }
  }

  // VALIDATION ET ENVOI DE LA RÉSERVATION
  Future<void> _reserve() async {
    // RÉCUPÉRATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      NotificationHelper.showError(context, 'TOKEN JWT NON TROUVÉ');
      return;
    }

    if (_selectedCreneauId == null ||
        _selectedDate == null ||
        _selectedBateauId == null ||
        _selectedPontId == null) {
      NotificationHelper.showWarning(
          context, "VEUILLEZ REMPLIR TOUS LES CHAMPS");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            const Text("ENREGISTREMENT EN COURS...")
          ],
        ),
      ),
    );

    final userId = UserSession.userId;
    if (userId == null) {
      Navigator.pop(context);
      NotificationHelper.showWarning(context, "UTILISATEUR NON CONNECTÉ");
      return;
    }

    final url = Uri.parse("${ApiConstants.baseUrl}user/reservations-creneaux");
    final body = json.encode({
      "user_id": userId,
      "creneau_id": _selectedCreneauId,
      "bateau_id": _selectedBateauId,
      "reservation_date": _selectedDate!.toIso8601String().substring(0, 10),
      "pont_id": _selectedPontId,
    });

    try {
      final response = await http.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: body);

      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        String message =
            jsonResponse is String ? jsonResponse : jsonResponse["message"];

        _fetchCreneaux();

        setState(() {
          _selectedCreneauId = null;
        });

        NotificationHelper.showSuccess(context, message.toUpperCase());
      }
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        NotificationHelper.showWarning(
            context, 'SESSION EXPIRÉE. VEUILLEZ VOUS RECONNECTER.');
        Navigator.pushReplacementNamed(context, '/login_screen');
      } else {
        final jsonResponse = json.decode(response.body);
        String message =
            jsonResponse is String ? jsonResponse : jsonResponse["message"];

        NotificationHelper.showError(
            context, "ERREUR: ${message.toUpperCase()}");
      }
    } catch (e) {
      Navigator.pop(context);
      NotificationHelper.showError(context, "ERREUR: $e");
    }
  }

  // DROPDOWN PERSONNALISÉ
  Widget _buildDropdownField<T>({
    required String label,
    required List<DropdownMenuItem<T>> items,
    T? value,
    required Function(T?) onChanged,
    Widget? hint,
    bool isLoading = false,
  }) {
    return Stack(
      children: [
        DropdownButtonFormField<T>(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
                fontSize: 15,
                color: textSecondary,
                fontFamily: 'DarumadropOne'),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
          ),
          items: isLoading ? [] : items,
          value: isLoading ? null : value,
          onChanged: isLoading ? null : onChanged,
          dropdownColor: backgroundLight,
          iconEnabledColor: textPrimary,
          style: const TextStyle(
              fontSize: 15, color: textPrimary, fontFamily: 'DarumadropOne'),
          hint: isLoading
              ? const Text("CHARGEMENT...",
                  style: TextStyle(fontFamily: 'DarumadropOne'))
              : hint ??
                  const Text("SÉLECTIONNER",
                      style: TextStyle(fontFamily: 'DarumadropOne')),
        ),
        if (isLoading)
          const Positioned(
            right: 40,
            top: 15,
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  // SÉLECTEUR DE DATE
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).primaryColor,
                  onPrimary: backgroundLight,
                  onSurface: textPrimary,
                ),
                dialogBackgroundColor: backgroundLight,
                textTheme: ThemeData.light()
                    .textTheme
                    .apply(fontFamily: 'DarumadropOne'),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _selectedCreneauId = null;
          });
          _fetchCreneaux();
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "DATE",
          labelStyle: const TextStyle(
              fontSize: 15, color: textSecondary, fontFamily: 'DarumadropOne'),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? "DATE"
                  : DateFormat('yyyy-MM-dd').format(_selectedDate!),
              style: const TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  fontFamily: 'DarumadropOne'),
            ),
            const Icon(Icons.calendar_today, color: textSecondary),
          ],
        ),
      ),
    );
  }

  // CONSTRUCTION DE L'INTERFACE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        title: const Text(
          'RÉSERVER UN CRÉNEAU',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: backgroundLight,
          ),
        ),
      ),
      backgroundColor: backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SÉLECTION DU PONT ET DE LA DATE (CÔTE À CÔTE)
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: _buildDropdownField<int>(
                    label: "PONT",
                    items: _ponts.map((p) {
                      return DropdownMenuItem<int>(
                        value: p['pont_id'],
                        child: Text(
                          p['libelle_pont'] ?? '',
                          style: const TextStyle(fontFamily: 'DarumadropOne'),
                        ),
                      );
                    }).toList(),
                    value: _selectedPontId,
                    onChanged: (val) {
                      setState(() {
                        _selectedPontId = val;
                        _selectedCreneauId = null;
                      });
                      _fetchCreneaux();
                    },
                    isLoading: _isLoadingPonts,
                    hint: _ponts.isEmpty && !_isLoadingPonts
                        ? const Text("0 PONT",
                            style: TextStyle(fontFamily: 'DarumadropOne'))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: _buildDatePicker(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SÉLECTION DU CRÉNEAU
            _buildDropdownField<int>(
              label: "CRÉNEAU",
              items: _creneaux.map((c) {
                String displayLabel =
                    "${c['periode']} - ${c['direction']} : ${c['heure_debut']} - ${c['heure_fin']}";
                return DropdownMenuItem<int>(
                  value: c['creneau_id'],
                  child: Text(displayLabel,
                      style: const TextStyle(fontFamily: 'DarumadropOne')),
                );
              }).toList(),
              value: _selectedCreneauId,
              onChanged: (val) {
                setState(() {
                  _selectedCreneauId = val;
                });
              },
              isLoading: _isLoadingCreneaux,
              hint: _creneaux.isEmpty && !_isLoadingCreneaux
                  ? const Text("SÉLECTIONNEZ UNE DATE",
                      style: TextStyle(fontFamily: 'DarumadropOne'))
                  : null,
            ),
            const SizedBox(height: 16),

            // SÉLECTION DU BATEAU ET BOUTON RÉSERVER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildDropdownField<int>(
                    label: "BATEAU",
                    items: _bateaux.map((b) {
                      return DropdownMenuItem<int>(
                        value: b['bateau_id'],
                        child: Text(b['nom'] ?? '',
                            style:
                                const TextStyle(fontFamily: 'DarumadropOne')),
                      );
                    }).toList(),
                    value: _selectedBateauId,
                    onChanged: (val) {
                      setState(() {
                        _selectedBateauId = val;
                      });
                    },
                    isLoading: _isLoadingBateaux,
                    hint: _bateaux.isEmpty && !_isLoadingBateaux
                        ? const Text("0 BATEAU",
                            style: TextStyle(fontFamily: 'DarumadropOne'))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _reserve,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: secondaryColor,
                      ),
                      child: const Text(
                        "RÉSERVER",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DarumadropOne',
                          color: backgroundLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
