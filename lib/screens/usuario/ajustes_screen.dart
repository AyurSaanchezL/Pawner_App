import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/components/chat_bubble_clipper.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/screens/first_screen.dart';
import 'package:pawner_app/screens/usuario/dashboard_screen.dart';
import 'package:pawner_app/screens/usuario/perfil_screen.dart';
import 'package:pawner_app/services/auth_service.dart';
import 'package:pawner_app/screens/familia/detalle_familia_screen.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/background_01.png", fit: BoxFit.cover),

          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(
                                LucideIcons.arrowLeft,
                                color: Colors.black,
                                size: 28,
                              ),
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DashboardScreen(),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _buildBubble(
                                  text: "Perfil",
                                  color: AppColors.secondary.withAlpha(245),
                                  icon: LucideIcons.user,
                                  isRightTail: true,
                                  iconColor: AppColors.secondary,
                                  onTap: () async {
                                    Usuario usuario = await authService.value
                                        .getCurrentUser();
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PerfilUsuarioScreen(u: usuario),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 25),
                                _buildBubble(
                                  text: "Familia",
                                  color: AppColors.accent.withAlpha(245),
                                  icon: LucideIcons.users,
                                  isRightTail: false,
                                  iconColor: Colors.orange,
                                  onTap: () async {
                                    Usuario usuario = await authService.value
                                        .getCurrentUser();
                                    if (context.mounted) {
                                      if (usuario.familiaID != null &&
                                          usuario.familiaID!.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetalleFamiliaScreen(
                                                  familiaID: usuario.familiaID!,
                                                ),
                                          ),
                                        );
                                      } else {
                                        log("El usuario no tiene familia");
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(height: 25),
                                _buildBubble(
                                  text: "Cerrar sesión",
                                  color: Colors.redAccent.withAlpha(245),
                                  icon: Icons.exit_to_app,
                                  isRightTail: true,
                                  iconColor: Colors.redAccent,
                                  onTap: () async {
                                    AuthService().signOut();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FirstScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),
                          const SizedBox(height: 40),

                          _buildDarkPanel(context),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble({
    required String text,
    required Color color,
    required IconData icon,
    required bool isRightTail,
    Color textColor = Colors.black,
    Color iconCircleColor = Colors.white,
    Color iconColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        log("Opción seleccionada: $text");
        if (onTap != null) onTap();
      },
      child: ClipPath(
        clipper: SimpleChatBubbleClipper(isRight: isRightTail),
        child: Container(
          width: double.infinity,
          height: 90,
          padding: const EdgeInsets.fromLTRB(25, 10, 25, 20),
          color: color,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconCircleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 40, left: 40, right: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildSmallBubble(
            "Ayuda",
            isRightTail: false,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _ContactFormSheet(),
            ),
          ),
          const SizedBox(height: 20),
          _buildSmallBubble(
            "Sobre nosotros",
            isRightTail: true,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _SobreNosotrosSheet(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBubble(
    String text, {
    required bool isRightTail,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => log("Opción seleccionada: $text"),
      child: ClipPath(
        clipper: SimpleChatBubbleClipper(isRight: isRightTail),
        child: Container(
          width: 250,
          height: 70,
          color: AppColors.lightSecondary,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── FORMULARIO DE CONTACTO ───────────────────────────────────────────────────

class _ContactFormSheet extends StatefulWidget {
  const _ContactFormSheet();

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  final _asuntoController = TextEditingController();
  final _mensajeController = TextEditingController();
  bool _sending = false;

  static const _supportEmail = 'marianagomezdam@gmail.com';

  @override
  void dispose() {
    _asuntoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final asunto = _asuntoController.text.trim();
    final mensaje = _mensajeController.text.trim();

    if (asunto.isEmpty || mensaje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _sending = true);

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query:
          'subject=${Uri.encodeQueryComponent(asunto)}'
          '&body=${Uri.encodeQueryComponent(mensaje)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el cliente de correo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(
                  LucideIcons.messageCircle,
                  color: AppColors.secondary,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  '¿Cómo podemos ayudarte?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Te responderemos lo antes posible.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _asuntoController,
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: AppColors.dark,
              ),
              decoration: _inputDecoration('Asunto', LucideIcons.tag),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _mensajeController,
              maxLines: 4,
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: AppColors.dark,
              ),
              decoration: _inputDecoration('Cuéntanos...', LucideIcons.pencil),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _sending ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Enviar',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Nunito', color: Colors.black38),
      prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightSecondary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
    );
  }
}

// ─── SOBRE NOSOTROS ───────────────────────────────────────────────────────────

class _SobreNosotrosSheet extends StatelessWidget {
  const _SobreNosotrosSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 42,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pawner',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Una carta de amor a las familias con mascotas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Somos tres estudiantes de Desarrollo de Aplicaciones '
            'Multiplataforma con una pasión en común: los animales '
            'y las personas que los quieren.\n\n'
            'Pawner nació para que cuidar juntos sea más fácil — '
            'recordatorios de alimentación, seguimiento veterinario, '
            'paseos coordinados, todo en un mismo lugar para toda la familia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: Colors.white70,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _buildTeamCard('Mariana', '🧸', AppColors.lightSecondary),
              const SizedBox(width: 10),
              _buildTeamCard('Guille', '🚀', AppColors.lightSecondary),
              const SizedBox(width: 10),
              _buildTeamCard('Ayur', '✨', AppColors.lightSecondary),
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                color: Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String name, String emoji, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(35),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withAlpha(80), width: 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
