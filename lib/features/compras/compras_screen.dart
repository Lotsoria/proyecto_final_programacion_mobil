import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Visualización de órdenes de compra con filtro por estado en memoria.
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

  /// Recupera compras (`GET compras/`) y devuelve lista tipada.
  Future<List<Map<String, dynamic>>> _load() async {
    final json = await ApiClient.I.get('compras/');
    final List items = json['results'] ?? [];
    return items.cast<Map<String, dynamic>>();
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
          List<Map<String, dynamic>> data =
              (snap.data ?? []) as List<Map<String, dynamic>>;
          if (_filtro != 'Todos') {
            data = data
                .where((o) => (o['estado'] ?? '')
                    .toString()
                    .toLowerCase() ==
                    _filtro)
                .toList();
          }
          if (data.isEmpty) return const Center(child: Text('Sin órdenes'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final o = data[i];
              return ExpansionTile(
                title: Text('${o['numero']} • ${o['proveedor'] ?? ''}'),
                subtitle: Text(
                  '${o['fecha'] ?? ''} • ${o['estado'] ?? ''} • Q${o['total'] ?? 0}',
                ),
                children: [
                  ...((o['items'] as List?) ?? []).map(
                    (it) => ListTile(
                      dense: true,
                      title: Text('${it['producto']} x${it['cantidad']}'),
                      trailing: Text('Q${it['subtotal']}'),
                      subtitle: Text('CU: Q${it['costo_unitario']}'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

