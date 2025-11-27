import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Carga y normaliza la respuesta
  Future<List<Map<String, dynamic>>> _load() async {
    final json = await ApiClient.I.get('clientes/');
    final List items = json['results'] ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes activos')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = 
              (snap.data ?? []) as List<Map<String, dynamic>>;

          if (data.isEmpty) return const Center(child: Text('Sin clientes'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = data[i];
              return ListTile(
                title: Text(c['nombre_completo'] ?? ''),
                subtitle: Text(
                  '${c['direccion'] ?? ''}\n${c['telefono'] ?? ''} • ${c['email'] ?? ''}',

                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () async {
                        final updated = await Navigator.pushNamed(
                          context,
                          '/clientes/editar',
                          arguments: c,
                        );
                        if (updated == true && mounted) {
                          setState(() {
                            _future = _load();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cliente actualizado')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.redAccent,
                      tooltip: 'Eliminar',
                      onPressed: () => _confirmDelete(context, c),
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
          final created = await Navigator.pushNamed(context, '/clientes/nuevo');
          if (created == true && mounted) {
            setState(() {
              _future = _load();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cliente creado')),
            );
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar'),
      ),
    );
  }

  /// Muestra confirmación y elimina el cliente si se acepta.
  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> cliente) async {
    final id = cliente['id'];
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Seguro que deseas eliminar a "${cliente['nombre_completo']}"?'),
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
      await ApiClient.I.delete('clientes/$id/');
      if (!mounted) return;
      setState(() {
        _future = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }


}
