import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/components/bottom_logo.dart';
import 'package:pawner_app/core/constants.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/screens/session/change_email_screen.dart';
import 'package:pawner_app/screens/session/change_password_screen.dart';
import 'package:pawner_app/screens/session/delete_account_screen.dart';
import 'package:pawner_app/services/firestore_service.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  final Usuario u;
  const PerfilUsuarioScreen({super.key, required this.u});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  bool isEditingUsername = false;
  bool isEditingEmail = false;
  late TextEditingController usernameController;
  late TextEditingController emailController;

  @override
  void dispose() {
    super.dispose();
    usernameController.dispose();
    emailController.dispose();
  }

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    emailController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    usernameController.text = widget.u.nombre;
    emailController.text = widget.u.email;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightSecondary,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        actionsPadding: .only(right: 10),
        actions: [
          IconButton.filled(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeleteAccountScreen(usuario: widget.u),
                ),
              );
            },
            icon: Icon(LucideIcons.trash),
            style: ButtonStyle(
              backgroundColor: .all(Colors.redAccent.withAlpha(155)),
              iconColor: .all(AppColors.cardWhite),
              iconSize: .all(20),
              side: .all(BorderSide(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.lightSecondary,
      body: _buildBody(widget.u),
    );
  }

  Widget _buildBody(Usuario usuario) {
    return LayoutBuilder(
      builder: (thisContext, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                spacing: 30,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildAvatar(usuario),
                  Text(
                    "Hola👋 ¿Qué necesitas?",
                    style: TextStyle(fontSize: 18, fontWeight: .w600),
                  ),
                  SizedBox(height: 10),
                  isEditingUsername
                      ? _buildTextField(
                          "Nombre de usuario",
                          usernameController,
                          setState,
                          usuario,
                        )
                      : _buildTextContainers(
                          "Nombre de usuario",
                          usernameController.text,
                          setState,
                        ),
                  isEditingEmail
                      ? _buildTextField(
                          "Correo electrónico",
                          emailController,
                          setState,
                          usuario,
                        )
                      : _buildTextContainers(
                          "Correo electrónico",
                          emailController.text,
                          setState,
                        ),
                  RichText(
                    text: TextSpan(
                      text: "Cambiar contraseña",
                      style: TextStyle(
                        color: AppColors.secondary,
                        letterSpacing: .5,
                        fontWeight: .w500,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          );
                        },
                    ),
                  ),
                  Spacer(),
                  BottomLogo(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextContainers(
    String titulo,
    String text,
    StateSetter setThisState,
  ) {
    return Center(
      child: Column(
        children: [
          Text(titulo, style: TextStyle(fontSize: 16, fontWeight: .w500)),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 8),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(155),
                    border: Border.all(color: AppColors.primary.withAlpha(155)),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      text,
                      textAlign: .center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -15,
                right: 5,
                child: IconButton(
                  onPressed: () {
                    if (titulo.trim().contains('usuario')) {
                      setThisState(() {
                        isEditingUsername = !isEditingUsername;
                      });
                    } else {
                      // Navegar a la pantalla de cambio de email
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeEmailScreen(
                            currentEmail: emailController.text,
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(LucideIcons.edit, size: 25),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String titulo,
    TextEditingController controller,
    StateSetter setThisState,
    Usuario u,
  ) {
    bool autoFocus = false;
    if (titulo.toLowerCase().contains('usuario')) {
      autoFocus = isEditingUsername;
    } else {
      autoFocus = isEditingEmail;
    }
    return Center(
      child: Column(
        children: [
          Text(titulo, style: TextStyle(fontSize: 16, fontWeight: .w500)),
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, top: 8),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                filled: true,
                fillColor: AppColors.primary.withAlpha(155),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.primary.withAlpha(155),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
              ),
              autofocus: autoFocus,
              onSubmitted: (value) {
                _editUser(u);
                _toggleEditing(titulo, setThisState);
              },
              // 2. Detectar cuando se toca fuera del campo (desenfocar)
              onTapOutside: (event) {
                FocusScope.of(context).unfocus(); // Cierra el teclado
                _toggleEditing(titulo, setThisState);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEditing(String titulo, StateSetter setThisState) {
    setThisState(() {
      if (titulo.toLowerCase().contains('usuario')) {
        isEditingUsername = false;
      } else {
        isEditingEmail = false;
      }
    });
  }

  Widget _buildAvatar(Usuario usuario) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lightSecondary,
            radius: 65,
            child: Image.asset(FotosPerfil.getProfileImage(usuario.fotoUrl)),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              onPressed: () {
                _openImagePicker(usuario);
              },
              icon: Icon(LucideIcons.edit, size: 25),
            ),
          ),
        ],
      ),
    );
  }

  void _openImagePicker(Usuario u) {
    List<String> fotosLista = FotosPerfil.values
        .map((foto) => foto.path)
        .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              "Selecciona tu avatar:",
              style: TextStyle(color: AppColors.primary, fontWeight: .w700),
            ),
            backgroundColor: AppColors.secondary.withAlpha(200),
            content: SingleChildScrollView(
              child: SizedBox(
                width: .maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: fotosLista.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          u.fotoUrl = FotosPerfil.fromPath(fotosLista[index]);
                        });

                        _editUser(u);
                        if (mounted) Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                u.fotoUrl ==
                                    FotosPerfil.fromPath(fotosLista[index])
                                ? AppColors.accent
                                : Colors.transparent,
                            width: 10,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: AssetImage(fotosLista[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editUser(Usuario u) async {
    String nombre = u.nombre;
    String foto = u.fotoUrl;
    u.email = emailController.text;
    u.nombre = usernameController.text;

    try {
      await FirestoreService().updateUsuario(u);
    } catch (e) {
      // Si algo sale mal, revierte los cambios para no confundir
      u.nombre = nombre;
      u.fotoUrl = foto;
    }
  }
}
