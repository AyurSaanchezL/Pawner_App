import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Definimos la variable global aquí
late FirebasePawnerController firebaseController; 

class FirebasePawnerController {
  final FirebaseCrashlytics _crashlytics;
  FirebasePawnerController(this._crashlytics);

  Future<void> reportCrash(dynamic e, [StackTrace? stack]) async {
    await _crashlytics.recordError(e, stack);
  }
}