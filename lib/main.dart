import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawner_app/screens/first_screen.dart';
import 'package:pawner_app/services/crash_manager.dart';
import 'package:pawner_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
  FlutterError.onError = crashlytics.recordFlutterFatalError;

  firebaseController = CrashManager(crashlytics);

  // Listener para sincronizar email en Firestore cuando cambie en Auth
  _setupEmailSyncListener();

  runApp(const MainApp());
}

/// Sincroniza el email de Firestore cuando el usuario confirma cambio en Auth
void _setupEmailSyncListener() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      // Obtener el email actual del usuario en Auth
      final currentEmail = user.email;
      if (currentEmail != null) {
        // Verificar y actualizar en Firestore si es diferente
        await _syncEmailWithFirestore(user.uid, currentEmail);
      }
    }
  });
}

/// Sincroniza el email del usuario en Firestore con el de Auth
Future<void> _syncEmailWithFirestore(String uid, String authEmail) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uid)
        .get();

    if (docSnapshot.exists) {
      final firestoreEmail = docSnapshot.data()?['email'] as String?;
      // Solo actualizar si son diferentes
      if (firestoreEmail != null &&
          firestoreEmail.toLowerCase() != authEmail.toLowerCase()) {
        await FirebaseFirestore.instance.collection('Usuarios').doc(uid).update(
          {'email': authEmail},
        );
      }
    }
  } catch (e) {
    // Silenciar errores de sync - no bloquea la app
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Nunito'),
      home: FirstScreen(),
    );
  }
}
