import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/constants.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/screens/first_screen.dart';
import 'package:pawner_app/services/auth_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  final Usuario usuario;

  const DeleteAccountScreen({super.key, required this.usuario});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmTextController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmTextController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma la acción escribiendo ELIMINAR';
    }
    if (value.trim() != 'ELIMINAR') {
      return 'Debes escribir \'ELIMINAR\' para confirmar';
    }
    return null;
  }

  Future<void> _handleDeleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().deleteAccount(
        usuario: widget.usuario,
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorDialog(_getErrorMessage(e.code));
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al eliminar la cuenta: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'wrong-password':
        return 'La contraseña es incorrecta';
      case 'requires-recent-login':
        return 'Debes iniciar sesión de nuevo antes de eliminar la cuenta';
      case 'user-not-found':
        return 'No se encontró el usuario';
      case 'user-disabled':
        return 'La cuenta ha sido deshabilitada';
      case 'invalid-credential':
        return 'La contraseña es incorrecta';
      default:
        return 'No se pudo eliminar la cuenta. Inténtalo de nuevo.';
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.trash, color: Colors.redAccent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Cuenta eliminada', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: const Text(
          'Tu cuenta se eliminó correctamente. Esta acción es irreversible.\n\nAhora serás redirigid@ a la pantalla de inicio.',
          textAlign: .center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const FirstScreen()),
                (route) => false,
              );
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            const Expanded(child: Text('Error')),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.secondary,
        centerTitle: true,
        toolbarHeight: 40,
        title: const Text(
          'ELIMINAR CUENTA',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      backgroundColor: AppColors.homeScreenBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.trash,
                    size: 45,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Eliminar cuenta\nEsta acción es irreversible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu perfil, tu historial y tu acceso se eliminarán permanentemente. ',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: .center,
              ),
              const SizedBox(height: 20),
              if (widget.usuario.rol == UserRol.admin)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Text(
                    'Como administrador, tu rol pasará a otra persona de la familia. '
                    'Si eres el único miembro, la familia y sus mascotas también se borrarán.',
                    style: TextStyle(color: Colors.redAccent),
                    textAlign: .center,
                  ),
                ),
              if (widget.usuario.rol == UserRol.admin)
                const SizedBox(height: 20),
              const Text(
                'Contraseña actual',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.secondary.withAlpha(85),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 20),
              const Text(
                'Para confirmar, escribe ELIMINAR',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmTextController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.secondary.withAlpha(85),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: _validateConfirmation,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleDeleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: AppColors.cardWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cardWhite,
                          ),
                        )
                      : const Text(
                          'ELIMINAR CUENTA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
