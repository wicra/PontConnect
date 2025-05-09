import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../auth/user_session_storage.dart';

/// PAGE DE RÉSERVATION DES CRÉNEAUX POUR L'UTILISATEUR
class UserAddReservation extends StatefulWidget {
  @override
  _UserAddReservationState createState() => _UserAddReservationState();
}

class _UserAddReservationState extends State<UserAddReservation> {
  // VARIABLES D'ÉTAT
  List<dynamic> _creneaux = [];
  List<dynamic> _bateaux = [];
  int? _selectedCreneauId;
  int? _selectedBateauId;
  DateTime? _selectedDate;
  bool _isLoadingBateaux = false;
  bool _isLoadingCreneaux = false;

  @override
  void initState() {
    super.initState();
    _fetchBateaux();
  }

  // RÉCUPÉRATION DES CRÉNEAUX DISPONIBLES
  Future<void> _fetchCreneaux() async {

    // RECUPERATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token JWT non trouvé')),
      );
      return;
    }

    if (_selectedDate == null) return;

    setState(() {
      _isLoadingCreneaux = true;
    });

    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final url = Uri.parse("${ApiConstants.baseUrl}user/creneaux?date=$dateStr");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token', // TOKEN JWT
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée. Veuillez vous reconnecter.')),
        );
        Navigator.pushReplacementNamed(context, '/login_screen');
      }
      
      else {
        setState(() {
          _isLoadingCreneaux = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ERREUR LORS DE LA RÉCUPÉRATION DES CRÉNEAUX")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingCreneaux = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ERREUR: $e")));
    }
  }

  // RÉCUPÉRATION DES BATEAUX DE L'UTILISATEUR
  Future<void> _fetchBateaux() async {

    // RECUPERATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token JWT non trouvé')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("UTILISATEUR NON CONNECTÉ")));
      return;
    }

    final url = Uri.parse("${ApiConstants.baseUrl}user/boats?user_id=$userId");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token', // TOKEN JWT
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée. Veuillez vous reconnecter.')),
        );
        Navigator.pushReplacementNamed(context, '/login_screen');
      }   
      
      else {
        setState(() {
          _isLoadingBateaux = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ERREUR LORS DE LA RÉCUPÉRATION DES BATEAUX")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingBateaux = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("ERREUR: $e")));
    }
  }

  // VALIDATION ET ENVOI DE LA RÉSERVATION
  Future<void> _reserve() async {
    // RECUPERATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token JWT non trouvé')),
      );
      return;
    }

    if (_selectedCreneauId == null || _selectedDate == null || _selectedBateauId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("VEUILLEZ REMPLIR TOUS LES CHAMPS")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("ENREGISTREMENT EN COURS...")
          ],
        ),
      ),
    );

    final userId = UserSession.userId;
    if (userId == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("UTILISATEUR NON CONNECTÉ")));
      return;
    }

    final url = Uri.parse("${ApiConstants.baseUrl}user/reservations-creneaux");
    final body = json.encode({
      "user_id": userId,
      "creneau_id": _selectedCreneauId,
      "bateau_id": _selectedBateauId,
      "reservation_date": _selectedDate!.toIso8601String().substring(0, 10),
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // TOKEN JWT
        }, 
        body: body);

      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        String message = jsonResponse is String ? jsonResponse : jsonResponse["message"];

        _fetchCreneaux();

        setState(() {
          _selectedCreneauId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.toUpperCase()),
              backgroundColor: primaryColor,
            )
        );
      }
      
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée. Veuillez vous reconnecter.')),
        );
        Navigator.pushReplacementNamed(context, '/login_screen');
      }

      else {
        final jsonResponse = json.decode(response.body);
        String message = jsonResponse is String ? jsonResponse : jsonResponse["message"];

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("ERREUR: ${message.toUpperCase()}"),
              backgroundColor: accentColor,
            )
        );
      }
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ERREUR: $e"),
            backgroundColor: accentColor,
          )
      );
    }
  }

  // COMPOSANTS D'INTERFACE UTILISATEUR

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
            labelStyle: TextStyle(fontSize: 15, color: textSecondary, fontFamily: 'DarumadropOne'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
          ),
          items: isLoading ? [] : items,
          value: isLoading ? null : value,
          onChanged: isLoading ? null : onChanged,
          dropdownColor: backgroundLight,
          iconEnabledColor: textPrimary,
          style: TextStyle(fontSize: 15, color: textPrimary, fontFamily: 'DarumadropOne'),
          hint: isLoading
              ? Text("CHARGEMENT...", style: TextStyle(fontFamily: 'DarumadropOne'))
              : hint ?? Text("SÉLECTIONNER", style: TextStyle(fontFamily: 'DarumadropOne')),
        ),
        if (isLoading)
          Positioned(
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
                textTheme: ThemeData.light().textTheme.apply(fontFamily: 'DarumadropOne'),
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
          labelStyle: TextStyle(fontSize: 15, color: textSecondary, fontFamily: 'DarumadropOne'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? "CHOISIR LA DATE"
                  : DateFormat('yyyy-MM-dd').format(_selectedDate!),
              style: TextStyle(fontSize: 15, color: textSecondary, fontFamily: 'DarumadropOne'),
            ),
            Icon(Icons.calendar_today, color: textSecondary),
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
            // SÉLECTION DU BATEAU
            _buildDropdownField<int>(
              label: "BATEAU",
              items: _bateaux.map((b) {
                return DropdownMenuItem<int>(
                  value: b['bateau_id'],
                  child: Text(b['nom'] ?? '', style: TextStyle(fontFamily: 'DarumadropOne')),
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
                  ? Text("AUCUN BATEAU DISPONIBLE", style: TextStyle(fontFamily: 'DarumadropOne'))
                  : null,
            ),
            const SizedBox(height: 16),

            // SÉLECTION DE LA DATE
            _buildDatePicker(),
            const SizedBox(height: 16),

            // SÉLECTION DU CRÉNEAU
            _buildDropdownField<int>(
              label: "CRÉNEAU",
              items: _creneaux.map((c) {
                String displayLabel = "${c['periode']} - ${c['direction']} : ${c['heure_debut']} - ${c['heure_fin']}";
                return DropdownMenuItem<int>(
                  value: c['creneau_id'],
                  child: Text(displayLabel, style: TextStyle(fontFamily: 'DarumadropOne')),
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
                  ? Text("SÉLECTIONNEZ UNE DATE", style: TextStyle(fontFamily: 'DarumadropOne'))
                  : null,
            ),
            const SizedBox(height: 24),

            // BOUTON DE RÉSERVATION
            ElevatedButton(
              onPressed: _reserve,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: secondaryColor,
              ),
              child: Text(
                "RÉSERVER",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DarumadropOne',
                  color: backgroundLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}