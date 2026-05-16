import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_comida/plato_model.dart';
import 'package:pawner_app/screens/modulos/comida/add_plato_screen.dart';
import 'package:pawner_app/screens/modulos/comida/detalle_plato_sheet.dart';
import 'package:pawner_app/screens/modulos/comida/horarios_screen.dart';
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
  final Set<String> _filtros = {};

  static const List<String> _categorias = ['Seca', 'Húmeda', 'Natural', 'Suplemento'];

  Color _colorParaTipo(String tipo) {
    switch (tipo) {
      case 'Seca':       return Colors.amber.shade600;
      case 'Húmeda':     return Colors.blue.shade400;
      case 'Natural':    return Colors.green.shade500;
      case 'Suplemento': return AppColors.secondary;
      default:           return Colors.grey;
    }
  }

  IconData _iconParaTipo(String tipo) {
    switch (tipo) {
      case 'Seca':       return LucideIcons.box;
      case 'Húmeda':     return LucideIcons.droplets;
      case 'Natural':    return LucideIcons.leaf;
      case 'Suplemento': return LucideIcons.pill;
      default:           return LucideIcons.utensils;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeScreenBackground,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildFiltrosRow()),
          SliverToBoxAdapter(child: _buildSeccionHeader()),
          _buildCatalogo(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: Colors.black, size: 30),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.lightSecondary.withAlpha(70),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.utensils, size: 16, color: AppColors.secondary),
          ),
          const SizedBox(width: 10),
          Text(
            'Alimentación · ${widget.mascota.nombre}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HorariosScreen(mascota: widget.mascota),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightSecondary.withAlpha(70),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.clock, size: 18, color: AppColors.secondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltrosRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categorias.map((cat) {
            final isSelected = _filtros.contains(cat);
            final color = _colorParaTipo(cat);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _filtros.remove(cat);
                  } else {
                    _filtros.add(cat);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withAlpha(30) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconParaTipo(cat),
                        size: 13,
                        color: isSelected ? color : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? color : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSeccionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Menú de platos',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: AppColors.secondary, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddPlatoScreen(
                  familiaId: widget.mascota.familiaID,
                  mascotaId: widget.mascota.mascotaID,
                ),
              ),
            ),
            tooltip: 'Añadir plato',
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogo() {
    return StreamBuilder<List<Plato>>(
      stream: _comidaService.getPlatos(
        widget.mascota.familiaID,
        widget.mascota.mascotaID,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final platos = snapshot.data ?? [];
        final platosFiltrados = _filtros.isEmpty
            ? platos
            : platos.where((p) => _filtros.contains(p.tipo)).toList();

        if (platosFiltrados.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState(platos.isEmpty));
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPlatoCard(platosFiltrados[index]),
              childCount: platosFiltrados.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool noHayPlatos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            noHayPlatos ? LucideIcons.utensils : LucideIcons.filter,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            noHayPlatos
                ? 'Aún no hay platos en el menú'
                : 'Sin platos para estos filtros',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              color: Colors.grey.shade400,
            ),
          ),
          if (noHayPlatos) ...[
            const SizedBox(height: 6),
            Text(
              'Toca + para añadir el primero',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _abrirDetalle(BuildContext context, Plato plato) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetallePlatoSheet(
        plato: plato,
        familiaId: widget.mascota.familiaID,
        mascotaId: widget.mascota.mascotaID,
      ),
    );
  }

  Widget _buildPlatoCard(Plato plato) {
    final color = _colorParaTipo(plato.tipo);
    final hasImage = plato.fotoUrl != null && plato.fotoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _abrirDetalle(context, plato),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: hasImage
                  ? Image.network(
                      plato.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, _) => _buildColorHeader(color),
                    )
                  : _buildColorHeader(color),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plato.nombre,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plato.tipo,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      if (plato.ingredientes.isNotEmpty) ...[
                        const Spacer(),
                        Text(
                          '${plato.ingredientes.length} ing.',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildColorHeader(Color color) {
    return Container(
      color: color.withAlpha(30),
      child: Center(
        child: Icon(
          LucideIcons.chefHat,
          size: 36,
          color: color.withAlpha(180),
        ),
      ),
    );
  }
}
