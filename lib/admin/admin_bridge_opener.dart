import 'package:flutter/material.dart';
import 'package:pontconnect/core/constants.dart';
import 'package:pontconnect/auth/user_session_storage.dart';
import 'package:pontconnect/core/notification_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// WIDGET PRINCIPAL
class AdminBridgeOpener extends StatefulWidget {
  const AdminBridgeOpener({super.key});

  @override
  State<AdminBridgeOpener> createState() => _AdminBridgeOpenerState();
}

class _AdminBridgeOpenerState extends State<AdminBridgeOpener> {
  // VARIABLES D'ÉTAT
  List<dynamic> _ponts = [];
  String? _selectedPontId;
  String? _statusMessage;
  bool _loading = false;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _fetchPonts();
  }

  // API : RÉCUPÉRATION DES PONTS
  Future<void> _fetchPonts() async {
    setState(() {
      _fetching = true;
      _statusMessage = null;
    });
    try {
      final String? token = UserSession.userToken;
      final response = await http.patch(
        Uri.parse("${ApiConstants.baseUrl}admin/ponts/status"),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['ponts'] != null) {
          setState(() {
            _ponts = data['ponts'];
          });
        } else {
          setState(() {
            _statusMessage =
                data['message'] ?? "Erreur lors de la récupération des ponts.";
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _statusMessage = "Non autorisé : token invalide ou expiré.";
        });
      } else {
        setState(() {
          _statusMessage = "Erreur serveur : ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur réseau : $e';
      });
    } finally {
      setState(() {
        _fetching = false;
      });
    }
  }

  // API : MISE À JOUR DU STATUT
  Future<void> _updatePontStatus(String status) async {
    if (_selectedPontId == null) return;
    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    try {
      final String? token = UserSession.userToken;
      final response = await http.patch(
        Uri.parse("${ApiConstants.baseUrl}admin/ponts/status"),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pont_id': int.parse(_selectedPontId!),
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          NotificationHelper.showSuccess(
              context, data['message'] ?? 'Statut mis à jour.');
        } else {
          NotificationHelper.showError(
              context, data['message'] ?? 'Erreur inconnue');
        }
        setState(() {
          _statusMessage = data['message'] ?? 'Erreur inconnue';
        });
        _fetchPonts();
      } else if (response.statusCode == 401) {
        NotificationHelper.showError(
            context, "Non autorisé : token invalide ou expiré.");
        setState(() {
          _statusMessage = "Non autorisé : token invalide ou expiré.";
        });
      } else {
        NotificationHelper.showError(
            context, "Erreur serveur : ${response.statusCode}");
        setState(() {
          _statusMessage = "Erreur serveur : ${response.statusCode}";
        });
      }
    } catch (e) {
      NotificationHelper.showError(context, 'Erreur réseau : $e');
      setState(() {
        _statusMessage = 'Erreur réseau : $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // UI : DROPDOWN DE SÉLECTION
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPontId,
      decoration: InputDecoration(
        filled: true,
        fillColor: backgroundLight,
        labelText: "Choisir un pont",
        labelStyle: const TextStyle(
          fontFamily: 'DarumadropOne',
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      items: _ponts
          .map((pont) => DropdownMenuItem(
                value: pont['PONT_ID'].toString(),
                child: Text(
                  "${pont['LIBELLE_PONT']} (${pont['STATUS_PONT']})",
                  style: const TextStyle(
                    fontFamily: 'DarumadropOne',
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedPontId = value;
          _statusMessage = null;
        });
      },
    );
  }

  // UI : STATUT ACTUEL
  Widget _buildStatus(
      Color statusColor, IconData statusIcon, String statusLabel) {
    return Column(
      children: [
        Text(
          "STATUT ACTUEL",
          style: TextStyle(
            fontFamily: 'DarumadropOne',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.13),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 12),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontFamily: 'DarumadropOne',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // UI : BOUTONS RONDS
  Widget _buildCircleActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _loading ? null : onTap,
          child: SizedBox(
            width: 62,
            height: 62,
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: backgroundLight,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(icon, color: backgroundLight, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  // BUILD PRINCIPAL
  @override
  Widget build(BuildContext context) {
    final pont = _selectedPontId == null
        ? null
        : _ponts.firstWhere(
            (p) => p['PONT_ID'].toString() == _selectedPontId,
            orElse: () => null,
          );

    Color statusColor = textSecondary;
    IconData statusIcon = Icons.help_outline_rounded;
    String statusLabel = "Sélectionnez un pont";
    if (pont != null) {
      final status = (pont['STATUS_PONT'] ?? '').toString().toLowerCase();
      switch (status) {
        case 'ouvert':
          statusColor = primaryColor;
          statusIcon = Icons.lock_open_rounded;
          statusLabel = "OUVERT";
          break;
        case 'ferme':
          statusColor = accentColor;
          statusIcon = Icons.lock_outline_rounded;
          statusLabel = "FERMÉ";
          break;
        case 'stop':
          statusColor = tertiaryColor;
          statusIcon = Icons.timelapse_rounded;
          statusLabel = "STOP";
          break;
        default:
          statusColor = textSecondary;
          statusIcon = Icons.help_outline_rounded;
          statusLabel = "INCONNU";
      }
    }

    return Scaffold(
      backgroundColor: backgroundCream,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'CONTRÔLE OUVERTURE PONT',
          style: TextStyle(
            fontFamily: 'DarumadropOne',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: backgroundLight,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: backgroundLight),
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                  decoration: BoxDecoration(
                    color: backgroundLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatus(statusColor, statusIcon, statusLabel),
                      const SizedBox(height: 24),
                      _buildDropdown(),
                      const SizedBox(height: 32),
                      if (_selectedPontId != null)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCircleActionButton(
                                  icon: Icons.lock_open_rounded,
                                  color: primaryColor,
                                  onTap: () => _updatePontStatus("ouvert"),
                                  tooltip: "Ouvrir",
                                ),
                                const SizedBox(width: 32),
                                _buildCircleActionButton(
                                  icon: Icons.lock_outline_rounded,
                                  color: accentColor,
                                  onTap: () => _updatePontStatus("ferme"),
                                  tooltip: "Fermer",
                                ),
                                const SizedBox(width: 32),
                                _buildCircleActionButton(
                                  icon: Icons.timelapse_rounded,
                                  color: tertiaryColor,
                                  onTap: () => _updatePontStatus("stop"),
                                  tooltip: "Stop",
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text("Ouvrir",
                                    style: TextStyle(
                                        fontFamily: 'DarumadropOne',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                SizedBox(width: 44),
                                Text("Fermer",
                                    style: TextStyle(
                                        fontFamily: 'DarumadropOne',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                SizedBox(width: 36),
                                Text("Stop",
                                    style: TextStyle(
                                        fontFamily: 'DarumadropOne',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                              ],
                            ),
                          ],
                        ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: _statusMessage!.contains("succès") ||
                                    _statusMessage!.contains("mis à jour")
                                ? primaryColor.withOpacity(0.12)
                                : accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: _statusMessage!.contains("succès") ||
                                      _statusMessage!.contains("mis à jour")
                                  ? primaryColor
                                  : accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'DarumadropOne',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
