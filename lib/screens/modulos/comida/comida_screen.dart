import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_comida/modulo_comida_config.dart';
import 'package:pawner_app/core/model/modulo_comida/plato_model.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/screens/modulos/comida/nuevo_plato_screen.dart';
import 'package:pawner_app/screens/modulos/comida/horarios_screen.dart';

class ComidaScreen extends StatefulWidget {
  final Mascota mascota;

  const ComidaScreen({super.key, required this.mascota});

  @override
  State<ComidaScreen> createState() => _ComidaScreenState();
}

class _ComidaScreenState extends State<ComidaScreen> {
  final FirestoreService _fs = FirestoreService();
  List<String> _categoriasActivas = ['Seca', 'Húmeda', 'Natural'];
  final List<String> _todasLasCategorias = ['Seca', 'Húmeda', 'Natural', 'Suplemento'];
  String _filtroCategoria = 'Todas';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _fs.getModuloComidaConfig(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
    );
    if (config != null && mounted) {
      setState(() {
        _categoriasActivas = config.categoriasActivas;
      });
    }
  }

  List<Plato> _filtrarPlatos(List<Plato> platos) {
    if (_filtroCategoria == 'Todas') return platos;
    return platos.where((p) => p.tipo == _filtroCategoria).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeScreenBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Alimentación de ${widget.mascota.nombre}",
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.clock, color: AppColors.secondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HorariosScreen(mascota: widget.mascota),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 20),
                  _buildCategoriaFilterChips(),
                  const SizedBox(height: 20),
                  _buildSugerenciasSection(),
                  const SizedBox(height: 20),
                  const Text(
                    "Platos registrados",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: StreamBuilder<List<Plato>>(
              stream: _fs.streamPlatos(
                widget.mascota.familiaID,
                widget.mascota.mascotaID,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final platos = _filtrarPlatos(snapshot.data!);
                if (platos.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          "No hay platos registrados aún.",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPlatoCard(platos[index]),
                    childCount: platos.length,
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final nombre = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => NuevoPlatoScreen(mascota: widget.mascota),
            ),
          );
          if (nombre != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¡$nombre añadido!',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        backgroundColor: AppColors.complementary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          "Añadir plato",
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightSecondary.withAlpha(77),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.utensils, color: AppColors.secondary, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.mascota.especie} · ${widget.mascota.raza}",
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "${widget.mascota.peso.toStringAsFixed(1)} kg",
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaFilterChips() {
    final categorias = ['Todas', ..._todasLasCategorias];
    return Wrap(
      spacing: 10,
      children: categorias.map((cat) {
        final isSelected = _filtroCategoria == cat;
        return FilterChip(
          label: Text(
            cat,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.secondary,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => setState(() => _filtroCategoria = cat),
          selectedColor: AppColors.secondary,
          backgroundColor: AppColors.lightSecondary.withAlpha(51),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildSugerenciasSection() {
    final sugerencias = [
      Plato(
        id: 'sug_1',
        nombre: 'Dieta Balanceada',
        tipo: 'Seca',
        ingredientes: ['Pollo', 'Arroz', 'Verduras'],
        esSugerencia: true,
      ),
      Plato(
        id: 'sug_2',
        nombre: 'Comida Húmeda Natural',
        tipo: 'Húmeda',
        ingredientes: ['Salmón', 'Patata', 'Zanahoria'],
        esSugerencia: true,
      ),
      Plato(
        id: 'sug_3',
        nombre: 'Snack Saludable',
        tipo: 'Natural',
        ingredientes: ['Manzana', 'Plátano', 'Avena'],
        esSugerencia: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sugerencias",
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sugerencias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildSugerenciaCard(sugerencias[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSugerenciaCard(Plato plato) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.homeScreenOrange.withAlpha(77),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.utensils, size: 18, color: AppColors.complementary),
          ),
          const SizedBox(height: 10),
          Text(
            plato.nombre,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            plato.ingredientes.take(2).join(', '),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlatoCard(Plato plato) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.lightSecondary.withAlpha(51),
                borderRadius: BorderRadius.circular(15),
                image: plato.fotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(plato.fotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: plato.fotoUrl == null
                  ? const Icon(LucideIcons.utensils, color: AppColors.secondary)
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plato.nombre,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    plato.tipo,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (plato.ingredientes.isNotEmpty)
                    Text(
                      plato.ingredientes.join(', '),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
              onPressed: () async {
                await _fs.deletePlato(
                  widget.mascota.familiaID,
                  widget.mascota.mascotaID,
                  plato.id,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
