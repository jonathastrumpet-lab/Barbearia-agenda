import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  // Os valores abaixo sao publicos no app cliente e funcionam como fallback.
  // O GitHub Actions ainda pode sobrescreve-los via --dart-define.
  static const _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://drvaacngbtnjxdeakgnn.supabase.co',
  );
  static const _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_FAPJ5-5m7nnvXP18vw85yQ_QuVAjum8',
  );
  static const shopId = String.fromEnvironment(
    'BARBERSHOP_ID',
    defaultValue: 'b77fd4c8-d303-42d0-9489-a88ae8a131c9',
  );

  static bool _cloudReady = false;
  static String? _cloudError;

  static bool get cloudEnabled => _cloudReady;
  static String? get cloudError => _cloudError;

  static Future<void> initializeCloud() async {
    _cloudReady = false;
    _cloudError = null;

    if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
      _cloudError = 'Configuracao do Supabase ausente no APK.';
      debugPrint('[Supabase] $_cloudError');
      return;
    }

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
      if (!_cloudReady) {
        _cloudError = 'Supabase inicializou, mas nao criou sessao anonima.';
      }

      debugPrint(
        '[Supabase] cloudReady=$_cloudReady user=${auth.currentUser?.id} shop=$shopId',
      );
    } catch (error, stackTrace) {
      _cloudReady = false;
      _cloudError = error.toString();
      debugPrint('[Supabase] Falha ao inicializar/autenticar: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<List<Appointment>> load() async {
    if (cloudEnabled) {
      try {
        final remote = await _loadRemote();
        await _save(remote);
        return remote;
      } catch (error, stackTrace) {
        _cloudError = error.toString();
        debugPrint('[Supabase] Falha ao carregar agenda: $error');
        debugPrintStack(stackTrace: stackTrace);
        // Usa a ultima copia local quando a nuvem estiver temporariamente
        // indisponivel.
      }
    }
    return _loadLocal();
  }

  static Future<void> add(Appointment appointment) async {
    if (cloudEnabled) {
      try {
        await _addRemote(appointment);
        _cloudError = null;
      } catch (error, stackTrace) {
        _cloudError = error.toString();
        debugPrint('[Supabase] Falha ao inserir agendamento: $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
    } else {
      debugPrint(
        '[Supabase] Salvando somente local. Motivo: ${_cloudError ?? 'nuvem nao inicializada'}',
      );
    }

    final items = await _loadLocal();
    items.removeWhere((item) => item.id == appointment.id);
    items.add(appointment);
    items.sort(_compareAppointments);
    await _save(items);
  }

  static Future<void> remove(String id) async {
    if (cloudEnabled) {
      try {
        await _removeRemote(id);
        _cloudError = null;
      } catch (error, stackTrace) {
        _cloudError = error.toString();
        debugPrint('[Supabase] Falha ao cancelar agendamento: $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
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
    if (user == null) throw StateError('Sessao Supabase nao autenticada.');

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
    if (user == null) throw StateError('Sessao Supabase nao autenticada.');

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
    if (user == null) throw StateError('Sessao Supabase nao autenticada.');

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
