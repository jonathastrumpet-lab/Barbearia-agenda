import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.service,
    required this.duration,
    required this.price,
    required this.barber,
    required this.dateIso,
    required this.time,
    required this.createdAtIso,
  });

  final String id;
  final String service;
  final String duration;
  final String price;
  final String barber;
  final String dateIso;
  final String time;
  final String createdAtIso;

  DateTime get date => DateTime.parse(dateIso);

  Map<String, dynamic> toJson() => {
        'id': id,
        'service': service,
        'duration': duration,
        'price': price,
        'barber': barber,
        'dateIso': dateIso,
        'time': time,
        'createdAtIso': createdAtIso,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        service: json['service'] as String,
        duration: json['duration'] as String,
        price: json['price'] as String,
        barber: json['barber'] as String,
        dateIso: json['dateIso'] as String,
        time: json['time'] as String,
        createdAtIso: json['createdAtIso'] as String,
      );

  Map<String, dynamic> toCloudJson() => {
        'id': id,
        'shop_id': AppointmentStore.shopId,
        'service': service,
        'duration': duration,
        'price': price,
        'barber': barber,
        'date_iso': dateIso,
        'time': time,
        'created_at_iso': createdAtIso,
        'status': 'active',
      };

  factory Appointment.fromCloudJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        service: json['service'] as String,
        duration: json['duration'] as String,
        price: json['price'] as String,
        barber: json['barber'] as String,
        dateIso: json['date_iso'] as String,
        time: json['time'] as String,
        createdAtIso: json['created_at_iso'] as String,
      );
}

class AppointmentConflictException implements Exception {
  const AppointmentConflictException();
}

class AppointmentStore {
  AppointmentStore._();

  static const _key = 'appointments_v1';

  // A sincronização fica desativada enquanto estes valores não forem
  // fornecidos no build com --dart-define. Isso mantém o APK atual funcionando
  // localmente e evita colocar credenciais no repositório.
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const shopId = String.fromEnvironment(
    'BARBERSHOP_ID',
    defaultValue: 'barbearia-demo',
  );

  static bool get cloudEnabled =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  static Future<List<Appointment>> load() async {
    if (cloudEnabled) {
      try {
        final remote = await _loadRemote();
        await _save(remote);
        return remote;
      } catch (_) {
        // Se a internet estiver indisponível, a última cópia local continua
        // acessível. Quando a conexão voltar, a próxima leitura sincroniza.
      }
    }
    return _loadLocal();
  }

  static Future<void> add(Appointment appointment) async {
    if (cloudEnabled) {
      await _addRemote(appointment);
    }

    final items = await _loadLocal();
    items.removeWhere((item) => item.id == appointment.id);
    items.add(appointment);
    items.sort(_compareAppointments);
    await _save(items);
  }

  static Future<void> remove(String id) async {
    if (cloudEnabled) {
      await _removeRemote(id);
    }

    final items = await _loadLocal();
    items.removeWhere((item) => item.id == id);
    await _save(items);
  }

  static Future<List<Appointment>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
          .toList();
      items.sort(_compareAppointments);
      return items;
    } catch (_) {
      return [];
    }
  }

  static Future<List<Appointment>> _loadRemote() async {
    final uri = Uri.parse(
      '$_supabaseUrl/rest/v1/appointments'
      '?shop_id=eq.${Uri.encodeQueryComponent(shopId)}'
      '&status=eq.active'
      '&select=id,service,duration,price,barber,date_iso,time,created_at_iso'
      '&order=date_iso.asc,time.asc',
    );
    final response = await _request('GET', uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Falha ao sincronizar agenda (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final items = decoded
        .map((item) =>
            Appointment.fromCloudJson(item as Map<String, dynamic>))
        .toList();
    items.sort(_compareAppointments);
    return items;
  }

  static Future<void> _addRemote(Appointment appointment) async {
    final uri = Uri.parse('$_supabaseUrl/rest/v1/appointments');
    final response = await _request(
      'POST',
      uri,
      body: jsonEncode(appointment.toCloudJson()),
      extraHeaders: const {'Prefer': 'return=minimal'},
    );

    if (response.statusCode == 409) {
      throw const AppointmentConflictException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Falha ao salvar na nuvem (${response.statusCode})');
    }
  }

  static Future<void> _removeRemote(String id) async {
    final uri = Uri.parse(
      '$_supabaseUrl/rest/v1/appointments?id=eq.${Uri.encodeQueryComponent(id)}',
    );
    final response = await _request(
      'DELETE',
      uri,
      extraHeaders: const {'Prefer': 'return=minimal'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Falha ao cancelar na nuvem (${response.statusCode})');
    }
  }

  static Future<_HttpResult> _request(
    String method,
    Uri uri, {
    String? body,
    Map<String, String> extraHeaders = const {},
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      request.headers.set('apikey', _supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer $_supabaseAnonKey');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      extraHeaders.forEach(request.headers.set);
      if (body != null) request.write(body);

      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      return _HttpResult(response.statusCode, responseBody);
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _save(List<Appointment> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static int _compareAppointments(Appointment a, Appointment b) {
    DateTime value(Appointment item) {
      final parts = item.time.split(':');
      return DateTime(
        item.date.year,
        item.date.month,
        item.date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    return value(a).compareTo(value(b));
  }
}

class _HttpResult {
  const _HttpResult(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
