import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Definimos la variable global aquí
late CrashManager firebaseController;

class CrashManager {
  final FirebaseCrashlytics _crashlytics;
  CrashManager(this._crashlytics);

  Future<void> reportCrash(dynamic e, [StackTrace? stack]) async {
    await _crashlytics.recordError(e, stack);
  }
}
