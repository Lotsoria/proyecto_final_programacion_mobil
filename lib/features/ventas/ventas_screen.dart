import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Ventas: consume `GET ventas/` y permite crear, editar (pendientes),
/// borrar (pendiente) y completar (`POST ventas/{id}/completar/`).
class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final json = await ApiClient.I.get('ventas/');
    final List items = json['results'] ?? json['data'] ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<void> _eliminar(Map<String, dynamic> venta) async {
    if ((venta['estado'] ?? '').toString().toLowerCase() != 'pendiente') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solo puedes eliminar ventas pendientes')));
      return;
    }
    final id = venta['id'];
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text('¿Eliminar venta "${venta['numero']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.I.delete('ventas/$id/');
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta eliminada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _completar(Map<String, dynamic> venta) async {
    if ((venta['estado'] ?? '').toString().toLowerCase() != 'pendiente') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solo puedes completar ventas pendientes')));
      return;
    }
    final id = venta['id'];
    if (id == null) return;
    try {
      await ApiClient.I.post('ventas/$id/completar/');
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta completada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filtro,
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'completado', child: Text('Completado')),
                DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
              ],
              onChanged: (v) => setState(() => _filtro = v ?? 'Todos'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          List<Map<String, dynamic>> data = (snap.data ?? []) as List<Map<String, dynamic>>;
          if (_filtro != 'Todos') {
            data = data.where((v) => (v['estado'] ?? '').toString().toLowerCase() == _filtro).toList();
          }
          if (data.isEmpty) return const Center(child: Text('Sin ventas'));
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.separated(
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final v = data[i];
                final estado = (v['estado'] ?? '').toString().toLowerCase();
                return ExpansionTile(
                  title: Text('${v['numero'] ?? ''} • ${v['cliente'] ?? ''}'),
                  subtitle: Text('${v['fecha'] ?? ''} • ${v['estado'] ?? ''} • Q${v['total'] ?? 0}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (option) {
                      if (option == 'editar') {
                        Navigator.pushNamed(context, '/ventas/editar', arguments: v).then((updated) {
                          if (updated == true && mounted) setState(() => _future = _load());
                        });
                      } else if (option == 'completar') {
                        _completar(v);
                      } else if (option == 'eliminar') {
                        _eliminar(v);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: 'editar', enabled: estado == 'pendiente', child: const Text('Editar')),
                      PopupMenuItem(value: 'completar', enabled: estado == 'pendiente', child: const Text('Completar')),
                      PopupMenuItem(value: 'eliminar', enabled: estado == 'pendiente', child: const Text('Eliminar')),
                    ],
                  ),
                  children: [
                    ...((v['items'] as List?) ?? []).map(
                      (it) => ListTile(
                        dense: true,
                        title: Text('${it['producto']} x${it['cantidad']}'),
                        trailing: Text('Q${it['subtotal'] ?? it['precio_unitario']}'),
                        subtitle: Text('PU: Q${it['precio_unitario']}'),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.pushNamed(context, '/ventas/nueva');
          if (created == true && mounted) setState(() => _future = _load());
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nueva'),
      ),
    );
  }
}
