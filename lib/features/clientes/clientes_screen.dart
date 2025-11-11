import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Lista de clientes activos provenientes del endpoint `GET clientes/`.
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

  /// Carga y normaliza la respuesta `{ results: [...] }` en una lista tipada.
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
          final data = (snap.data ?? []) as List<Map<String, dynamic>>;
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
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () async {
                    final updated = await Navigator.pushNamed(
                      context,
                      '/clientes/editar',
                      arguments: c,
                    );
                    if (updated == true && mounted) {
                      setState(() => _future = _load());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cliente actualizado')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navega al formulario de nuevo cliente y espera resultado.
          final created = await Navigator.pushNamed(context, '/clientes/nuevo');
          if (created == true && mounted) {
            // Si se creó, recarga la lista.
            setState(() => _future = _load());
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
}
