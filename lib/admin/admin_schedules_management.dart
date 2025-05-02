import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'package:pontconnect/auth/user_session_storage.dart';

// GESTION DES CRÉNEAUX HORAIRES ADMIN
class AdminCreneauManagement extends StatefulWidget {
  const AdminCreneauManagement({Key? key}) : super(key: key);

  @override
  _AdminCreneauManagementState createState() => _AdminCreneauManagementState();
}

class _AdminCreneauManagementState extends State<AdminCreneauManagement> {
  // VARIABLES D'ÉTAT
  List<dynamic> _creneaux = [];
  List<dynamic> _periodes = [];
  List<dynamic> _directions = [];
  bool _isLoading = false;
  bool _isFormDataLoaded = false;
  Map<int, bool> _imageVisibility = {};

  @override
  void initState() {
    super.initState();
    _fetchCreneaux();
    _fetchFormData();
  }

  // RÉCUPÉRATION DES CRÉNEAUX
  Future<void> _fetchCreneaux() async {
    
    // RECUPERATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token JWT non trouvé')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}admin/adminGetHorairesCreneaux');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token', // TOKEN JWT
        },
      );

      // SUCCÈS
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _creneaux = data['creneaux'];
          });
        } else {
          _showErrorSnackBar(data['message'] ?? "ERREUR LORS DE LA RÉCUPÉRATION DES CRÉNEAUX");
        }
      } 
      
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée. Veuillez vous reconnecter.')),
        );
        Navigator.pushReplacementNamed(context, '/login_screen');
      }

      else {
        _showErrorSnackBar("ERREUR ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("ERREUR: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // RÉCUPÉRATION DES DONNÉES POUR LES FORMULAIRES
  Future<void> _fetchFormData() async {

    // RECUPERATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token JWT non trouvé')),
      );
      return;
    }

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}admin/adminGetFormDataHorairesCreneaux');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token', // TOKEN JWT
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // SUCCÈS
        if (data['success'] == true) {
          setState(() {
            _periodes = data['periodes'];
            _directions = data['directions'];
            _isFormDataLoaded = true;
          });
        } else {
          _showErrorSnackBar(data['message'] ?? "ERREUR LORS DE LA RÉCUPÉRATION DES DONNÉES DE FORMULAIRE");
        }
      }
      
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée. Veuillez vous reconnecter.')),
        );
        Navigator.pushReplacementNamed(context, '/login_screen');
      }

      // AUTRES ERREURS
      else {
        _showErrorSnackBar("ERREUR ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("ERREUR: $e");
    }
  }

  // AJOUT D'UN CRÉNEAU
  Future<void> _addCreneau(Map<String, dynamic> creneauData) async {
    await _postRequest(
      url: '${ApiConstants.baseUrl}admin/adminAddHoraireCreneau',
      data: creneauData,
      successMessage: "CRÉNEAU AJOUTÉ AVEC SUCCÈS",
    );
  }

  // MISE À JOUR D'UN CRÉNEAU
  Future<void> _updateCreneau(Map<String, dynamic> creneauData) async {
    await _postRequest(
      url: '${ApiConstants.baseUrl}admin/adminUpdateHoraireCreneau',
      data: creneauData,
      successMessage: "CRÉNEAU MIS À JOUR AVEC SUCCÈS",
    );
  }

  // SUPPRESSION D'UN CRÉNEAU
  Future<void> _deleteCreneau(int creneauId) async {
    await _postRequest(
      url: '${ApiConstants.baseUrl}admin/adminDeleteHoraireCreneau',
      data: {"horaires_id": creneauId},
      successMessage: "CRÉNEAU SUPPRIMÉ AVEC SUCCÈS",
    );
  }

  // MÉTHODE GÉNÉRIQUE POUR LES REQUÊTES POST
  Future<void> _postRequest({ required String url, required Map<String, dynamic> data, required String successMessage,}) async {

    // RECUPERATION DU TOKEN JWT
    final token = UserSession.userToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token JWT non trouvé')),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final uri = Uri.parse(url);

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token', // TOKEN JWT
        },
        body: json.encode(data),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final respData = json.decode(response.body);
          if (respData['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(successMessage), backgroundColor: primaryColor),
            );
            
            await Future.delayed(Duration(milliseconds: 100));
            if (mounted) {
              await _fetchCreneaux();
            }
          } else {
            _showErrorSnackBar(respData['message'] ?? "ERREUR LORS DE L'OPÉRATION");
          }
        } catch (e) {
          _showErrorSnackBar("ERREUR DE DÉCODAGE JSON: $e");
        }
      } 
      
      // SESSION EXPIREE
      else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée. Veuillez vous reconnecter.')),
        );
        Navigator.pushReplacementNamed(context, '/login_screen');
      }

      // AUTRES ERREURS
      else {
        _showErrorSnackBar("ERREUR HTTP ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("ERREUR: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // AFFICHAGE DES MESSAGES D'ERREUR
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: accentColor),
    );
  }

  // AFFICHAGE DES MESSAGES DE SUCCÈS
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryColor),
    );
  }

  // CONSTRUCTION DE LA CARTE D'UN CRÉNEAU
  Widget _buildCreneauCard(dynamic creneau) {
    // DONNÉES DU CRÉNEAU
    final int creneauId = int.parse(creneau['HORAIRES_ID']?.toString() ?? '0');
    final String periodeName = creneau['LIBELLE_PERIODE'] ?? "PÉRIODE INCONNUE";
    final String directionName = creneau['DIRECTION_TRAJET'] ?? creneau['LIBELLE_DIRECTION_CRENEAU'] ?? "DIRECTION INCONNUE";
    final String departTime = creneau['HORAIRE_DEPART'] ?? "--:--";
    final String passage1Time = creneau['HORAIRE_PASSAGE1'] ?? "--:--";
    final String passage2Time = creneau['HORAIRE_PASSAGE2'] ?? "--:--";
    final String passage3Time = creneau['HORAIRE_PASSAGE3'] ?? "--:--";

    // DÉTERMINATION DU TYPE DE DIRECTION
    final int directionId = int.tryParse(creneau['DIRECTION_CRENEAU_ID']?.toString() ?? '0') ?? 0;

    // DÉFINITION DES ATTRIBUTS SELON LA DIRECTION
    IconData directionIcon;
    String directionLabel;
    Color directionColor;
    String imagePath;

    switch (directionId) {
      case 1:
        directionIcon = Icons.logout;
        directionLabel = "SORTIE";
        directionColor = primaryColor;
        imagePath = 'assets/images/sortie.webp';
        break;
      case 2:
        directionIcon = Icons.login;
        directionLabel = "ENTRÉE";
        directionColor = secondaryColor ;
        imagePath = 'assets/images/entre.webp';
        break;
      default:
        directionIcon = Icons.swap_horiz;
        directionLabel = "AUTRE";
        directionColor = tertiaryColor;
        imagePath = 'assets/images/default.webp';
    }

    // VÉRIFICATION DE LA VISIBILITÉ DE L'IMAGE
    bool isImageVisible = _imageVisibility[creneauId] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN-TÊTE DE LA CARTE
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: backgroundLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ICÔNE DE DIRECTION AVEC BOUTON D'AFFICHAGE D'IMAGE
                InkWell(
                  onTap: () {
                    setState(() {
                      _imageVisibility[creneauId] = !isImageVisible;
                    });
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: directionColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isImageVisible ? Icons.visibility_off : Icons.visibility,
                      color: directionColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // INFORMATIONS PRINCIPALES
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(directionIcon, size: 16, color: directionColor),
                          const SizedBox(width: 4),
                          Text(
                            directionLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: directionColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        directionName,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // BADGE PÉRIODE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    periodeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // AFFICHAGE DE L'IMAGE SI DEMANDÉ
          if (isImageVisible)
            Container(
              height: 140,
              width: double.infinity,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),

          // SÉPARATEUR
          Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),

          // HORAIRES
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeItem("DÉPART", departTime, Icons.directions_boat_filled_outlined, directionColor),
                    if (passage1Time != "--:--")
                      _buildTimeItem("P1", passage1Time, Icons.access_time, textSecondary),
                    if (passage2Time != "--:--")
                      _buildTimeItem("P2", passage2Time, Icons.access_time, textSecondary),
                    if (passage3Time != "--:--")
                      _buildTimeItem("P3", passage3Time, Icons.access_time, textSecondary),
                  ],
                ),
              ],
            ),
          ),

          // ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // BOUTON MODIFIER
                TextButton.icon(
                  onPressed: () => _showCreneauDialog(creneau: creneau),
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text("MODIFIER"),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 8),

                // BOUTON SUPPRIMER
                TextButton.icon(
                  onPressed: () => _confirmDeleteCreneau(creneauId),
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text("SUPPRIMER"),
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ÉLÉMENT D'HEURE SIMPLIFIÉ
  Widget _buildTimeItem(String label, String time, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  // DIALOGUE DE CONFIRMATION DE SUPPRESSION
  Future<void> _confirmDeleteCreneau(int creneauId) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundLight,
        title: const Text(
          "CONFIRMER LA SUPPRESSION",
          style: TextStyle(color: textPrimary),
        ),
        content: const Text(
          "VOULEZ-VOUS VRAIMENT SUPPRIMER CE CRÉNEAU HORAIRE ? CETTE ACTION EST IRRÉVERSIBLE.",
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER", style: TextStyle(color: secondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCreneau(creneauId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("SUPPRIMER", style: TextStyle(color: backgroundLight)),
          )
        ],
      ),
    );
  }

  // DIALOGUE D'AJOUT/ÉDITION DE CRÉNEAU
  Future<void> _showCreneauDialog({dynamic creneau}) async {
    if (!_isFormDataLoaded) {
      _showErrorSnackBar("CHARGEMENT DES DONNÉES EN COURS...");
      return;
    }

    final isEditing = creneau != null;

    // S'ASSURER QUE LES DONNÉES DE FORMULAIRE SONT CHARGÉES
    if (_directions.isEmpty || _periodes.isEmpty) {
      await _fetchFormData();
      if (_directions.isEmpty || _periodes.isEmpty) {
        _showErrorSnackBar("IMPOSSIBLE DE CHARGER LES DONNÉES DE FORMULAIRE");
        return;
      }
    }

    // INITIALISATION DES VALEURS
    int periodeId;
    int directionId;

    try {
      if (isEditing) {
        periodeId = int.parse(creneau['PERIODE_ID'].toString());
        directionId = int.parse(creneau['DIRECTION_CRENEAU_ID'].toString());
      } else {
        periodeId = int.parse(_periodes[0]['PERIODE_ID'].toString());
        directionId = int.parse(_directions[0]['DIRECTION_CRENEAU_ID'].toString());
      }
    } catch (e) {
      periodeId = 1; // Valeur de secours
      directionId = 1; // Valeur de secours
    }

    // CONTROLEURS DE SAISIE DES HEURES
    final TextEditingController departController = TextEditingController(
        text: isEditing && creneau['HORAIRE_DEPART'] != null ? creneau['HORAIRE_DEPART'].toString() : ''
    );

    final TextEditingController passage1Controller = TextEditingController(
        text: isEditing && creneau['HORAIRE_PASSAGE1'] != null && creneau['HORAIRE_PASSAGE1'] != "--:--"
            ? creneau['HORAIRE_PASSAGE1'].toString()
            : ''
    );

    final TextEditingController passage2Controller = TextEditingController(
        text: isEditing && creneau['HORAIRE_PASSAGE2'] != null && creneau['HORAIRE_PASSAGE2'] != "--:--"
            ? creneau['HORAIRE_PASSAGE2'].toString()
            : ''
    );

    final TextEditingController passage3Controller = TextEditingController(
        text: isEditing && creneau['HORAIRE_PASSAGE3'] != null && creneau['HORAIRE_PASSAGE3'] != "--:--"
            ? creneau['HORAIRE_PASSAGE3'].toString()
            : ''
    );

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: backgroundLight,
          title: Text(
            isEditing ? "MODIFIER UN CRÉNEAU" : "AJOUTER UN CRÉNEAU",
            style: TextStyle(color: textPrimary),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 450,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DROPDOWNS PÉRIODE & DIRECTION
                  Text("PÉRIODE", style: TextStyle(color: textSecondary, fontSize: 14)),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: periodeId.toString(),
                    items: _periodes.map((periode) {
                      return DropdownMenuItem<String>(
                        value: periode['PERIODE_ID'].toString(),
                        child: Text(periode['LIBELLE_PERIODE'] ?? ""),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => periodeId = int.parse(value));
                      }
                    },
                    hint: "SÉLECTIONNEZ UNE PÉRIODE",
                  ),
                  const SizedBox(height: 12),

                  // DROPDOWN DIRECTION
                  Text("DIRECTION", style: TextStyle(color: textSecondary, fontSize: 14)),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: directionId.toString(),
                    items: _directions.map((direction) {
                      return DropdownMenuItem<String>(
                        value: direction['DIRECTION_CRENEAU_ID'].toString(),
                        child: Text(direction['LIBELLE_DIRECTION'] ?? "DIRECTION SANS NOM"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => directionId = int.parse(value));
                      }
                    },
                    hint: "SÉLECTIONNEZ UNE DIRECTION",
                  ),
                  const SizedBox(height: 16),

                  // CHAMPS DE SAISIE D'HEURE
                  Text("HORAIRES", style: TextStyle(color: textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildTimeField("HEURE DE DÉPART *", departController, primaryColor),
                  const SizedBox(height: 8),
                  _buildTimeField("PASSAGE 1", passage1Controller, primaryColor),
                  const SizedBox(height: 8),
                  _buildTimeField("PASSAGE 2", passage2Controller, primaryColor),
                  const SizedBox(height: 8),
                  _buildTimeField("PASSAGE 3", passage3Controller, primaryColor),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ANNULER", style: TextStyle(color: secondaryColor)),
            ),
            ElevatedButton(
              onPressed: () {
                if (departController.text.isEmpty || passage1Controller.text.isEmpty || passage2Controller.text.isEmpty || passage3Controller.text.isEmpty) {
                  _showErrorSnackBar("TOUS LES CHAMPS SONT OBLIGATOIRES");
                  return;
                }

                // CONSTRUCTION DES DONNÉES DU CRÉNEAU
                final Map<String, dynamic> creneauData = {
                  'periode_id': periodeId,
                  'direction_id': directionId,
                  'horaire_depart': departController.text.trim(),
                  'horaire_passage1': passage1Controller.text.trim(),
                  'horaire_passage2': passage2Controller.text.trim(),
                  'horaire_passage3': passage3Controller.text.trim()
                };

                if (isEditing) {
                  creneauData['horaires_id'] = int.parse(creneau['HORAIRES_ID'].toString());
                  _updateCreneau(creneauData);
                } else {
                  _addCreneau(creneauData);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isEditing ? "MODIFIER" : "AJOUTER",
                style: TextStyle(color: backgroundLight),
              ),
            ),
          ],
        ),
      ),
    );

    // LIBÉRATION DES RESSOURCES
    departController.dispose();
    passage1Controller.dispose();
    passage2Controller.dispose();
    passage3Controller.dispose();
  }

  // CONSTRUCTION D'UN DROPDOWN PERSONNALISÉ
  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        hint: Text(hint, style: TextStyle(color: textPrimary)),
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        style: TextStyle(color: textPrimary),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  // CHAMP DE SAISIE D'HEURE AVEC TIME PICKER
  Widget _buildTimeField(String label, TextEditingController controller, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(color: textSecondary, fontSize: 14)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "HH:MM",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: textSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: GestureDetector(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: controller.text.isNotEmpty ? _parseTimeString(controller.text) : TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: primaryColor,
                            onPrimary: backgroundLight,
                            onSurface: textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    controller.text = _formatTimeOfDay(picked);
                  }
                },
                child: Icon(Icons.access_time, color: color),
              ),
            ),
            style: TextStyle(color: textPrimary),
          ),
        ),
      ],
    );
  }

  // CONVERSION DE STRING EN TIMEODAY
  TimeOfDay _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  // FORMATAGE DE TIMEODAY EN STRING
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // CONSTRUCTION DE L'INTERFACE PRINCIPALE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BARRE D'APPLICATION
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        title: const Text(
          'GESTION DES CRÉNEAUX HORAIRES',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: backgroundLight),
        ),
      ),
      
      // CONTENU PRINCIPAL
      backgroundColor: backgroundLight,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _creneaux.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 80, color: textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 24),
                      Text(
                        "AUCUN CRÉNEAU HORAIRE TROUVÉ",
                        style: TextStyle(fontSize: 18, color: textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "AJOUTEZ UN NOUVEAU CRÉNEAU AVEC LE BOUTON CI-DESSOUS",
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCreneaux,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _creneaux.length,
                    itemBuilder: (context, index) => _buildCreneauCard(_creneaux[index]),
                  ),
                ),
      
      // BOUTON D'AJOUT
      floatingActionButton: _isFormDataLoaded
          ? FloatingActionButton(
              backgroundColor: primaryColor,
              onPressed: () => _showCreneauDialog(),
              tooltip: 'AJOUTER UN CRÉNEAU',
              child: const Icon(Icons.add, color: backgroundLight),
            )
          : null,
    );
  }
}