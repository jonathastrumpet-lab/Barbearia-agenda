import 'appointment_store.dart';

class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.active,
  });

  final String id;
  final String name;
  final double price;
  final int durationMinutes;
  final bool active;

  String get formattedPrice => 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  factory ServiceRecord.fromJson(Map<String, dynamic> json) => ServiceRecord(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
        active: json['active'] == true,
      );
}

class ServiceStore {
  ServiceStore._();

  static String get _shopId {
    final shop = AppointmentStore.shopId;
    if (shop == null || shop.isEmpty) {
      throw StateError('Estabelecimento não selecionado.');
    }
    return shop;
  }

  static Future<List<ServiceRecord>> loadAll() async {
    final rows = await AppointmentStore.client
        .from('services')
        .select('id,name,price,duration_minutes,active')
        .eq('barbershop_id', _shopId)
        .order('name');

    return (rows as List<dynamic>)
        .map((row) => ServiceRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ServiceRecord>> loadActive() async {
    final rows = await AppointmentStore.client
        .from('services')
        .select('id,name,price,duration_minutes,active')
        .eq('barbershop_id', _shopId)
        .eq('active', true)
        .order('name');

    return (rows as List<dynamic>)
        .map((row) => ServiceRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<ServiceRecord> add({
    required String name,
    required double price,
    required int durationMinutes,
  }) async {
    _validate(name, price, durationMinutes);
    final row = await AppointmentStore.client
        .from('services')
        .insert({
          'barbershop_id': _shopId,
          'name': name.trim(),
          'price': price,
          'duration_minutes': durationMinutes,
          'active': true,
        })
        .select('id,name,price,duration_minutes,active')
        .single();
    return ServiceRecord.fromJson(row);
  }

  static Future<void> update({
    required String id,
    required String name,
    required double price,
    required int durationMinutes,
  }) async {
    _validate(name, price, durationMinutes);
    await AppointmentStore.client
        .from('services')
        .update({
          'name': name.trim(),
          'price': price,
          'duration_minutes': durationMinutes,
        })
        .eq('id', id)
        .eq('barbershop_id', _shopId);
  }

  static Future<void> setActive(String id, bool active) async {
    await AppointmentStore.client
        .from('services')
        .update({'active': active})
        .eq('id', id)
        .eq('barbershop_id', _shopId);
  }

  static void _validate(String name, double price, int durationMinutes) {
    if (name.trim().isEmpty) throw ArgumentError('Informe o nome do serviço.');
    if (price < 0) throw ArgumentError('Informe um valor válido.');
    if (durationMinutes <= 0) throw ArgumentError('Informe uma duração válida.');
  }
}
