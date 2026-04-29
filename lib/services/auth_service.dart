import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/services/firestore_service.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<Usuario> getCurrentUser() async {
    return FirestoreService().getCurrentUser(currentUser!);
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> changeEmail({
    required String newEmail,
    required String userPassword,
  }) async {
    if (currentUser == null) return;

    // 1. Reautenticar al usuario
    AuthCredential credential = EmailAuthProvider.credential(
      email: currentUser!.email!,
      password: userPassword,
    );

    await currentUser!.reauthenticateWithCredential(credential);

    log("Enviando correo a $newEmail");
    // 2. Iniciar el cambio de email
    // Este método envía un correo de verificación a la NUEVA dirección.
    // El email no se cambiará en la base de datos hasta que el usuario haga clic en el enlace.
    await currentUser!.verifyBeforeUpdateEmail(newEmail);
  }

  Future<void> changePasswordFromCurrentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
