import 'appointment_store.dart';

class BarberRecord {
  const BarberRecord({
    required this.id,
    required this.name,
    required this.active,
    this.usesCustomSchedule = false,
  });

  final String id;
  final String name;
  final bool active;
  final bool usesCustomSchedule;

  factory BarberRecord.fromJson(Map<String, dynamic> json) => BarberRecord(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        active: json['active'] == true,
        usesCustomSchedule: json['uses_custom_schedule'] == true,
      );
}

class ProfessionalPlanLimitException implements Exception { const ProfessionalPlanLimitException(); }

class BarberStore {
  BarberStore._();

  static String get _shopId {
    final shop = AppointmentStore.shopId;
    if (shop == null || shop.isEmpty) {
      throw StateError('Estabelecimento não selecionado.');
    }
    return shop;
  }

  static Future<List<BarberRecord>> loadAll() async {
    final rows = await AppointmentStore.client
        .from('barbers')
        .select('id,name,active,uses_custom_schedule')
        .eq('barbershop_id', _shopId)
        .order('name');

    return (rows as List<dynamic>)
        .map((row) => BarberRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<BarberRecord>> loadActive() async {
    final rows = await AppointmentStore.client
        .from('barbers')
        .select('id,name,active,uses_custom_schedule')
        .eq('barbershop_id', _shopId)
        .eq('active', true)
        .order('name');

    return (rows as List<dynamic>)
        .map((row) => BarberRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<BarberRecord> add(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome do profissional.');

    try {
    final row = await AppointmentStore.client
        .from('barbers')
        .insert({
          'barbershop_id': _shopId,
          'name': cleanName,
          'active': true,
          'uses_custom_schedule': false,
        })
        .select('id,name,active,uses_custom_schedule')
        .single();

    return BarberRecord.fromJson(row);
    } catch (e) {
      if (e.toString().contains('professional_plan_limit_reached')) {
        throw const ProfessionalPlanLimitException();
      }
      rethrow;
    }
  }

  static Future<void> rename(String id, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Informe o nome do profissional.');

    await AppointmentStore.client
        .from('barbers')
        .update({'name': cleanName})
        .eq('id', id)
        .eq('barbershop_id', _shopId);
  }

  static Future<void> setActive(String id, bool active) async {
    await AppointmentStore.client
        .from('barbers')
        .update({'active': active})
        .eq('id', id)
        .eq('barbershop_id', _shopId);
  }

  static Future<void> setUsesCustomSchedule(String id, bool enabled) async {
    await AppointmentStore.client
        .from('barbers')
        .update({'uses_custom_schedule': enabled})
        .eq('id', id)
        .eq('barbershop_id', _shopId);
  }
}
