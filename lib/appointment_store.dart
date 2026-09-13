import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Map<String, dynamic> toCloudJson(String clientId) => {
        'id': id,
        'barbershop_id': AppointmentStore.shopId,
        'client_id': clientId,
        'service': service,
        'duration': duration,
        'price': price,
        'barber': barber,
        'date_iso': dateIso,
        'time': time,
        'created_at_iso': createdAtIso,
        'status': 'scheduled',
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
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const shopId = String.fromEnvironment(
    'BARBERSHOP_ID',
    defaultValue: 'barbearia-demo',
  );

  static bool _cloudReady = false;
  static bool get cloudEnabled => _cloudReady;

  static Future<void> initializeCloud() async {
    if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) return;

    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabasePublishableKey,
      );

      final auth = Supabase.instance.client.auth;
      if (auth.currentSession == null) {
        await auth.signInAnonymously();
      }

      _cloudReady = auth.currentUser != null;
    } catch (_) {
      _cloudReady = false;
    }
  }

  static Future<List<Appointment>> load() async {
    if (cloudEnabled) {
      try {
        final remote = await _loadRemote();
        await _save(remote);
        return remote;
      } catch (_) {
        // Usa a última cópia local quando a nuvem estiver temporariamente
        // indisponível.
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

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<Appointment>> _loadRemote() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sessão Supabase não autenticada.');

    final rows = await _client
        .from('appointments')
        .select(
          'id,service,duration,price,barber,date_iso,time,created_at_iso',
        )
        .eq('barbershop_id', shopId)
        .eq('client_id', user.id)
        .eq('status', 'scheduled')
        .order('date_iso')
        .order('time');

    final items = (rows as List<dynamic>)
        .map((item) =>
            Appointment.fromCloudJson(item as Map<String, dynamic>))
        .toList();
    items.sort(_compareAppointments);
    return items;
  }

  static Future<void> _addRemote(Appointment appointment) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sessão Supabase não autenticada.');

    try {
      await _client
          .from('appointments')
          .insert(appointment.toCloudJson(user.id));
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const AppointmentConflictException();
      }
      rethrow;
    }
  }

  static Future<void> _removeRemote(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sessão Supabase não autenticada.');

    await _client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', id)
        .eq('client_id', user.id);
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
