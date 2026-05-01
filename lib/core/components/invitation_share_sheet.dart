import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pawner_app/core/app_colors.dart';

class InvitationShareSheet extends StatefulWidget {
  final String codigoInvitacion;

  const InvitationShareSheet({super.key, required this.codigoInvitacion});

  @override
  State<InvitationShareSheet> createState() => _InvitationShareSheetState();
}

class _InvitationShareSheetState extends State<InvitationShareSheet> {
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.codigoInvitacion));
    setState(() {
      _copied = true;
    });
    
    // Feedback visual breve
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado al portapapeles'),
        backgroundColor: AppColors.secondary,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareCode() {
    final String message = 
        '¡Únete a mi familia en Pawner! Usa este código para ver a nuestras mascotas: ${widget.codigoInvitacion}';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tirador decorativo
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          
          const Text(
            'Invitar a la familia',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Comparte este código con tus seres queridos para que puedan ver a tus mascotas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 30),
          
          // Campo de Código
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.lightSecondary),
                  ),
                  child: Text(
                    widget.codigoInvitacion,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _copyToClipboard,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _copied ? Colors.green : AppColors.secondary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _copied ? Icons.check : LucideIcons.copy,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Botón de compartir general
          ElevatedButton.icon(
            onPressed: _shareCode,
            icon: const Icon(LucideIcons.share2),
            label: const Text(
              'COMPARTIR CÓDIGO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.dark,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
