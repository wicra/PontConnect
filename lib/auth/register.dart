import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// CENTRALISATION COULEURS & API
import 'package:pontconnect/constants.dart';

// PAGE D'INSCRIPTION
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  // VARIABLES
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // INSCRIPTION
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        // API REST URL
        Uri.parse('${ApiConstants.baseUrl}auth/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      // VERIFICATION DE LA REPONSE
      if (response.statusCode == 201 && data['success'] == true) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login_screen');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('INSRIPTION REUSSIE ! CONNECTEZ-VOUS')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'ERREUR D\'INSCRIPTION')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ERREUR DE CONNEXION AU SERVEUR')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // CORPS DE LA PAGE
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, tertiaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: textPrimary,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),

              // FORMULAIRE D'INSCRIPTION
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      "assets/images/logo.svg",
                      height: 90,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 30),

                    // CHAMPS DE SAISIE NOM
                    TextFormField(
                      controller: _nameController,
                      cursorColor: primaryColor,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',

                        labelStyle: TextStyle(
                          fontSize: 16,
                          color: textPrimary,
                          fontFamily: 'DarumadropOne',
                        ),
                        floatingLabelStyle: TextStyle(
                          color: primaryColor,
                          fontFamily: 'DarumadropOne',
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),

                        prefixIcon: const Icon(Icons.person, color: primaryColor),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // CHAMPS DE SAISIE EMAIL
                    TextFormField(
                      controller: _emailController,
                      cursorColor: primaryColor,
                      decoration: InputDecoration(
                        labelText: 'Email',

                        labelStyle: TextStyle(
                          fontSize: 16,
                          color: textPrimary,
                          fontFamily: 'DarumadropOne',
                        ),
                        floatingLabelStyle: TextStyle(
                          color: primaryColor,
                          fontFamily: 'DarumadropOne',
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),

                        prefixIcon: const Icon(Icons.email, color: primaryColor),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Format email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // CHAMPS DE SAISIE MOT DE PASSE
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      cursorColor: primaryColor,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',

                        labelStyle: TextStyle(
                          fontSize: 16,
                          color: textPrimary,
                          fontFamily: 'DarumadropOne',
                        ),
                        floatingLabelStyle: TextStyle(
                          color: primaryColor,
                          fontFamily: 'DarumadropOne',
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),

                        prefixIcon: const Icon(Icons.lock, color: primaryColor),
                        filled: true,
                        fillColor: Colors.grey.shade100,

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: primaryColor,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (value.length < 12) {
                          return 'Minimum 12 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // BOUTON D'INSCRIPTION
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "S'inscrire",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // LIEN VERS LA PAGE DE CONNEXION
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login_screen');
                      },
                      child: const Text(
                        "Déjà un compte ? Se connecter",
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}