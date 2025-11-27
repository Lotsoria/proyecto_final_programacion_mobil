import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Formulario de productos para `POST productos/` y `PATCH productos/{id}/`.
class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _form = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _precioVenta = TextEditingController();
  final _precioCompra = TextEditingController();
  final _stock = TextEditingController();
  final _proveedorId = TextEditingController();
  final _categoriaId = TextEditingController();
  late Future<List<Map<String, dynamic>>> _proveedoresFuture;
  List<Map<String, dynamic>> _proveedores = [];
  late Future<List<Map<String, dynamic>>> _categoriasFuture;
  List<Map<String, dynamic>> _categorias = [];
  bool _cargandoCodigo = false;
  bool _codigoBloqueado = false;
  bool _activo = true;
  bool _loading = false;
  bool _initialized = false;
  int? _productoId;

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _descripcion.dispose();
    _precioVenta.dispose();
    _precioCompra.dispose();
    _stock.dispose();
    _proveedorId.dispose();
    _categoriaId.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _productoId = args['id'] as int?;
      _codigo.text = (args['codigo'] ?? '').toString();
      _nombre.text = (args['nombre'] ?? '').toString();
      _descripcion.text = (args['descripcion'] ?? '').toString();
      _precioVenta.text = (args['precio_venta'] ?? '').toString();
      _precioCompra.text = (args['precio_compra'] ?? '').toString();
      _stock.text = (args['stock'] ?? '').toString();
      _proveedorId.text = (args['proveedor_id'] ?? args['proveedor'] ?? '').toString();
      _categoriaId.text = (args['categoria_id'] ?? args['categoria'] ?? '').toString();
      _activo = args['activo'] != false;
    }
    _proveedoresFuture = _loadProveedores();
    _categoriasFuture = _loadCategorias();
    if (_productoId != null && _codigo.text.isNotEmpty) {
      _codigoBloqueado = true;
    } else if (_codigo.text.isEmpty) {
      _cargarCodigoSugerido();
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<List<Map<String, dynamic>>> _loadProveedores() async {
    final res = await ApiClient.I.get('proveedores/', query: {'page_size': 100});
    final List data = res['results'] ?? res['data'] ?? [];
    _proveedores = data.cast<Map<String, dynamic>>();
    return _proveedores;
  }

  Future<List<Map<String, dynamic>>> _loadCategorias() async {
    final res = await ApiClient.I.get('categorias/', query: {'page_size': 100});
    final List data = res['results'] ?? res['data'] ?? [];
    _categorias = data.cast<Map<String, dynamic>>();
    return _categorias;
  }

  Future<String?> _siguienteCodigo() async {
    final res = await ApiClient.I.get('productos/', query: {'page_size': 50});
    final List data = res['results'] ?? res['data'] ?? [];
    if (data.isEmpty) return 'PROD001';
    int maxNumero = 0;
    int padding = 3;
    for (final raw in data) {
      final codigo = (raw['codigo'] ?? '').toString();
      final match = RegExp('(\\d+)\$').firstMatch(codigo);
      if (match == null) continue;
      final digits = match.group(1)!;
      final value = int.tryParse(digits) ?? 0;
      if (value > maxNumero) maxNumero = value;
      if (digits.length > padding) padding = digits.length;
    }
    final siguiente = maxNumero + 1;
    final ancho = padding < 3 ? 3 : padding;
    return 'PROD${siguiente.toString().padLeft(ancho, '0')}';
  }

  Future<void> _cargarCodigoSugerido() async {
    if (_productoId != null || _cargandoCodigo || _codigo.text.isNotEmpty) return;
    setState(() => _cargandoCodigo = true);
    try {
      final sugerido = await _siguienteCodigo();
      if (!mounted) return;
      if (sugerido != null && sugerido.isNotEmpty) {
        setState(() {
          _codigo.text = sugerido;
          _codigoBloqueado = true;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el codigo automaticamente')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoCodigo = false);
    }
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final precioVenta = double.tryParse(_precioVenta.text);
    final precioCompra = double.tryParse(_precioCompra.text);
    final stock = int.tryParse(_stock.text);
    final proveedor = int.tryParse(_proveedorId.text);
    final categoria = int.tryParse(_categoriaId.text);
    if (precioVenta == null || precioCompra == null || stock == null || proveedor == null || categoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa numeros (precios, stock, proveedor y categoria).')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final body = {
        'codigo': _codigo.text.trim(),
        'nombre': _nombre.text.trim(),
        'descripcion': _descripcion.text.trim(),
        'precio_venta': precioVenta,
        'precio_compra': precioCompra,
        'stock': stock,
        'proveedor_id': proveedor,
        'categoria_id': categoria,
        'activo': _activo,
      };
      if (_productoId != null) {
        await ApiClient.I.patch('productos/${_productoId!}/', data: body);
      } else {
        await ApiClient.I.post('productos/', data: body);
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
    final isEdit = _productoId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar producto' : 'Nuevo producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _codigo,
                decoration: InputDecoration(
                  labelText: 'Codigo',
                  suffixIcon: _productoId != null
                      ? null
                      : IconButton(
                          tooltip: 'Generar correlativo',
                          onPressed: _cargandoCodigo ? null : _cargarCodigoSugerido,
                          icon: _cargandoCodigo
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.autorenew),
                        ),
                ),
                validator: _required,
                readOnly: _codigoBloqueado,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcion,
                decoration: const InputDecoration(labelText: 'Descripcion'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioVenta,
                      decoration: const InputDecoration(labelText: 'Precio venta'),
                      validator: _required,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _precioCompra,
                      decoration: const InputDecoration(labelText: 'Precio compra'),
                      validator: _required,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stock,
                decoration: const InputDecoration(labelText: 'Stock'),
                validator: _required,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
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
                            .map<Map<String, dynamic>>(
                              (p) => {
                                'id': p['id'],
                                'nombre': p['empresa'] ?? p['nombre'] ?? 'Proveedor ${p['id']}',
                              },
                            )
                            .toList();
                        final value = int.tryParse(_proveedorId.text);
                        return DropdownButtonFormField<int>(
                          value: proveedores.any((p) => p['id'] == value) ? value : null,
                          decoration: const InputDecoration(labelText: 'Proveedor'),
                          items: proveedores
                              .map(
                                (p) => DropdownMenuItem<int>(
                                  value: p['id'] as int,
                                  child: Text(p['nombre'] ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _proveedorId.text = v?.toString() ?? ''),
                          validator: (v) => v == null ? 'Requerido' : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _categoriasFuture,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return TextFormField(
                            controller: _categoriaId,
                            decoration: const InputDecoration(labelText: 'Categoria ID'),
                            validator: _required,
                            keyboardType: TextInputType.number,
                          );
                        }
                        if (snap.hasError || (snap.data ?? _categorias).isEmpty) {
                          return TextFormField(
                            controller: _categoriaId,
                            decoration: const InputDecoration(labelText: 'Categoria ID'),
                            validator: _required,
                            keyboardType: TextInputType.number,
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
                        final value = int.tryParse(_categoriaId.text);
                        return DropdownButtonFormField<int>(
                          value: categorias.any((c) => c['id'] == value) ? value : null,
                          decoration: const InputDecoration(labelText: 'Categoria'),
                          items: categorias
                              .map(
                                (c) => DropdownMenuItem<int>(
                                  value: c['id'] as int,
                                  child: Text(c['nombre'] ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _categoriaId.text = v?.toString() ?? ''),
                          validator: (v) => v == null ? 'Requerido' : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
                title: const Text('Activo'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _guardar,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
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
