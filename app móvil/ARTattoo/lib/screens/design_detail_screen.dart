import 'package:flutter/material.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';

class DesignDetailScreen extends StatelessWidget {
  final Map<String,dynamic> design; const DesignDetailScreen({super.key, required this.design});
  @override
  Widget build(BuildContext context) {
    final img = design['image_url'] ?? '';
    final artistId = design['artist_id'] as int;
    return AppShell(
      title: design['title'] ?? 'Diseño',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        AspectRatio(aspectRatio:1, child: Image.network(img, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const ColoredBox(color: Color(0x11000000)))),
        const Gap(16),
        Text(design['description'] ?? '—'),
        const Gap(16),
        Row(children:[
          FilledButton(
            onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> BookingScreen(designId: design['id'], artistId: artistId))),
            child: const Text('Reservar'),
          ),
          const Spacer(),
          Text(design['price']!=null? '\$${design['price']}' : '—', style: const TextStyle(fontWeight: FontWeight.w700))
        ])
      ]),
    );
  }
}
