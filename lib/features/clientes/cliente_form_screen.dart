import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Formulario para crear un nuevo cliente.
///
/// POST `clientes/` con body { nombre_completo, direccion, telefono, email }.
class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  bool _loading = false;
  bool _initialized = false;
  int? _clienteId; // si viene, es edición

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    // Si se navega con argumentos, se asume modo edición.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _clienteId = args['id'] as int?;
      _nombre.text = (args['nombre_completo'] ?? '').toString();
      _direccion.text = (args['direccion'] ?? '').toString();
      _telefono.text = (args['telefono'] ?? '').toString();
      _email.text = (args['email'] ?? '').toString();
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;
  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final email = v.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return ok ? null : 'Email no válido';
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = {
        'nombre_completo': _nombre.text.trim(),
        'direccion': _direccion.text.trim(),
        'telefono': _telefono.text.trim(),
        'email': _email.text.trim(),
      };
      if (_clienteId != null) {
        // Actualización parcial mediante PATCH clientes/{id}/
        await ApiClient.I.patch('clientes/${_clienteId!}/', data: body);
      } else {
        // Creación
        await ApiClient.I.post('clientes/', data: body);
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
    final isEdit = _clienteId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar Cliente' : 'Nuevo Cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: _required,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccion,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: _required,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefono,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: _required,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _emailValidator,
                keyboardType: TextInputType.emailAddress,
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
