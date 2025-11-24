import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Formulario de ventas:
/// - POST `ventas/` crea venta con items.
/// - PATCH `ventas/{id}/` actualiza si está en estado `pendiente`.
class VentaFormScreen extends StatefulWidget {
  const VentaFormScreen({super.key});

  @override
  State<VentaFormScreen> createState() => _VentaFormScreenState();
}

class _VentaFormScreenState extends State<VentaFormScreen> {
  final _form = GlobalKey<FormState>();
  final _numero = TextEditingController();
  final _clienteId = TextEditingController();
  final List<_VentaItemControllers> _items = [];
  bool _cargandoNumero = false;
  bool _numeroBloqueado = false;
  bool _loading = false;
  bool _initialized = false;
  int? _ventaId;

  @override
  void dispose() {
    _numero.dispose();
    _clienteId.dispose();
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
      _ventaId = args['id'] as int?;
      _numero.text = (args['numero'] ?? '').toString();
      _clienteId.text = (args['cliente_id'] ?? args['cliente'] ?? '').toString();
      final List items = args['items'] is List ? args['items'] as List : [];
      for (final raw in items) {
        final map = Map<String, dynamic>.from(raw as Map);
        _items.add(
          _VentaItemControllers(
            producto: (map['producto_id'] ?? map['producto'] ?? '').toString(),
            cantidad: (map['cantidad'] ?? '').toString(),
            precio: (map['precio_unitario'] ?? '').toString(),
          ),
        );
      }
    }
    if (_items.isEmpty) _items.add(_VentaItemControllers());
    if (_ventaId != null && _numero.text.isNotEmpty) {
      _numeroBloqueado = true;
    } else if (_numero.text.isEmpty) {
      _cargarNumeroSugerido();
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

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
    if (_ventaId != null || _cargandoNumero || _numero.text.isNotEmpty) return;
    setState(() => _cargandoNumero = true);
    try {
      final sugerido = await _siguienteNumero(resource: 'ventas/', prefijo: 'V-');
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
          const SnackBar(content: Text('No se pudo generar el n\xfamero autom\xE1ticamente')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoNumero = false);
    }
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final cliente = int.tryParse(_clienteId.text);
    if (cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente ID inválido')));
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final c in _items) {
      final producto = int.tryParse(c.producto.text);
      final cantidad = int.tryParse(c.cantidad.text);
      final precio = c.precio.text.isEmpty ? null : double.tryParse(c.precio.text);
      if (producto == null || cantidad == null || cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa producto y cantidad en items')));
        return;
      }
      items.add({
        'producto_id': producto,
        'cantidad': cantidad,
        if (precio != null) 'precio_unitario': precio,
      });
    }
    setState(() => _loading = true);
    try {
      final body = {
        'numero': _numero.text.trim(),
        'cliente_id': cliente,
        'items': items,
      };
      if (_ventaId != null) {
        await ApiClient.I.patch('ventas/${_ventaId!}/', data: body);
      } else {
        await ApiClient.I.post('ventas/', data: body);
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
    final isEdit = _ventaId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar venta' : 'Nueva venta')),
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
                  labelText: 'N�mero',
                  suffixIcon: _ventaId != null
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
              TextFormField(
                controller: _clienteId,
                decoration: const InputDecoration(labelText: 'Cliente ID'),
                validator: _required,
                keyboardType: TextInputType.number,
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
                                child: TextFormField(
                                  controller: item.producto,
                                  decoration: const InputDecoration(labelText: 'Producto ID'),
                                  validator: _required,
                                  keyboardType: TextInputType.number,
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
                                  controller: item.precio,
                                  decoration: const InputDecoration(labelText: 'Precio unitario (opcional)'),
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
                  onPressed: () => setState(() => _items.add(_VentaItemControllers())),
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

class _VentaItemControllers {
  final TextEditingController producto;
  final TextEditingController cantidad;
  final TextEditingController precio;

  _VentaItemControllers({String producto = '', String cantidad = '', String precio = ''})
      : producto = TextEditingController(text: producto),
        cantidad = TextEditingController(text: cantidad),
        precio = TextEditingController(text: precio);

  void dispose() {
    producto.dispose();
    cantidad.dispose();
    precio.dispose();
  }
}

