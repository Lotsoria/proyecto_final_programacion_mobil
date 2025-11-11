import 'package:flutter/material.dart';

/// Pantalla de Movimientos de Inventario.
///
/// Nota: a la espera de confirmación del endpoint de backend.
/// Propuesta: `GET inventario/movimientos/?tipo=entrada|salida` con asociación
/// a venta u orden de compra según corresponda.
class MovimientosScreen extends StatelessWidget {
  const MovimientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario - Movimientos')),
      body: const Center(
        child: Text(
          'Pendiente integrar con API de movimientos.\n'
          'Comparte el endpoint y estructura de respuesta para implementarlo.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

