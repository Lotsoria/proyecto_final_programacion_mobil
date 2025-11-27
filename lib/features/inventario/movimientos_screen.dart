import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Movimientos de inventario usando `GET inventario/movimientos/` con filtros
/// opcionales: tipo, producto, desde, hasta, referencia.
class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  String? _tipo;
  final _producto = TextEditingController();
  int? _productoId;
  final _desde = TextEditingController();
  final _hasta = TextEditingController();
  final _referencia = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  late Future<List<Map<String, dynamic>>> _productosFuture;
  List<Map<String, dynamic>> _productos = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _productosFuture = _loadProductos();
  }

  @override
  void dispose() {
    _producto.dispose();
    _desde.dispose();
    _hasta.dispose();
    _referencia.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final query = <String, dynamic>{};
    if (_tipo != null) query['tipo'] = _tipo;
    final prodValue = _productoId ?? int.tryParse(_producto.text);
    if (prodValue != null) query['producto'] = prodValue;
    if (_desde.text.isNotEmpty) query['desde'] = _desde.text;
    if (_hasta.text.isNotEmpty) query['hasta'] = _hasta.text;
    if (_referencia.text.isNotEmpty) query['referencia'] = _referencia.text;
    final json = await ApiClient.I.get('inventario/movimientos/', query: query);
    final List items = json['results'] ?? json['data'] ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _loadProductos() async {
    final json = await ApiClient.I.get('productos/', query: {'page_size': 200});
    final List items = json['results'] ?? json['data'] ?? [];
    _productos = items.cast<Map<String, dynamic>>();
    return _productos;
  }

  void _aplicarFiltros() {
    setState(() {
      _productoId = _productoId ?? int.tryParse(_producto.text);
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario - Movimientos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _tipo,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                          DropdownMenuItem<String?>(value: 'entrada', child: Text('Entrada')),
                          DropdownMenuItem<String?>(value: 'salida', child: Text('Salida')),
                        ],
                        onChanged: (v) => setState(() => _tipo = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _productosFuture,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return TextField(
                              controller: _producto,
                              decoration: const InputDecoration(labelText: 'Producto ID', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _productoId = null,
                            );
                          }
                          if (snap.hasError || (snap.data ?? _productos).isEmpty) {
                            return TextField(
                              controller: _producto,
                              decoration: const InputDecoration(labelText: 'Producto ID', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _productoId = null,
                            );
                          }
                          final productos = (snap.data ?? _productos)
                              .where((p) => p['id'] != null)
                              .map<Map<String, dynamic>>((p) => {
                                    'id': p['id'],
                                    'nombre': p['nombre'] ?? p['codigo'] ?? 'Producto',
                                    'codigo': p['codigo'] ?? '',
                                  })
                              .toList();
                          final value = _productoId ?? int.tryParse(_producto.text);
                          return DropdownButtonFormField<int?>(
                            value: productos.any((p) => p['id'] == value) ? value : null,
                            decoration: const InputDecoration(
                              labelText: 'Producto',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Todos'),
                              ),
                          ...productos.map(
                            (p) => DropdownMenuItem<int?>(
                              value: p['id'] as int,
                              child: Text('${p["codigo"]} - ${p["nombre"]}'),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _productoId = v;
                          _producto.text = v?.toString() ?? '';
                        }),
                      );
                    },
                  ),
                ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _desde,
                        decoration: const InputDecoration(labelText: 'Desde (YYYY-MM-DD)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _hasta,
                        decoration: const InputDecoration(labelText: 'Hasta (YYYY-MM-DD)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _referencia,
                  decoration: const InputDecoration(labelText: 'Referencia', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _aplicarFiltros,
                    child: const Text('Filtrar'),
                  ),
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
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                final data = (snap.data ?? []) as List<Map<String, dynamic>>;
                if (data.isEmpty) return const Center(child: Text('Sin movimientos'));
                return ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = data[i];
                    return ListTile(
                      title: Text('${m['producto'] ?? ''} • ${m['tipo'] ?? ''}'),
                      subtitle: Text('${m['fecha'] ?? ''} • Ref: ${m['referencia'] ?? '-'}'),
                      trailing: Text('Cantidad: ${m['cantidad'] ?? ''}'),
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
