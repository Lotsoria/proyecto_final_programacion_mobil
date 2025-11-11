import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Visualización de productos con filtros opcionales `categoria` y `min` (stock ≤).
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  int? _categoria;
  int? _min;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Llama a `GET inventario/` con query params según los filtros activos.
  Future<List<Map<String, dynamic>>> _load() async {
    final query = <String, dynamic>{};
    if (_categoria != null) query['categoria'] = _categoria;
    if (_min != null) query['min'] = _min;
    final json = await ApiClient.I.get('inventario/', query: query);
    final List items = json['results'] ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  /// Dispara recarga con filtros actuales.
  void _aplicarFiltros() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario - Productos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Categoría (id)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _categoria = int.tryParse(v.isEmpty ? 'NaN' : v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Stock ≤',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _min = int.tryParse(v.isEmpty ? 'NaN' : v),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _aplicarFiltros, child: const Text('Filtrar')),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final data = (snap.data ?? []) as List<Map<String, dynamic>>;
                if (data.isEmpty) return const Center(child: Text('Sin productos'));
                return ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = data[i];
                    return ListTile(
                      title: Text('${p['codigo']} • ${p['nombre']}'),
                      subtitle: Text('Compra: Q${p['precio_compra']} • Venta: Q${p['precio_venta']}'),
                      trailing: Chip(label: Text('Stock: ${p['stock']}')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

