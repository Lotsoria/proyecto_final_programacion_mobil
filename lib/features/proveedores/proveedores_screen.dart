import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Lista de proveedores usando `GET proveedores/` con acciones de editar y eliminar.
class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final json = await ApiClient.I.get('proveedores/');
    final List items = json['results'] ?? json['data'] ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<void> _delete(Map<String, dynamic> proveedor) async {
    final id = proveedor['id'];
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text('¿Eliminar "${proveedor['empresa']}"?'),
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
      await ApiClient.I.delete('proveedores/$id/');
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proveedor eliminado')));
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
      appBar: AppBar(title: const Text('Proveedores')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final data = (snap.data ?? []) as List<Map<String, dynamic>>;
          if (data.isEmpty) return const Center(child: Text('Sin proveedores'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = data[i];
              return ListTile(
                title: Text(p['empresa'] ?? ''),
                subtitle: Text('${p['contacto_principal'] ?? ''}\n${p['telefono'] ?? ''} • ${p['direccion'] ?? ''}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final updated = await Navigator.pushNamed(context, '/proveedores/editar', arguments: p);
                        if (updated == true && mounted) {
                          setState(() => _future = _load());
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proveedor actualizado')));
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.pushNamed(context, '/proveedores/nuevo');
          if (created == true && mounted) {
            setState(() => _future = _load());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proveedor creado')));
          }
        },
        icon: const Icon(Icons.add_business),
        label: const Text('Agregar'),
      ),
    );
  }
}
