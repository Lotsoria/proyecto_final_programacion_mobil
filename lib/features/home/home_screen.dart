import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Pantalla principal con Drawer para navegar entre módulos y cerrar sesión.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Cierra sesión contra la API y vuelve a la pantalla de login.
  Future<void> _logout(BuildContext context) async {
    try {
      await ApiClient.I.post('logout/');
    } catch (_) {
      // Ignorar errores al cerrar sesión para no bloquear al usuario.
    }
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión Móvil')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Clientes'),
              onTap: () => Navigator.pushNamed(context, '/clientes'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Ventas'),
              onTap: () => Navigator.pushNamed(context, '/ventas'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Compras'),
              onTap: () => Navigator.pushNamed(context, '/compras'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Inventario - Productos'),
              onTap: () => Navigator.pushNamed(context, '/productos'),
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Inventario - Movimientos'),
              onTap: () => Navigator.pushNamed(context, '/movimientos'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: const Center(child: Text('Bienvenido')),
    );
  }
}

