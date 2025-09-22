import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/auth_state.dart';
import '../widgets/common.dart';
import 'design_detail_screen.dart';
import 'appointments_screen.dart';
import 'create_design_screen.dart';

class CatalogScreen extends StatefulWidget {
  static const route = '/catalog';
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.getDesigns();
  }

  Future<void> _refresh() async {
    setState(() => _future = Api.getDesigns());
  }

  Future<void> _goCreateDesign() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateDesignScreen()),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Diseños',
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppointmentsScreen.route),
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Mis reservas',
        ),
        IconButton(onPressed: () => Api.logout(), icon: const Icon(Icons.logout)),
      ],
      floatingActionButton: authState.role == 'artist'
          ? FloatingActionButton(
              onPressed: _goCreateDesign,
              child: const Icon(Icons.add),
              tooltip: 'Nuevo diseño',
            )
          : null,

      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return const Busy();
          if (snap.hasError) {
            debugPrint('[Catalog] ERROR: ${snap.error}');
            return Center(child: Text('Error: ${snap.error}'));
          }

          final items = snap.data ?? const <Map<String, dynamic>>[];
          debugPrint('[Catalog] diseños recibidos = ${items.length}');

          if (items.isEmpty) {
            return SafeArea(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('Sin diseños aún')),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  // ↓ Más alto cada ítem para que quepa todo
                  childAspectRatio: .60,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final d = items[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        _,
                        MaterialPageRoute(
                          builder: (__) => DesignDetailScreen(design: d),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: (d['image_url'] != null &&
                                    (d['image_url'] as String).isNotEmpty)
                                ? Image.network(
                                    d['image_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const ColoredBox(color: Color(0x11000000)),
                                  )
                                : const ColoredBox(color: Color(0x11000000)),
                          ),
                          // Bloque inferior compacto
                          Expanded(
                            child: Padding(
                              // ↓ Paddings más chicos
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    d['title']?.toString() ?? '—',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    d['artist_name']?.toString() ?? '—',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      // Botón más compacto (alto ~32)
                                      FilledButton.tonal(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DesignDetailScreen(design: d),
                                          ),
                                        ),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          minimumSize: const Size(0, 32),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text('Ver'),
                                      ),
                                      const Spacer(),
                                      Text(
                                        d['price'] != null ? '\$${d['price']}' : '—',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
