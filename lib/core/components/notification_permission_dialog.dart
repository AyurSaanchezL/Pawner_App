import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/services/notification_service.dart';

class NotificationPermissionDialog {
  /// Comprueba el permiso y muestra el diálogo solo si no está concedido.
  /// [feature] describe la funcionalidad bloqueada, p.ej. "las citas veterinarias".
  static Future<void> checkAndShow(
    BuildContext context, {
    required String feature,
  }) async {
    final granted = await NotificationService().hasNotificationPermission();
    if (!granted && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _NotificationPermissionDialogWidget(
          feature: feature,
          dialogContext: dialogContext,
        ),
      );
    }
  }
}

class _NotificationPermissionDialogWidget extends StatelessWidget {
  final String feature;
  final BuildContext dialogContext;

  const _NotificationPermissionDialogWidget({
    required this.feature,
    required this.dialogContext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Cabecera ilustrada ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: const BoxDecoration(
              color: AppColors.lightSecondary,
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(180),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(LucideIcons.bellOff, size: 40, color: AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '¡Uy, las notificaciones\nestán desactivadas! 🐾',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          // --- Cuerpo ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              'Sin permiso de notificaciones no podremos avisarte de $feature.\n\n¡Tus mascotas necesitan que estés al tanto! 🐶🐱',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),

          // --- Botones ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      AppSettings.openAppSettings(type: AppSettingsType.notification);
                    },
                    icon: const Icon(LucideIcons.settings, size: 18, color: Colors.white),
                    label: const Text(
                      'Activar notificaciones',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Ahora no',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
