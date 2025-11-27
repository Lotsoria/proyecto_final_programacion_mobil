import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Inventario: consume `GET inventario/?categoria={id}&min={stock}` para listar
/// productos filtrando por categoria y/o stock minimo.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  int? _categoria;
  int? _min;
  late Future<List<Map<String, dynamic>>> _future;
  late Future<List<Map<String, dynamic>>> _categoriasFuture;
  List<Map<String, dynamic>> _categorias = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _categoriasFuture = _loadCategorias();
  }

  /// Llama a `GET inventario/` con los filtros activos y normaliza la respuesta.
  Future<List<Map<String, dynamic>>> _load() async {
    final query = <String, dynamic>{};
    if (_categoria != null) query['categoria'] = _categoria;
    if (_min != null) query['min'] = _min;
    final json = await ApiClient.I.get('inventario/', query: query);
    final List items = json['results'] ?? json['data'] ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _loadCategorias() async {
    final json = await ApiClient.I.get('categorias/', query: {'page_size': 100});
    final List items = json['results'] ?? json['data'] ?? [];
    _categorias = items.cast<Map<String, dynamic>>();
    return _categorias;
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
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _categoriasFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return TextField(
                          decoration: const InputDecoration(
                            labelText: 'Categoria (id)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _categoria = int.tryParse(v),
                        );
                      }
                      if (snap.hasError || (snap.data ?? _categorias).isEmpty) {
                        return TextField(
                          decoration: const InputDecoration(
                            labelText: 'Categoria (id)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _categoria = int.tryParse(v),
                        );
                      }
                      final categorias = (snap.data ?? _categorias)
                          .where((c) => c['id'] != null)
                          .map<Map<String, dynamic>>(
                            (c) => {
                              'id': c['id'],
                              'nombre': c['nombre'] ?? 'Categoria ${c['id']}',
                            },
                          )
                          .toList();
                      return DropdownButtonFormField<int>(
                        value: _categoria,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...categorias.map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['nombre'] ?? ''),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _categoria = v),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Stock maximo (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _min = int.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _future = _load();
                    });
                  },
                  child: const Text('Filtrar'),
                ),
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
                      title: Text('${p['codigo'] ?? ''} - ${p['nombre'] ?? ''}'),
                      subtitle: Text('Compra: Q${p['precio_compra']} - Venta: Q${p['precio_venta']}'),
                      trailing: Chip(label: Text('Stock: ${p['stock'] ?? '-'}')),
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
