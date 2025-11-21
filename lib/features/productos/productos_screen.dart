import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Gestión de productos usando `GET/POST/DELETE productos/`.
/// Para crear/editar se navega a `/productos/nuevo` o `/productos/editar`.
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final json = await ApiClient.I.get('productos/');
    final List items = json['results'] ?? json['data'] ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final id = p['id'];
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p['nombre']}"?'),
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
      await ApiClient.I.delete('productos/$id/');
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
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
      appBar: AppBar(title: const Text('Productos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o código',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                List<Map<String, dynamic>> data = (snap.data ?? []) as List<Map<String, dynamic>>;
                if (_query.isNotEmpty) {
                  data = data
                      .where((p) =>
                          (p['nombre'] ?? '').toString().toLowerCase().contains(_query) ||
                          (p['codigo'] ?? '').toString().toLowerCase().contains(_query))
                      .toList();
                }
                if (data.isEmpty) return const Center(child: Text('Sin productos'));
                return RefreshIndicator(
                  onRefresh: () async => setState(() => _future = _load()),
                  child: ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = data[i];
                      return ListTile(
                        title: Text('${p['codigo'] ?? ''} • ${p['nombre'] ?? ''}'),
                        subtitle: Text('Compra: Q${p['precio_compra']} • Venta: Q${p['precio_venta']}'),
                        leading: Chip(label: Text(p['activo'] == false ? 'Inactivo' : 'Activo')),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Stock: ${p['stock'] ?? 0}'),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final updated = await Navigator.pushNamed(context, '/productos/editar', arguments: p);
                                    if (updated == true && mounted) {
                                      setState(() => _future = _load());
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.redAccent,
                                  onPressed: () => _delete(p),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.pushNamed(context, '/productos/nuevo');
          if (created == true && mounted) {
            setState(() => _future = _load());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto creado')));
          }
        },
        icon: const Icon(Icons.add_box),
        label: const Text('Agregar'),
      ),
    );
  }
}
