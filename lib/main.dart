import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/clientes/clientes_screen.dart';
import 'features/clientes/cliente_form_screen.dart';
import 'features/proveedores/proveedores_screen.dart';
import 'features/proveedores/proveedor_form_screen.dart';
import 'features/categorias/categorias_screen.dart';
import 'features/categorias/categoria_form_screen.dart';
import 'features/productos/productos_screen.dart';
import 'features/productos/producto_form_screen.dart';
import 'features/ventas/ventas_screen.dart';
import 'features/ventas/venta_form_screen.dart';
import 'features/compras/compras_screen.dart';
import 'features/inventario/productos_screen.dart' as inventario;
import 'features/inventario/movimientos_screen.dart';

/// Punto de entrada de la aplicación.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

/// Widget raíz con rutas registradas y tema base.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Móvil',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/clientes': (_) => const ClientesScreen(),
        '/clientes/nuevo': (_) => const ClienteFormScreen(),
        '/clientes/editar': (_) => const ClienteFormScreen(),
        '/proveedores': (_) => const ProveedoresScreen(),
        '/proveedores/nuevo': (_) => const ProveedorFormScreen(),
        '/proveedores/editar': (_) => const ProveedorFormScreen(),
        '/categorias': (_) => const CategoriasScreen(),
        '/categorias/nueva': (_) => const CategoriaFormScreen(),
        '/categorias/editar': (_) => const CategoriaFormScreen(),
        '/productos': (_) => const ProductosScreen(),
        '/productos/nuevo': (_) => const ProductoFormScreen(),
        '/productos/editar': (_) => const ProductoFormScreen(),
        '/ventas': (_) => const VentasScreen(),
        '/ventas/nueva': (_) => const VentaFormScreen(),
        '/ventas/editar': (_) => const VentaFormScreen(),
        '/compras': (_) => const ComprasScreen(),
        '/compras/nueva': (_) => const ComprasScreen(),
        '/compras/editar': (_) => const ComprasScreen(),
        '/inventario': (_) => const inventario.InventarioScreen(),
        '/movimientos': (_) => const MovimientosScreen(),
      },
      home: FutureBuilder<bool>(
        future: ApiClient.I.hasSession(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final logged = snap.data == true;
          return logged ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
