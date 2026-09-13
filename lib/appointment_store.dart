import 'dart:convert';

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
}

class AppointmentStore {
  AppointmentStore._();

  static const _key = 'appointments_v1';

  static Future<List<Appointment>> load() async {
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

  static Future<void> add(Appointment appointment) async {
    final items = await load();
    items.add(appointment);
    items.sort(_compareAppointments);
    await _save(items);
  }

  static Future<void> remove(String id) async {
    final items = await load();
    items.removeWhere((item) => item.id == id);
    await _save(items);
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
