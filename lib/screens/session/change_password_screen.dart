import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/first_screen.dart';
import 'package:pawner_app/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña actual es obligatoria';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La nueva contraseña es obligatoria';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (value == _currentPasswordController.text) {
      return 'La nueva contraseña debe ser diferente a la actual';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma la nueva contraseña';
    }
    if (value != _newPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().changePasswordFromCurrentPassword(
        email: FirebaseAuth.instance.currentUser!.email!,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
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
        _showErrorDialog('Error al cambiar la contraseña: ${e.toString()}');
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
        return 'La contraseña actual es incorrecta';
      case 'weak-password':
        return 'La nueva contraseña es demasiado débil';
      case 'requires-recent-login':
        return 'Debes haber iniciado sesión recientemente para cambiar la contraseña';
      case 'invalid-credential':
        return 'La contraseña actual es incorrecta';
      default:
        return 'Error al cambiar la contraseña. Inténtalo de nuevo.';
    }
  }

  void _showSuccessDialog() {
    final double screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Contraseña Cambiada y Sesión Cerrada',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: screenWidth * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu contraseña ha sido cambiada exitosamente.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Por seguridad, debes iniciar sesión de nuevo.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Cerrar diálogo
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FirstScreen()),
              );
            },
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final double screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Flexible(child: Text('Error')),
          ],
        ),
        content: SizedBox(width: screenWidth * 0.7, child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Aceptar'),
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
        title: Text(
          "CAMBIAR CONTRASEÑA",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      backgroundColor: AppColors.lightSecondary,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =============== ICONO ==============
              Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // =============== TÍTULO ==============
              Center(
                child: Text(
                  'Cambiar Contraseña',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  'Ingresa tu contraseña actual y la nueva',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              SizedBox(height: 32),

              // =============== CONTRASEÑA ACTUAL ==============
              Text(
                'Contraseña actual: *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                validator: _validateCurrentPassword,
                style: TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Tu contraseña actual',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  fillColor: AppColors.primary,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // =============== NUEVA CONTRASEÑA ==============
              Text(
                'Nueva contraseña: *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                validator: _validateNewPassword,
                style: TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Nueva contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  fillColor: AppColors.primary,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // =============== CONFIRMAR CONTRASEÑA ==============
              Text(
                'Confirmar nueva contraseña: *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
                style: TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Confirma la nueva contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  fillColor: AppColors.primary,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 32),

              // =============== BOTÓN CONFIRMAR ==============
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'CAMBIAR CONTRASEÑA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
