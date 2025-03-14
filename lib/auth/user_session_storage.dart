// STORAGE DES DONNEES DE L'UTILISATEUR
class UserSession {

  // VARIABLES POUR RECUPERER LES DONNEES
  static int? userId;
  static String? userName;
  static String? userEmail;
  static int? typeUserId;

  // METHODES POUR RECUPERER LES DONNEES
  static void setUser({required int id, required String name, required String email,required int type}) {
    userId = id;
    userName = name;
    userEmail = email;
    typeUserId = type;
  }

  // METHODE POUR SUPPRIMER LES DONNEES
  static void clear() {
    userId = null;
    userName = null;
    userEmail = null;
    typeUserId = null;
  }
}