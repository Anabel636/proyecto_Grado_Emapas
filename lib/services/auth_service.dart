import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Este servicio centraliza todas las operaciones de autenticación.
// En lugar de escribir código de Firebase en cada pantalla,
// lo escribimos aquí una sola vez y lo llamamos desde cualquier lugar.

class AuthService {
  // Instancia de Firebase Auth — es el objeto que maneja usuarios
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Instancia de Firestore — para guardar datos adicionales del usuario
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Retorna el usuario actual (null si no hay sesión iniciada)
  User? get currentUser => _auth.currentUser;

  // Stream que emite eventos cuando el estado de sesión cambia
  // (útil para detectar si el usuario cerró sesión)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─────────────────────────────────────────
  // REGISTRO DE NUEVO USUARIO
  // ─────────────────────────────────────────
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
  }) async {
    // Crea el usuario en Firebase Authentication
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Actualiza el nombre en el perfil de Auth
    await credential.user!.updateDisplayName(nombre);

    // Guarda datos adicionales en Firestore
    // (Firebase Auth solo guarda email, uid y nombre)
    await _firestore.collection('usuarios').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'rol': 'ciudadano', // Rol por defecto
      'fechaRegistro': FieldValue.serverTimestamp(),
      'activo': true,
    });

    return credential;
  }

  // ─────────────────────────────────────────
  // INICIO DE SESIÓN
  // ─────────────────────────────────────────
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─────────────────────────────────────────
  // RECUPERAR CONTRASEÑA
  // ─────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
    // Firebase envía un correo automáticamente al usuario
  }

  // ─────────────────────────────────────────
  // CERRAR SESIÓN
  // ─────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─────────────────────────────────────────
  // OBTENER DATOS DEL USUARIO DESDE FIRESTORE
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;
    
    final doc = await _firestore
        .collection('usuarios')
        .doc(currentUser!.uid)
        .get();
    
    return doc.data();
  }

  // ─────────────────────────────────────────
  // CONVERTIR ERRORES DE FIREBASE A ESPAÑOL
  // ─────────────────────────────────────────
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      default:
        return 'Error inesperado. Intenta de nuevo';
    }
  }
}