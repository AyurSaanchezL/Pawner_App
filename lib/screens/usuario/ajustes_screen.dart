import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/components/chat_bubble_clipper.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/screens/first_screen.dart';
import 'package:pawner_app/screens/usuario/dashboard_screen.dart';
import 'package:pawner_app/screens/usuario/perfil_screen.dart';
import 'package:pawner_app/services/auth_service.dart';
import 'package:pawner_app/screens/familia/detalle_familia_screen.dart';
import 'package:pawner_app/services/notification_service.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  // ── DEBUG: muestra las notificaciones pendientes en el sistema ──────────────
  Future<void> _mostrarNotificacionesPendientes(BuildContext context) async {
    final pendientes = await NotificationService().getPendingNotifications();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(LucideIcons.bell, size: 18),
            SizedBox(width: 8),
            Text(
              'Notificaciones pendientes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: pendientes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Sin notificaciones pendientes.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: pendientes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = pendientes[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID ${n.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.title ?? '(sin título)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            n.body ?? '(sin cuerpo)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          Text(
            '${pendientes.length} pendiente${pendientes.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/background_01.png", fit: BoxFit.cover),

          SafeArea(
            bottom: false,
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

                const Spacer(flex: 1),

                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildBubble(
                          text: "Perfil",
                          color: AppColors.secondary,
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
                          color: AppColors.accent,
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
                                    builder: (context) => DetalleFamiliaScreen(
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
                          color: Colors.redAccent,
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
                        const SizedBox(height: 25),
                        // ── TEMPORAL — eliminar tras pruebas de notificaciones ──
                        _buildBubble(
                          text: "Debug Notifs",
                          color: const Color(0xFFFFC107),
                          icon: LucideIcons.bell,
                          isRightTail: false,
                          textColor: Colors.black87,
                          iconColor: Colors.black87,
                          onTap: () => _mostrarNotificacionesPendientes(context),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                _buildDarkPanel(),
              ],
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

  Widget _buildDarkPanel() {
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
          _buildSmallBubble("Ayuda", isRightTail: false),
          const SizedBox(height: 20),
          _buildSmallBubble("Sobre nosotros", isRightTail: true),
        ],
      ),
    );
  }

  Widget _buildSmallBubble(String text, {required bool isRightTail}) {
    return GestureDetector(
      onTap: () => log("Opción seleccionada: $text"),
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
