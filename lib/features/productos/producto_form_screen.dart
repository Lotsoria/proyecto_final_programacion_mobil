import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Formulario de productos para `POST productos/` y `PUT|PATCH productos/{id}/`.
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
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final precioVenta = double.tryParse(_precioVenta.text);
    final precioCompra = double.tryParse(_precioCompra.text);
    final stock = int.tryParse(_stock.text);
    final proveedor = int.tryParse(_proveedorId.text);
    final categoria = int.tryParse(_categoriaId.text);
    if (precioVenta == null || precioCompra == null || stock == null || proveedor == null || categoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa números (precios, stock, proveedor y categoría).')),
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
                decoration: const InputDecoration(labelText: 'Código'),
                validator: _required,
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
                decoration: const InputDecoration(labelText: 'Descripción'),
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
                    child: TextFormField(
                      controller: _proveedorId,
                      decoration: const InputDecoration(labelText: 'Proveedor ID'),
                      validator: _required,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _categoriaId,
                      decoration: const InputDecoration(labelText: 'Categoría ID'),
                      validator: _required,
                      keyboardType: TextInputType.number,
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
