import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/first_screen.dart';
import 'package:pawner_app/services/auth_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  final String currentEmail;

  const ChangeEmailScreen({super.key, required this.currentEmail});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    // Validar formato de email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Introduce un correo electrónico válido';
    }
    // Verificar que no sea el mismo email
    if (value.toLowerCase() == widget.currentEmail.toLowerCase()) {
      return 'El nuevo correo debe ser diferente al actual';
    }
    return null;
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

  Future<void> _handleChangeEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Llamada al método de AuthService
      await AuthService().changeEmail(
        newEmail: _newEmailController.text.trim(),
        userPassword: _passwordController.text,
      );

      if (mounted) {
        // Mostrar diálogo explicativo y navegar a login
        _showLogoutDialog();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorDialog(_getErrorMessage(e.code));
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al cambiar el correo: ${e.toString()}');
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
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'email-already-in-use':
        return 'Este correo electrónico ya está en uso';
      case 'wrong-password':
        return 'La contraseña es incorrecta';
      case 'user-mismatch':
        return 'Las credenciales no coinciden';
      case 'invalid-credential':
        return 'Las credenciales no son válidas';
      default:
        return 'Error al cambiar el correo. Inténtalo de nuevo.';
    }
  }

  void _showLogoutDialog() {
    final double screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email_outlined, color: AppColors.accent),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Correo Enviado y Sesión Cerrada',
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
                'Se ha enviado un correo de verificación a:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _newEmailController.text.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '⚠️ IMPORTANTE:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                '1. Haz clic en el enlace de confirmación en tu NUEVO correo.\n'
                '2. Una vez verificado, inicia sesión de nuevo con tu nuevo email.\n'
                '3. Tu perfil se actualizará automáticamente.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              AuthService().signOut();
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
            Text('Error'),
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
          "CAMBIAR CORREO",
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
                    Icons.email_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // =============== TÍTULO ==============
              Center(
                child: Text(
                  'Cambiar Correo Electrónico',
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
                  'Ingresa tu nuevo correo y confirma tu identidad',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              SizedBox(height: 32),

              // =============== EMAIL ACTUAL ==============
              Text(
                'Correo actual:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.currentEmail,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // =============== NUEVO EMAIL ==============
              Text(
                'Nuevo correo electrónico: *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _newEmailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
                decoration: InputDecoration(
                  hintText: 'ejemplo@correo.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  fillColor: AppColors.primary,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // =============== CONTRASEÑA (REAUTENTICACIÓN) ==============
              Text(
                'Contraseña actual: *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Necesaria para confirmar tu identidad',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: _validatePassword,
                decoration: InputDecoration(
                  hintText: 'Tu contraseña actual',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
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
                  onPressed: _isLoading ? null : _handleChangeEmail,
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
                          'ENVIAR CORREO DE VERIFICACIÓN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24),

              // =============== INFORMACIÓN ==============
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[800],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Información',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Se enviará un enlace de confirmación a tu NUEVO correo\n'
                      '• Debes hacer clic en ese enlace para completar el cambio\n'
                      '• Tu contraseña se requiere para verificar tu identidad\n'
                      '• Cerraremos tu sesión después de cerrar esta pantalla',

                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[900],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
