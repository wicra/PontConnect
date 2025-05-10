import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// STORAGE DES DONNEES DE L'UTILISATEUR
class UserSession {
  static final _storage = FlutterSecureStorage();

  // VARIABLES POUR RECUPERER LES DONNEES
  static int? userId;
  static String? userName;
  static String? userEmail;
  static int? typeUserId;
  static String? userToken;

  // METHODES POUR RECUPERER LES DONNEES
  static Future<void> setUser(
      {required int id,
      required String name,
      required String email,
      required int type,
      required String token}) async {
    // RE SAUVEGARDE DES DONNEES
    userId = id;
    userName = name;
    userEmail = email;
    typeUserId = type;
    userToken = token;

    // SAUVEGARDE DES DONNEES DANS LE STOCKAGE SECURISE
    await _storage.write(key: 'userId', value: id.toString());
    await _storage.write(key: 'userName', value: name);
    await _storage.write(key: 'userEmail', value: email);
    await _storage.write(key: 'typeUserId', value: type.toString());
    await _storage.write(key: 'userToken', value: token);
  }

  // METHODE POUR CHARGER LES DONNEES (À APPELER AU DÉMARRAGE)
  static Future<bool> loadSession() async {
    final storedToken = await _storage.read(key: 'userToken');
    if (storedToken == null) return false;

    userToken = storedToken;
    userName = await _storage.read(key: 'userName');
    userEmail = await _storage.read(key: 'userEmail');

    final storedUserId = await _storage.read(key: 'userId');
    userId = storedUserId != null ? int.parse(storedUserId) : null;

    final storedTypeId = await _storage.read(key: 'typeUserId');
    typeUserId = storedTypeId != null ? int.parse(storedTypeId) : null;

    return true;
  }

  // METHODE POUR SUPPRIMER LES DONNEES
  static Future<void> clear() async {
    userId = null;
    userName = null;
    userEmail = null;
    typeUserId = null;
    userToken = null;
    await _storage.deleteAll();
  }
}
