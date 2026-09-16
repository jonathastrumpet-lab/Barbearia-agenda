import 'appointment_store.dart';

class BarberRecord {
  const BarberRecord({
    required this.id,
    required this.name,
    required this.active,
  });

  final String id;
  final String name;
  final bool active;

  factory BarberRecord.fromJson(Map<String, dynamic> json) => BarberRecord(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        active: json['active'] == true,
      );
}

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
        .select('id,name,active')
        .eq('barbershop_id', _shopId)
        .order('name');

    return (rows as List<dynamic>)
        .map((row) => BarberRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<BarberRecord>> loadActive() async {
    final rows = await AppointmentStore.client
        .from('barbers')
        .select('id,name,active')
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

    final row = await AppointmentStore.client
        .from('barbers')
        .insert({
          'barbershop_id': _shopId,
          'name': cleanName,
          'active': true,
        })
        .select('id,name,active')
        .single();

    return BarberRecord.fromJson(row);
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
}
