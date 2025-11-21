import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Formulario de proveedor.
/// - POST `proveedores/` para crear.
/// - PATCH `proveedores/{id}/` para editar campos enviados.
class ProveedorFormScreen extends StatefulWidget {
  const ProveedorFormScreen({super.key});

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen> {
  final _form = GlobalKey<FormState>();
  final _empresa = TextEditingController();
  final _contacto = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  bool _loading = false;
  bool _initialized = false;
  int? _proveedorId;

  @override
  void dispose() {
    _empresa.dispose();
    _contacto.dispose();
    _telefono.dispose();
    _direccion.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _proveedorId = args['id'] as int?;
      _empresa.text = (args['empresa'] ?? '').toString();
      _contacto.text = (args['contacto_principal'] ?? '').toString();
      _telefono.text = (args['telefono'] ?? '').toString();
      _direccion.text = (args['direccion'] ?? '').toString();
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = {
        'empresa': _empresa.text.trim(),
        'contacto_principal': _contacto.text.trim(),
        'telefono': _telefono.text.trim(),
        'direccion': _direccion.text.trim(),
      };
      if (_proveedorId != null) {
        await ApiClient.I.patch('proveedores/${_proveedorId!}/', data: body);
      } else {
        await ApiClient.I.post('proveedores/', data: body);
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
    final isEdit = _proveedorId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar proveedor' : 'Nuevo proveedor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _empresa,
                decoration: const InputDecoration(labelText: 'Empresa'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contacto,
                decoration: const InputDecoration(labelText: 'Contacto principal'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefono,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: _required,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccion,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: _required,
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
