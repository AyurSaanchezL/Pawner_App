import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/components/chat_bubble_clipper.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/screens/usuario/perfil_screen.dart';
import 'package:pawner_app/services/auth_service.dart';
import 'package:pawner_app/screens/familia/detalle_familia_screen.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  //TODO cambiar estos colores de lugar para usar la logica de AppColors
  final Color _backgroundColor = const Color(0xFFFFFDF0);
  final Color _orangeBubble = const Color(0xFFFFCC80);
  final Color _blueBubble = const Color(0xFF3F51B5);
  final Color _lavenderBubble = const Color(0xFFC5B4E3);
  final Color _darkPanel = const Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Fondo decorativo con huellas
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: PawPainter(),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Barra Superior
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.black, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBubble(
                          text: "Familia",
                          color: _orangeBubble,
                          icon: LucideIcons.users,
                          isRightTail: true,
                          iconColor: Colors.orange,
                          onTap: () async {
                            Usuario usuario = await authService.value.getCurrentUser();
                            if (context.mounted) {
                              if (usuario.familiaID != null && usuario.familiaID!.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleFamiliaScreen(familiaID: usuario.familiaID!),
                                  ),
                                );
                              } else {
                                // Si por algún motivo llegara aquí sin familia
                                log("El usuario no tiene familia");
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 25),
                        _buildBubble(
                          text: "Permisos",
                          color: _blueBubble,
                          icon: LucideIcons.shieldCheck,
                          isRightTail: false,
                          textColor: Colors.white,
                          iconCircleColor: Colors.transparent,
                          iconColor: Colors.white,
                        ),
                        const SizedBox(height: 25),
                        _buildBubble(
                          text: "Perfil",
                          color: _orangeBubble,
                          icon: LucideIcons.user,
                          isRightTail: true,
                          iconColor: Colors.blue,
                          onTap: () async {
                            Usuario usuario = await authService.value.getCurrentUser();
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PerfilUsuarioScreen(u: usuario),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Panel Inferior
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
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
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
                  fontFamily: 'Nunito',
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
        color: _darkPanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 40, left: 40, right: 40),
      child: Column(
        children: [
          // Tres puntos blancos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            )),
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
          color: _lavenderBubble,
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

class PawPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Simulación de huellas aleatorias
    _drawPaw(canvas, Offset(size.width * 0.1, size.height * 0.2), 15, const Color(0xFFC5B4E3));
    _drawPaw(canvas, Offset(size.width * 0.8, size.height * 0.15), 20, const Color(0xFF333333));
    _drawPaw(canvas, Offset(size.width * 0.4, size.height * 0.45), 18, const Color(0xFFC5B4E3));
    _drawPaw(canvas, Offset(size.width * 0.85, size.height * 0.55), 22, const Color(0xFF333333));
    _drawPaw(canvas, Offset(size.width * 0.2, size.height * 0.7), 16, const Color(0xFFC5B4E3));
  }

  void _drawPaw(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    
    // Almohadilla central
    canvas.drawOval(Rect.fromCenter(center: center, width: size, height: size * 0.8), paint);
    
    // Dedos
    canvas.drawCircle(Offset(center.dx - size * 0.4, center.dy - size * 0.45), size * 0.25, paint);
    canvas.drawCircle(Offset(center.dx - size * 0.1, center.dy - size * 0.6), size * 0.25, paint);
    canvas.drawCircle(Offset(center.dx + size * 0.2, center.dy - size * 0.55), size * 0.25, paint);
    canvas.drawCircle(Offset(center.dx + size * 0.45, center.dy - size * 0.35), size * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
