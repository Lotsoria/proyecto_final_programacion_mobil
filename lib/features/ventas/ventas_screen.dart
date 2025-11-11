import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Visualización de ventas con filtro por estado en memoria.
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

  /// Recupera ventas (`GET ventas/`) y devuelve lista tipada.
  Future<List<Map<String, dynamic>>> _load() async {
    final json = await ApiClient.I.get('ventas/');
    final List items = json['results'] ?? [];
    return items.cast<Map<String, dynamic>>();
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
                DropdownMenuItem(value: 'completada', child: Text('Completada')),
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
                .where((v) => (v['estado'] ?? '')
                    .toString()
                    .toLowerCase() ==
                    _filtro)
                .toList();
          }
          if (data.isEmpty) return const Center(child: Text('Sin ventas'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final v = data[i];
              return ExpansionTile(
                title: Text('${v['numero']} • ${v['cliente'] ?? ''}'),
                subtitle: Text(
                  '${v['fecha'] ?? ''} • ${v['estado'] ?? ''} • Q${v['total'] ?? 0}',
                ),
                children: [
                  ...((v['items'] as List?) ?? []).map(
                    (it) => ListTile(
                      dense: true,
                      title: Text('${it['producto']} x${it['cantidad']}'),
                      trailing: Text('Q${it['subtotal']}'),
                      subtitle: Text('PU: Q${it['precio_unitario']}'),
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

