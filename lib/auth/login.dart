import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:pontconnect/auth/user_session_storage.dart';
import 'dart:convert';

// CENTRALISATION COULEURS & API
import 'package:pontconnect/constants.dart';

// PAGE DE CONNEXION
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // VARIABLES
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;


  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        // API REST URL
        Uri.parse('${ApiConstants.baseUrl}auth/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      // VERIFICATION DE LA REPONSE
      if (response.statusCode == 200 && data['success'] == true) {
        // ENREGISTREMENT DE LA SESSION UTILISATEUR
        UserSession.setUser(
          id: data['user']['id'],
          name: data['user']['name'],
          email: data['user']['email'],
          type: data['user']['type_user_id'],
        );

        // CONNEXION REUSSI & REDIRECTION
        if (mounted) {
          if (data['user']['type_user_id'] == 1) {
            Navigator.pushReplacementNamed(context, '/admin_page');
          } else {
            Navigator.pushReplacementNamed(context, '/user_page');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'ERRREUR DE CONNEXION')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ERRREUR DE CONNEXION AU SERVEUR')),
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
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),

              // FORMULAIRE DE CONNEXION
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SvgPicture.asset(
                      "assets/images/logo.svg",
                      height: 90,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 30),

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
                          return 'Veuillez entrer votre mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Minimum 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // BOUTON DE CONNEXION
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: backgroundLight)
                            : const Text(
                          "Connexion",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: backgroundLight,
                          ),
                        ),
                      ),
                    ),

                    // LIENS VERS LES PAGES D'INSCRIPTION & VISITEUR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/register_screen');
                          },
                          child: const Text(
                            "Pas de compte ? S'inscrire",
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    )
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}