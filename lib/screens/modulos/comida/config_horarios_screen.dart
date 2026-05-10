import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/modulo_comida/horario_model.dart';
import 'package:pawner_app/services/comida_service.dart';

class ConfigHorariosScreen extends StatelessWidget {
  final String familiaId;
  final String mascotaId;

  const ConfigHorariosScreen({
    super.key,
    required this.familiaId,
    required this.mascotaId,
  });

  Future<void> _addHorarioManual(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final String horaStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      
      final nuevoHorario = HorarioComida(
        id: '',
        hora: horaStr,
        idNotificacion: DateTime.now().millisecondsSinceEpoch.remainder(100000), // Generación simple para prueba
        activo: true,
      );

      await ComidaService().addHorario(familiaId, mascotaId, nuevoHorario);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Horarios de Comida'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
      ),
      body: StreamBuilder<List<HorarioComida>>(
        stream: ComidaService().getHorarios(familiaId, mascotaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar horarios."));
          }

          final horarios = snapshot.data ?? [];

          if (horarios.isEmpty) {
            return const Center(child: Text("No hay horarios configurados."));
          }

          return ListView.builder(
            itemCount: horarios.length,
            itemBuilder: (context, index) {
              final horario = horarios[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.access_time, color: AppColors.secondary),
                  title: Text(
                    horario.hora,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  trailing: Switch(
                    value: horario.activo,
                    activeColor: AppColors.secondary,
                    onChanged: (val) {
                      ComidaService().toggleHorario(familiaId, mascotaId, horario);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addHorarioManual(context),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add, color: AppColors.primary),
        label: const Text('Añadir Horario', style: TextStyle(color: AppColors.primary)),
      ),
    );
  }
}
