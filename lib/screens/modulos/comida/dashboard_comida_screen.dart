import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_comida/modulo_comida_config.dart';
import 'package:pawner_app/core/model/modulo_comida/plato_model.dart';
import 'package:pawner_app/screens/modulos/comida/add_plato_screen.dart';
import 'package:pawner_app/screens/modulos/comida/config_horarios_screen.dart';
import 'package:pawner_app/services/comida_service.dart';

class DashboardComidaScreen extends StatefulWidget {
  final Mascota mascota;

  const DashboardComidaScreen({
    super.key,
    required this.mascota,
  });

  @override
  State<DashboardComidaScreen> createState() => _DashboardComidaScreenState();
}

class _DashboardComidaScreenState extends State<DashboardComidaScreen> {
  final ComidaService _comidaService = ComidaService();
  ModuloComidaConfig? _config;
  
  // Categorias base disponibles
  final List<String> _todasLasCategorias = ['Seca', 'Húmeda', 'Natural', 'Suplemento'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Comida - ${widget.mascota.nombre}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigHorariosScreen(
                    familiaId: widget.mascota.familiaID,
                    mascotaId: widget.mascota.mascotaID,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<ModuloComidaConfig>(
        stream: _comidaService.getConfig(widget.mascota.familiaID, widget.mascota.mascotaID),
        builder: (context, configSnapshot) {
          if (configSnapshot.hasData) {
            _config = configSnapshot.data;
          }

          return CustomScrollView(
            slivers: [
              // 1. Cabecera (Chips informativos)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(Icons.pets, widget.mascota.especie),
                      _buildInfoChip(Icons.category, widget.mascota.raza),
                      _buildInfoChip(Icons.monitor_weight, '${widget.mascota.peso} kg'),
                    ],
                  ),
                ),
              ),

              // 2. Barra de Categorías (FilterChips)
              SliverToBoxAdapter(
                child: _config == null
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _todasLasCategorias.map((cat) {
                              final isSelected = _config!.categoriasActivas.contains(cat);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  selectedColor: AppColors.secondary.withOpacity(0.3),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _config!.categoriasActivas.add(cat);
                                      } else {
                                        _config!.categoriasActivas.remove(cat);
                                      }
                                      _comidaService.saveConfig(
                                        widget.mascota.familiaID,
                                        widget.mascota.mascotaID,
                                        _config!,
                                      );
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: 20)),

              // 3. Catálogo de Platos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Catálogo de Platos',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.secondary, size: 30),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPlatoScreen(
                                familiaId: widget.mascota.familiaID,
                                mascotaId: widget.mascota.mascotaID,
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),

              StreamBuilder<List<Plato>>(
                stream: _comidaService.getPlatos(widget.mascota.familiaID, widget.mascota.mascotaID),
                builder: (context, platosSnapshot) {
                  if (platosSnapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  }

                  final platos = platosSnapshot.data ?? [];
                  
                  // Filtrar según categorias activas
                  final platosFiltrados = platos.where((p) {
                    return _config?.categoriasActivas.contains(p.tipo) ?? true;
                  }).toList();

                  if (platosFiltrados.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text("No hay platos disponibles para estas categorías.")),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildPlatoCard(platosFiltrados[index]);
                        },
                        childCount: platosFiltrados.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, color: AppColors.primary, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.secondary.withOpacity(0.2),
    );
  }

  Widget _buildPlatoCard(Plato plato) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: plato.fotoUrl != null && plato.fotoUrl!.isNotEmpty
                  ? Image.network(
                      plato.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                    )
                  : const Icon(Icons.fastfood, size: 50, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    plato.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plato.tipo,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
