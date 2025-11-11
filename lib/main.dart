import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/clientes/clientes_screen.dart';
import 'features/clientes/cliente_form_screen.dart';
import 'features/ventas/ventas_screen.dart';
import 'features/compras/compras_screen.dart';
import 'features/inventario/productos_screen.dart';
import 'features/inventario/movimientos_screen.dart';

/// Punto de entrada de la aplicación.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

/// Widget raíz de la aplicación con rutas y tema.
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
        // Para edición, se pasa el cliente como `arguments` al navegar.
        '/clientes/editar': (_) => const ClienteFormScreen(),
        '/ventas': (_) => const VentasScreen(),
        '/compras': (_) => const ComprasScreen(),
        '/productos': (_) => const ProductosScreen(),
        '/movimientos': (_) => const MovimientosScreen(),
      },
      // Decide la pantalla inicial de forma asíncrona en tiempo de ejecución.
      home: FutureBuilder<bool>(
        future: ApiClient.I.hasSession(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final logged = snap.data == true;
          return logged ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
