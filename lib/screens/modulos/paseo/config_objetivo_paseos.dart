import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/modulo_paseos/modulo_paseo_config.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/services/notification_service.dart';

class ConfigObjetivoPaseos extends StatefulWidget {
  final String familiaID;
  final String mascotaID;

  const ConfigObjetivoPaseos({
    super.key,
    required this.familiaID,
    required this.mascotaID,
  });

  @override
  State<ConfigObjetivoPaseos> createState() => _ConfigObjetivoPaseosState();
}

class _ConfigObjetivoPaseosState extends State<ConfigObjetivoPaseos> {
  int numPaseosObjetivo = 1;
  int intervaloHoras = 4;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await FirestoreService()
          .getPaseoConfig(widget.familiaID, widget.mascotaID)
          .first;
      if (config != null) {
        setState(() {
          numPaseosObjetivo = config.numPaseosObjetivo;
          intervaloHoras = config.intervaloRecordatoriosHoras;
        });
      }
    } catch (e) {
      // Usar valores por defecto
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarConfig() async {
    setState(() => _isSaving = true);
    try {
      final config = PaseoConfig(
        numPaseosObjetivo,
        intervaloRecordatoriosHoras: intervaloHoras,
      );
      await FirestoreService().saveModulePaseosConfig(
        widget.familiaID,
        widget.mascotaID,
        config,
      );

      // Programar recordatorios
      await _programarRecordatorios();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Objetivo configurado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _programarRecordatorios() async {
    final count = await FirestoreService().countPaseosToday(
      widget.familiaID,
      widget.mascotaID,
    );
    if (count < numPaseosObjetivo) {
      await NotificationService().schedulePaseoReminders(
        objetivo: numPaseosObjetivo,
        completadosHoy: count,
        intervaloHoras: intervaloHoras,
      );
    } else {
      await NotificationService().cancelPaseoReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Objetivo de Paseos Diarios",
                textAlign: .center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Número de paseos objetivo por día:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NumberPicker(
                  minValue: 1,
                  maxValue: 10,
                  value: numPaseosObjetivo,
                  onChanged: (val) => setState(() => numPaseosObjetivo = val),
                  infiniteLoop: true,
                  itemWidth: 60,
                  itemHeight: 40,
                  selectedTextStyle: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Recordarme cada (horas):",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NumberPicker(
                  minValue: 1,
                  maxValue: 12,
                  value: intervaloHoras,
                  onChanged: (val) => setState(() => intervaloHoras = val),
                  infiniteLoop: true,
                  itemWidth: 60,
                  itemHeight: 40,
                  selectedTextStyle: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardarConfig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(
                        'GUARDAR CONFIGURACIÓN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
