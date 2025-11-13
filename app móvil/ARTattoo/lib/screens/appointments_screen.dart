import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // por si usas enlaces en otra parte
import '../core/api.dart';
import '../widgets/common.dart';
import 'design_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  static const route = '/apts';
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = Api.myAppointments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = Api.myAppointments();
    });
    await _future;
  }

  Future<void> _cancel(int id) async {
    try {
      await Api.cancel(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(ok('Cita cancelada'));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(ko(e.toString()));
    }
  }

  Future<void> _markPaid(int id) async {
    try {
      await Api.markPaid(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(ok('Pago registrado'));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(ko(e.toString()));
    }
  }

  Future<void> _payNow(int appointmentId) async {
    try {
      final url = await Api.createCheckout(appointmentId);
      final okLaunch = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!okLaunch) throw 'No se pudo abrir el checkout';
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(ko('Pago: $e'));
    }
  }

  Widget _statusChip(String status, bool paid) {
    Color bg;
    Color fg = Colors.white;
    String label = status;

    if (paid) {
      bg = Colors.green;
      label = '$status • PAGADO';
    } else {
      switch (status) {
        case 'booked':
          bg = Colors.orange;
          break;
        case 'canceled': // backend usa "canceled"
          bg = Colors.redAccent;
          break;
        case 'done':
          bg = Colors.blueGrey;
          break;
        default:
          bg = Colors.grey;
      }
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Chip(
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: bg,
          labelStyle: TextStyle(color: fg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Busy();
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final items = snap.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) return const Center(child: Text('No tienes reservas'));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = items[i];

                // id robusto
                final dynamic rawId = a['id'];
                final int? id = (rawId is int) ? rawId : int.tryParse((rawId ?? '').toString());

                final String status = (a['status'] ?? '—').toString();
                final bool paid = a['paid'] == true;
                final bool payNow = a['pay_now'] == true;

                final String when = (a['start_time'] ?? '').toString();
                final dynamic price = a['price'];
                final String priceStr = (price != null) ? '\$${price}' : '';

                // -------- diseño y artista (desde appointments/me enriquecido) --------
                final Map<String, dynamic>? design =
                    (a['design'] is Map) ? Map<String, dynamic>.from(a['design']) : null;
                final Map<String, dynamic>? artist =
                    (a['artist'] is Map) ? Map<String, dynamic>.from(a['artist']) : null;

                final dynamic _tmpDesignId = design?['id'] ?? a['design_id'];
                final int? designId = (_tmpDesignId is int)
                    ? _tmpDesignId
                    : int.tryParse((_tmpDesignId ?? '').toString());

                final int artistId = (() {
                  final raw = a['artist_id'];
                  if (raw is int) return raw;
                  return int.tryParse((raw ?? '').toString()) ?? (design?['artist_id'] ?? 0);
                })();

                final String artistName = (artist?['name'] ??
                        design?['artist_name'] ??
                        (artistId != 0 ? 'Artista #$artistId' : 'Artista'))
                    .toString();

                final String artistAvatar = (artist?['avatar_url'] ??
                        artist?['avatar'] ??
                        design?['artist_avatar_url'] ??
                        design?['artist_avatar'] ??
                        '')
                    .toString();

                final String designTitle =
                    (design?['title'] ?? a['design_title'] ?? 'Diseño').toString();

                final String designDesc = (design?['description'] ?? '').toString();

                final String designThumb = (
                  design?['image_url'] ??
                  design?['thumb'] ??
                  design?['thumbnail'] ??
                  design?['image'] ??
                  a['design_thumb'] ??
                  a['design_thumbnail'] ??
                  a['design_image'] ??
                  a['thumbnail'] ??
                  a['image'] ??
                  a['photo'] ??
                  a['photo_url'] ??
                  a['preview'] ??
                  a['preview_url'] ??
                  a['cover'] ??
                  a['cover_url'] ??
                  ''
                ).toString();

                // ======================= ITEM (sin ListTile) =======================
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MINIATURA → siempre navega al detalle
                      InkWell(
                        onTap: () {
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DesignDetailScreen(
                                design: {
                                  'id': designId ?? 0,
                                  'title': designTitle,
                                  'description': designDesc,
                                  'price': price,
                                  // claves que el DetailScreen usa:
                                  'image_url': designThumb,
                                  'artist_id': artistId,
                                  'artist_name': artistName,
                                  'artist_avatar_url': artistAvatar,
                                },
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (designThumb.isNotEmpty)
                              ? Image.network(
                                  designThumb,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_not_supported),
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  alignment: Alignment.center,
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  child: const Icon(Icons.image_outlined),
                                ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // CONTENIDO (toma todo el ancho disponible)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cita #${id ?? '—'}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(when),
                            if (priceStr.isNotEmpty) Text('Monto: $priceStr'),
                            Text('paid: $paid • pay_now: $payNow'),
                            const SizedBox(height: 8),
                            _statusChip(status, paid),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // BOTONES → columna vertical (sin overflow)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (id != null && status == 'booked')
                            OutlinedButton(
                              onPressed: () => _cancel(id),
                              child: const Text('Cancelar'),
                            ),
                          if (id != null && !paid && status == 'booked' && payNow != true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: FilledButton.tonal(
                                onPressed: () => _markPaid(id),
                                child: const Text('Marcar pago'),
                              ),
                            ),
                          if (id != null && !paid && status == 'booked' && payNow == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: FilledButton(
                                onPressed: () => _payNow(id),
                                child: const Text('Pagar ahora'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
