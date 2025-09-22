import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_state.dart';

class Api {
  // Usa SIEMPRE el mismo host que valida los JWT
  static const base = 'http://167.114.145.34:8000';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final t = _prefs?.getString('token');
    final r = _prefs?.getString('role');
    final n = _prefs?.getString('name');
    final id = _prefs?.getInt('uid');
    if (t != null && r != null && n != null && id != null) {
      authState.set(token: t, role: r, name: n, userId: id);
    }
    // DEBUG: imprime si hay token cargado
    print('[Api.init] token loaded? ${authState.token != null}');
  }

  static Future<void> _save(Map data) async {
    await _prefs?.setString('token', data['access_token']);
    await _prefs?.setString('role', data['role']);
    await _prefs?.setString('name', data['name']);
    await _prefs?.setInt('uid', data['user_id']);
  }

  static Map<String, String> _headers({bool withAuth = true}) {
    final h = {'Content-Type': 'application/json'};
    if (withAuth) {
      final t = authState.token;
      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      } else {
        print('[Api._headers] WARNING: no token present for authenticated request');
      }
    }
    return h;
  }

  // ---- Auth ----
  static Future<String?> login(String email, String pass) async {
    final r = await http.post(
      Uri.parse('$base/auth/login'),
      headers: _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': pass}),
    );
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      await _save(data);
      authState.set(
        token: data['access_token'],
        role: data['role'],
        name: data['name'],
        userId: data['user_id'],
      );
      print('[Api.login] token set? ${authState.token != null}');
      return null;
    }
    try {
      return jsonDecode(r.body)['msg'];
    } catch (_) {
      return 'Error de login';
    }
  }

  static Future<String?> register({
    required String email,
    required String pass,
    required String name,
    required String role,
  }) async {
    final r = await http.post(
      Uri.parse('$base/auth/register'),
      headers: _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': pass, 'role': role, 'name': name}),
    );
    if (r.statusCode == 201) return null; // ok
    try {
      return jsonDecode(r.body)['msg'];
    } catch (_) {
      return 'Error de registro';
    }
  }

  static Future<void> logout() async {
    await _prefs?.clear();
    authState.clear();
  }

  // ---- Designs ----
  static Future<List<Map<String, dynamic>>> getDesigns({int? artistId}) async {
    final q = artistId != null ? '?artist_id=$artistId' : '';
    final r = await http.get(Uri.parse('$base/designs$q'));
    if (r.statusCode != 200) throw Exception('No se pudo cargar el catálogo');
    return List<Map<String, dynamic>>.from(jsonDecode(r.body));
  }

  static Future<Map?> createDesign({
    required String title,
    String? description,
    String? imageUrl,
    int? price,
  }) async {
    if (authState.token == null || authState.token!.isEmpty) {
      throw Exception('No hay token en memoria. Cierra sesión e inicia nuevamente.');
    }
    print('[Api.createDesign] using token (first 12): ${authState.token!.substring(0, 12)}...');

    final r = await http.post(
      Uri.parse('$base/designs'),
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'price': price,
      }),
    );
    if (r.statusCode == 201) return jsonDecode(r.body);
    print('[Api.createDesign] status=${r.statusCode} body=${r.body}');
    throw Exception(_safeMsg(r.body) ?? 'Error creando diseño');
  }

  // ---- Appointments ----
  static Future<Map> book({
    required int designId,
    required int artistId,
    required DateTime start,
    int durationMin = 60,
    bool payNow = false,
  }) async {
    final r = await http.post(
      Uri.parse('$base/appointments'),
      headers: _headers(),
      body: jsonEncode({
        'design_id': designId,
        'artist_id': artistId,
        'start_time': start.toIso8601String(),
        'duration_minutes': durationMin,
        'pay_now': payNow
      }),
    );
    if (r.statusCode >= 400) throw Exception(_safeMsg(r.body) ?? 'Error al reservar');
    return jsonDecode(r.body);
  }

  static Future<List<Map<String, dynamic>>> myAppointments() async {
    final r = await http.get(Uri.parse('$base/appointments/me'), headers: _headers());
    if (r.statusCode != 200) throw Exception('Error al cargar reservas');
    return List<Map<String, dynamic>>.from(jsonDecode(r.body));
  }

  static Future<void> markPaid(int id) async {
    final r = await http.post(Uri.parse('$base/appointments/$id/pay'), headers: _headers());
    if (r.statusCode != 200) throw Exception('No se pudo marcar pago');
  }

  static Future<void> cancel(int id) async {
    final r = await http.post(Uri.parse('$base/appointments/$id/cancel'), headers: _headers());
    if (r.statusCode != 200) throw Exception('No se pudo cancelar');
  }

  // Helper para extraer msg seguro
  static String? _safeMsg(String body) {
    try {
      final m = jsonDecode(body);
      if (m is Map && m['msg'] is String) return m['msg'] as String;
    } catch (_) {}
    return null;
  }
}
