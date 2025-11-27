import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Compras: consume `GET compras/` y permite crear, editar (pendientes),
class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final json = await ApiClient.I.get('compras/');
    final List items = json['results'] ?? json['data'] ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<void> _eliminar(Map<String, dynamic> compra) async {
    if ((compra['estado'] ?? '').toString().toLowerCase() != 'pendiente') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solo puedes eliminar compras pendientes')));
      return;
    }
    final id = compra['id'];
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar compra'),
        content: Text('¿Eliminar orden "${compra['numero']}"?'),
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
      await ApiClient.I.delete('compras/$id/');
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compra eliminada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _recibir(Map<String, dynamic> compra) async {
    if ((compra['estado'] ?? '').toString().toLowerCase() != 'pendiente') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solo puedes marcar como recibida si está pendiente')));
      return;
    }
    final id = compra['id'];
    if (id == null) return;
    try {
      await ApiClient.I.post('compras/$id/recibir/');
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compra recibida')));
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
        title: const Text('Compras'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filtro,
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'recibida', child: Text('Recibida')),
                DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
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
            data = data.where((o) => (o['estado'] ?? '').toString().toLowerCase() == _filtro).toList();
          }
          if (data.isEmpty) return const Center(child: Text('Sin órdenes'));
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.separated(
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final o = data[i];
                final estado = (o['estado'] ?? '').toString().toLowerCase();
                return ExpansionTile(
                  title: Text('${o['numero'] ?? ''} • ${o['proveedor'] ?? ''}'),
                  subtitle: Text('${o['fecha'] ?? ''} • ${o['estado'] ?? ''} • Q${o['total'] ?? 0}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (option) {
                      if (option == 'editar') {
                        Navigator.pushNamed(context, '/compras/editar', arguments: o).then((updated) {
                          if (updated == true && mounted) setState(() => _future = _load());
                        });
                      } else if (option == 'recibir') {
                        _recibir(o);
                      } else if (option == 'eliminar') {
                        _eliminar(o);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: 'editar', enabled: estado == 'pendiente', child: const Text('Editar')),
                      PopupMenuItem(value: 'recibir', enabled: estado == 'pendiente', child: const Text('Recibir')),
                      PopupMenuItem(value: 'eliminar', enabled: estado == 'pendiente', child: const Text('Eliminar')),
                    ],
                  ),
                  children: [
                    ...((o['items'] as List?) ?? []).map(
                      (it) => ListTile(
                        dense: true,
                        title: Text('${it['producto']} x${it['cantidad']}'),
                        trailing: Text('Q${it['subtotal'] ?? it['costo_unitario']}'),
                        subtitle: Text('CU: Q${it['costo_unitario']}'),
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
          final created = await Navigator.pushNamed(context, '/compras/nueva');
          if (created == true && mounted) setState(() => _future = _load());
        },
        icon: const Icon(Icons.playlist_add),
        label: const Text('Nueva'),
      ),
    );
  }
}
