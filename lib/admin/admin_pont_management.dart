import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pontconnect/colors.dart';

class AdminPontManagement extends StatefulWidget {
  const AdminPontManagement({super.key});

  @override
  _AdminPontManagementPageState createState() => _AdminPontManagementPageState();
}

class _AdminPontManagementPageState extends State<AdminPontManagement> {
  List<dynamic> _ponts = [];
  bool _isLoading = false;

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPonts();
  }

  Future<void> _fetchPonts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}admin/adminGetPonts.php');
      final response = await http.get(url);
      final data = json.decode(response.body);
      if (data['success'] == true) {
        setState(() {
          _ponts = data['ponts'];
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addPont() async {
    if (_nomController.text.trim().isEmpty || _adresseController.text.trim().isEmpty) return;
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}admin/adminAddPont.php');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nom": _nomController.text.trim(),
          "adresse": _adresseController.text.trim(),
        }),
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Pont ajouté avec succès")));
        _nomController.clear();
        _adresseController.clear();
        _fetchPonts();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  Future<void> _deletePont(int pontId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}admin/adminDeletePont.php');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pont_id": pontId}),
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Pont supprimé avec succès")));
        _fetchPonts();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'] ?? "Erreur")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  Widget _buildPontItem(dynamic pont) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        title: Text(pont['nom'] ?? "Pont inconnu"),
        subtitle: Text("Adresse : ${pont['adresse'] ?? '-'}"),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: accentColor),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Confirmer la suppression"),
                content: const Text("Voulez-vous supprimer ce pont ?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Annuler"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deletePont(pont['pont_id']);
                    },
                    child: const Text("Supprimer", style: TextStyle(color: accentColor)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Formulaire pour ajouter un nouveau pont
  Widget _buildAddPontForm() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _nomController,
            decoration:  InputDecoration(
              labelText: "Nom du pont",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adresseController,
            decoration:  InputDecoration(
              labelText: "Adresse du pont",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _addPont,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),              ),
              child: const Text(
                  "Ajouter",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: backgroundLight),

              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "GESTION DES PONTS",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: backgroundLight),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          _buildAddPontForm(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _fetchPonts,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: _ponts.length,
                itemBuilder: (context, index) {
                  return _buildPontItem(_ponts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}