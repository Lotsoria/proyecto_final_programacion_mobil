import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Dashboard: consume `GET dashboard/` para mostrar métricas resumidas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final json = await ApiClient.I.get('dashboard/');
    return json;
  }

  Future<void> _logout() async {
    try {
      await ApiClient.I.post('logout/');
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  Widget _metricCard(String title, String value, {IconData? icon}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (icon != null) Icon(icon),
            if (icon != null) const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Clientes'),
              onTap: () => Navigator.pushNamed(context, '/clientes'),
            ),
            ListTile(
              leading: const Icon(Icons.handshake),
              title: const Text('Proveedores'),
              onTap: () => Navigator.pushNamed(context, '/proveedores'),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categorías'),
              onTap: () => Navigator.pushNamed(context, '/categorias'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Productos'),
              onTap: () => Navigator.pushNamed(context, '/productos'),
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
              leading: const Icon(Icons.list_alt),
              title: const Text('Inventario'),
              onTap: () => Navigator.pushNamed(context, '/inventario'),
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Movimientos'),
              onTap: () => Navigator.pushNamed(context, '/movimientos'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')))],
              );
            }
            final data = (snap.data ?? {}) as Map<String, dynamic>;
            final top = (data['top_productos'] as List?) ?? [];
            final stockBajo = (data['stock_bajo'] as List?) ?? [];
            final ultimas = (data['ultimas_ventas'] as List?) ?? [];
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text('Resumen', style: Theme.of(context).textTheme.titleLarge),
                _metricCard('Total hoy', 'Q${data['total_hoy'] ?? '-'}', icon: Icons.today),
                _metricCard('Total mes', 'Q${data['total_mes'] ?? '-'}', icon: Icons.calendar_month),
                _metricCard('Total completado', 'Q${data['total_completado'] ?? '-'}', icon: Icons.check),
                _metricCard('Ventas pendientes', '${data['ventas_pendientes'] ?? 0}', icon: Icons.pending_actions),
                _metricCard('Compras pendientes', '${data['compras_pendientes'] ?? 0}', icon: Icons.pending),
                _metricCard('Stock total', '${data['stock_total'] ?? 0}', icon: Icons.inventory),
                const SizedBox(height: 12),
                Text('Top productos', style: Theme.of(context).textTheme.titleMedium),
                ...top.map((p) => ListTile(
                      leading: const Icon(Icons.star),
                      title: Text(p['nombre'] ?? ''),
                      subtitle: Text('Código: ${p['codigo'] ?? ''} • Unidades: ${p['unidades'] ?? '-'}'),
                      trailing: Text('Q${p['monto'] ?? '-'}'),
                    )),
                const SizedBox(height: 12),
                Text('Stock bajo', style: Theme.of(context).textTheme.titleMedium),
                ...stockBajo.map((p) => ListTile(
                      leading: const Icon(Icons.warning_amber),
                      title: Text(p['nombre'] ?? ''),
                      trailing: Text('Stock: ${p['stock'] ?? '-'}'),
                    )),
                const SizedBox(height: 12),
                Text('Últimas ventas', style: Theme.of(context).textTheme.titleMedium),
                ...ultimas.map((v) => ListTile(
                      leading: const Icon(Icons.receipt),
                      title: Text('${v['numero'] ?? ''} • ${v['cliente'] ?? ''}'),
                      subtitle: Text('${v['fecha'] ?? ''} • ${v['estado'] ?? ''}'),
                      trailing: Text('Q${v['monto'] ?? '-'}'),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}
