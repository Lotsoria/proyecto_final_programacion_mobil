import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Formulario de compras:
/// - POST `compras/` crea.
/// - PATCH `compras/{id}/` actualiza si la orden está en estado `pendiente`.
class CompraFormScreen extends StatefulWidget {
  const CompraFormScreen({super.key});

  @override
  State<CompraFormScreen> createState() => _CompraFormScreenState();
}

class _CompraFormScreenState extends State<CompraFormScreen> {
  final _form = GlobalKey<FormState>();
  final _numero = TextEditingController();
  final _proveedorId = TextEditingController();
  final List<_CompraItemControllers> _items = [];
  late Future<List<Map<String, dynamic>>> _proveedoresFuture;
  List<Map<String, dynamic>> _proveedores = [];
  late Future<List<Map<String, dynamic>>> _productosFuture;
  List<Map<String, dynamic>> _productos = [];
  bool _cargandoNumero = false;
  bool _numeroBloqueado = false;
  bool _loading = false;
  bool _initialized = false;
  int? _compraId;

  @override
  void dispose() {
    _numero.dispose();
    _proveedorId.dispose();
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _compraId = args['id'] as int?;
      _numero.text = (args['numero'] ?? '').toString();
      _proveedorId.text = (args['proveedor_id'] ?? args['proveedor'] ?? '').toString();
      final List items = args['items'] is List ? args['items'] as List : [];
      for (final raw in items) {
        final map = Map<String, dynamic>.from(raw as Map);
        _items.add(
          _CompraItemControllers(
            producto: (map['producto_id'] ?? map['producto'] ?? '').toString(),
            cantidad: (map['cantidad'] ?? '').toString(),
            costo: (map['costo_unitario'] ?? '').toString(),
          ),
        );
      }
    }
    if (_items.isEmpty) _items.add(_CompraItemControllers());
    _proveedoresFuture = _loadProveedores();
    _productosFuture = _loadProductos();
    if (_compraId != null && _numero.text.isNotEmpty) {
      _numeroBloqueado = true;
    } else if (_numero.text.isEmpty) {
      _cargarNumeroSugerido();
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<List<Map<String, dynamic>>> _loadProveedores() async {
    final res = await ApiClient.I.get('proveedores/', query: {'page_size': 100});
    final List data = res['results'] ?? res['data'] ?? [];
    _proveedores = data.cast<Map<String, dynamic>>();
    return _proveedores;
  }

  Future<List<Map<String, dynamic>>> _loadProductos() async {
    final res = await ApiClient.I.get('productos/', query: {'page_size': 200});
    final List data = res['results'] ?? res['data'] ?? [];
    _productos = data.cast<Map<String, dynamic>>();
    return _productos;
  }

  Future<String?> _siguienteNumero({required String resource, required String prefijo}) async {
    final res = await ApiClient.I.get(resource, query: {'page_size': 50});
    final List data = res['results'] ?? res['data'] ?? [];
    if (data.isEmpty) return '${prefijo}0001';
    int maxNumero = 0;
    int padding = 4;
    for (final raw in data) {
      final numero = (raw['numero'] ?? '').toString();
      final match = RegExp(r'(\d+)$').firstMatch(numero);
      if (match == null) continue;
      final digits = match.group(1)!;
      final value = int.tryParse(digits) ?? 0;
      if (value > maxNumero) maxNumero = value;
      if (digits.length > padding) padding = digits.length;
    }
    final siguiente = maxNumero + 1;
    final ancho = padding < 4 ? 4 : padding;
    return '$prefijo${siguiente.toString().padLeft(ancho, '0')}';
  }

  Future<void> _cargarNumeroSugerido() async {
    if (_compraId != null || _cargandoNumero || _numero.text.isNotEmpty) return;
    setState(() => _cargandoNumero = true);
    try {
      final sugerido = await _siguienteNumero(resource: 'compras/', prefijo: 'CO-');
      if (!mounted) return;
      if (sugerido != null && sugerido.isNotEmpty) {
        setState(() {
          _numero.text = sugerido;
          _numeroBloqueado = true;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el n�mero autom�ticamente')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoNumero = false);
    }
  }


  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final proveedor = int.tryParse(_proveedorId.text);
    if (proveedor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proveedor ID inválido')));
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final c in _items) {
      final producto = int.tryParse(c.producto.text);
      final cantidad = int.tryParse(c.cantidad.text);
      final costo = double.tryParse(c.costo.text);
      if (producto == null || cantidad == null || cantidad <= 0 || costo == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa producto, cantidad y costo en items')));
        return;
      }
      items.add({
        'producto_id': producto,
        'cantidad': cantidad,
        'costo_unitario': costo,
      });
    }
    setState(() => _loading = true);
    try {
      final body = {
        'numero': _numero.text.trim(),
        'proveedor_id': proveedor,
        'items': items,
      };
      if (_compraId != null) {
        await ApiClient.I.patch('compras/${_compraId!}/', data: body);
      } else {
        await ApiClient.I.post('compras/', data: body);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _compraId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar compra' : 'Nueva compra')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _numero,
                decoration: InputDecoration(
                  labelText: 'Número',
                  suffixIcon: _compraId != null
                      ? null
                      : IconButton(
                          tooltip: 'Generar correlativo',
                          onPressed: _cargandoNumero ? null : _cargarNumeroSugerido,
                          icon: _cargandoNumero
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.autorenew),
                        ),
                ),
                validator: _required,
                readOnly: _numeroBloqueado,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _proveedoresFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return TextFormField(
                      controller: _proveedorId,
                      decoration: const InputDecoration(labelText: 'Proveedor ID'),
                      validator: _required,
                      keyboardType: TextInputType.number,
                    );
                  }
                  if (snap.hasError || (snap.data ?? _proveedores).isEmpty) {
                    return TextFormField(
                      controller: _proveedorId,
                      decoration: const InputDecoration(labelText: 'Proveedor ID'),
                      validator: _required,
                      keyboardType: TextInputType.number,
                    );
                  }
                  final proveedores = (snap.data ?? _proveedores)
                      .where((p) => p['id'] != null)
                      .map<Map<String, dynamic>>((p) => {
                            'id': p['id'],
                            'nombre': p['empresa'] ?? p['nombre'] ?? p['nombre_completo'] ?? p['correo'] ?? "Proveedor ${p['id']}",
                          })
                      .toList();
                  final value = int.tryParse(_proveedorId.text);
                  return DropdownButtonFormField<int>(
                    value: proveedores.any((p) => p['id'] == value) ? value : null,
                    decoration: const InputDecoration(labelText: 'Proveedor'),
                    items: proveedores
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p['id'] as int,
                            child: Text(p["nombre"] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _proveedorId.text = v?.toString() ?? ''),
                    validator: (v) => v == null ? 'Requerido' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text('Items'),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map(
                (entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _productosFuture,
                                  builder: (context, snap) {
                                    if (snap.connectionState != ConnectionState.done) {
                                      return TextFormField(
                                        controller: item.producto,
                                        decoration: const InputDecoration(labelText: 'Producto ID'),
                                        validator: _required,
                                        keyboardType: TextInputType.number,
                                      );
                                    }
                                    if (snap.hasError || (snap.data ?? _productos).isEmpty) {
                                      return TextFormField(
                                        controller: item.producto,
                                        decoration: const InputDecoration(labelText: 'Producto ID'),
                                        validator: _required,
                                        keyboardType: TextInputType.number,
                                      );
                                    }
                                    final productos = (snap.data ?? _productos)
                                        .where((p) => p['id'] != null)
                                        .map<Map<String, dynamic>>((p) => {
                                              'id': p['id'],
                                              'nombre': p['nombre'] ?? p['codigo'] ?? 'Producto',
                                              'codigo': p['codigo'] ?? '',
                                              'costo': p['costo_promedio'] ?? p['costo'] ?? p['precio_compra'],
                                            })
                                        .toList();
                                    final value = int.tryParse(item.producto.text);
                                    return DropdownButtonFormField<int>(
                                      value: productos.any((p) => p['id'] == value) ? value : null,
                                      decoration: const InputDecoration(labelText: 'Producto'),
                                      items: productos
                                          .map(
                                            (p) => DropdownMenuItem<int>(
                                              value: p['id'] as int,
                                              child: Text('${p["codigo"]} - ${p["nombre"]}'),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(() {
                                        item.producto.text = v?.toString() ?? '';
                                        if (v != null) {
                                          final match = productos.firstWhere(
                                            (p) => p['id'] == v,
                                            orElse: () => {},
                                          );
                                          final costo = match['costo'];
                                          if (costo != null) item.costo.text = costo.toString();
                                        }
                                      }),
                                      validator: (v) => v == null ? 'Requerido' : null,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: _items.length == 1
                                    ? null
                                    : () => setState(() => _items.removeAt(idx)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: item.cantidad,
                                  decoration: const InputDecoration(labelText: 'Cantidad'),
                                  validator: _required,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: item.costo,
                                  decoration: const InputDecoration(labelText: 'Costo unitario'),
                                  validator: _required,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _items.add(_CompraItemControllers())),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar item'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _guardar,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(isEdit ? 'Actualizar' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompraItemControllers {
  final TextEditingController producto;
  final TextEditingController cantidad;
  final TextEditingController costo;

  _CompraItemControllers({String producto = '', String cantidad = '', String costo = ''})
      : producto = TextEditingController(text: producto),
        cantidad = TextEditingController(text: cantidad),
        costo = TextEditingController(text: costo);

  void dispose() {
    producto.dispose();
    cantidad.dispose();
    costo.dispose();
  }
}

