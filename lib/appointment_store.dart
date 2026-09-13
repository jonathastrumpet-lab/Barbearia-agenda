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

  Map<String, dynamic> toCloudJson(String clientId) {
    final shop = AppointmentStore.shopId;
    if (shop == null) {
      throw StateError('Usuario sem estabelecimento vinculado.');
    }
    return {
      'id': id,
      'barbershop_id': shop,
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
  }

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
  static const _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://drvaacngbtnjxdeakgnn.supabase.co',
  );
  static const _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_FAPJ5-5m7nnvXP18vw85yQ_QuVAjum8',
  );

  static bool _cloudReady = false;
  static String? _cloudError;
  static String? _shopId;
  static String? _memberRole;

  static bool get cloudEnabled => _cloudReady;
  static String? get cloudError => _cloudError;
  static String? get shopId => _shopId;
  static String? get memberRole => _memberRole;
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static bool get signedIn => currentUser != null && currentUser!.isAnonymous != true;
  static bool get hasShop => _shopId != null;

  static Future<void> initializeCloud() async {
    _cloudReady = false;
    _cloudError = null;
    _shopId = null;
    _memberRole = null;

    if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
      _cloudError = 'Configuracao do Supabase ausente no APK.';
      return;
    }

    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabasePublishableKey,
      );

      // Builds anteriores criavam uma sessao anonima. Ao atualizar o APK,
      // encerramos essa sessao para obrigar o login permanente.
      if (client.auth.currentUser?.isAnonymous == true) {
        await client.auth.signOut();
      }

      if (client.auth.currentUser != null) {
        await refreshMembership();
      } else {
        _cloudError = 'Entre com o login da barbearia.';
      }
    } catch (error, stackTrace) {
      _cloudReady = false;
      _cloudError = error.toString();
      debugPrint('[Supabase] Falha ao inicializar: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> signIn(String email, String password) async {
    _cloudReady = false;
    _cloudError = null;
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await refreshMembership();
  }

  static Future<bool> signUp(String email, String password) async {
    _cloudReady = false;
    _cloudError = null;
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    if (response.session != null) {
      await refreshMembership();
      return true;
    }
    _cloudError = 'Confirme seu e-mail e depois faca login.';
    return false;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
    _cloudReady = false;
    _shopId = null;
    _memberRole = null;
    _cloudError = 'Entre com o login da barbearia.';
  }

  static Future<void> refreshMembership() async {
    final user = client.auth.currentUser;
    _cloudReady = false;
    _shopId = null;
    _memberRole = null;

    if (user == null || user.isAnonymous == true) {
      _cloudError = 'Login permanente necessario.';
      return;
    }

    final rows = await client
        .from('barbershop_members')
        .select('barbershop_id,role')
        .eq('user_id', user.id)
        .limit(1);

    final list = rows as List<dynamic>;
    if (list.isEmpty) {
      _cloudError = 'Conta sem estabelecimento vinculado.';
      return;
    }

    final row = list.first as Map<String, dynamic>;
    _shopId = row['barbershop_id'] as String;
    _memberRole = row['role'] as String?;
    _cloudReady = true;
    _cloudError = null;
  }

  static Future<void> claimOwnerAccess(String inviteCode) async {
    if (!signedIn) throw StateError('Faca login primeiro.');
    await client.rpc(
      'claim_barbershop_owner',
      params: {'invite_code': inviteCode.trim()},
    );
    await refreshMembership();
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
      }
    }
    return _loadLocal();
  }

  static Future<void> add(Appointment appointment) async {
    if (!cloudEnabled) {
      throw StateError(_cloudError ?? 'Agenda na nuvem indisponivel.');
    }

    try {
      await _addRemote(appointment);
      _cloudError = null;
    } catch (error, stackTrace) {
      _cloudError = error.toString();
      debugPrint('[Supabase] Falha ao inserir agendamento: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }

    final items = await _loadLocal();
    items.removeWhere((item) => item.id == appointment.id);
    items.add(appointment);
    items.sort(_compareAppointments);
    await _save(items);
  }

  static Future<void> remove(String id) async {
    if (!cloudEnabled) {
      throw StateError(_cloudError ?? 'Agenda na nuvem indisponivel.');
    }

    try {
      await _removeRemote(id);
      _cloudError = null;
    } catch (error, stackTrace) {
      _cloudError = error.toString();
      debugPrint('[Supabase] Falha ao cancelar agendamento: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
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
    final user = client.auth.currentUser;
    final shop = shopId;
    if (user == null) throw StateError('Sessao Supabase nao autenticada.');
    if (shop == null) throw StateError('Estabelecimento nao vinculado.');

    final rows = await client
        .from('appointments')
        .select('id,service,duration,price,barber,date_iso,time,created_at_iso')
        .eq('barbershop_id', shop)
        .eq('status', 'scheduled')
        .order('date_iso')
        .order('time');

    final items = (rows as List<dynamic>)
        .map((item) => Appointment.fromCloudJson(item as Map<String, dynamic>))
        .toList();
    items.sort(_compareAppointments);
    return items;
  }

  static Future<void> _addRemote(Appointment appointment) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Sessao Supabase nao autenticada.');

    try {
      await client.from('appointments').insert(appointment.toCloudJson(user.id));
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const AppointmentConflictException();
      }
      rethrow;
    }
  }

  static Future<void> _removeRemote(String id) async {
    final shop = shopId;
    if (client.auth.currentUser == null) {
      throw StateError('Sessao Supabase nao autenticada.');
    }
    if (shop == null) throw StateError('Estabelecimento nao vinculado.');

    await client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', id)
        .eq('barbershop_id', shop);
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
