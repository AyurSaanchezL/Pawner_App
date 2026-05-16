import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pawner_app/screens/first_screen.dart';
import 'package:pawner_app/services/crash_manager.dart';
import 'package:pawner_app/services/notification_service.dart';
import 'package:pawner_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  log('FCM BACKGROUND: ${message.notification?.title}');
}

void main() async {
  // 1. Obligatorio para arrancar servicios asíncronos en Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Cargar configuraciones locales iniciales (No dependen de Firebase)
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es', null);

  // Declaramos la variable de Crashlytics arriba vacía
  FirebaseCrashlytics? crashlytics;

  try {
    // 3. ENCIENDE FIREBASE PRIMERO ◄── Aquí se soluciona tu error
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 4. Ahora que Firebase existe, ya podemos instanciar Crashlytics de forma segura
    crashlytics = FirebaseCrashlytics.instance;
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    firebaseController = CrashManager(crashlytics);

    // 5. Inicializar resto de servicios dependientes de Firebase
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().init();

    // 6. Listener para sincronizar email (Metido dentro para que no salte si falla Firebase)
    _setupEmailSyncListener();
  } catch (e) {
    // Si crashlytics ya se pudo inicializar bien antes del fallo, reportamos el crash
    if (crashlytics != null) {
      CrashManager(crashlytics).reportCrash(e);
    } else {
      debugPrint("Error crítico en el arranque de Firebase: $e");
    }
  }

  // 7. Arrancamos la interfaz gráfica
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
