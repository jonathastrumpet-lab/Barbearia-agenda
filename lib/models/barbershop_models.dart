class BarbershopProfile {
  const BarbershopProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.timeZone,
    this.active = true,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final String timeZone;
  final bool active;
}

class BarbershopService {
  const BarbershopService({
    required this.id,
    required this.barbershopId,
    required this.name,
    required this.durationMinutes,
    required this.priceCents,
    this.active = true,
  });

  final String id;
  final String barbershopId;
  final String name;
  final int durationMinutes;
  final int priceCents;
  final bool active;

  String get durationLabel {
    if (durationMinutes < 60) return '$durationMinutes min';
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes} min';
  }

  String get priceLabel => 'R\$ ${(priceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
}

class Barber {
  const Barber({
    required this.id,
    required this.barbershopId,
    required this.name,
    required this.serviceIds,
    this.active = true,
  });

  final String id;
  final String barbershopId;
  final String name;
  final List<String> serviceIds;
  final bool active;

  bool canPerform(String serviceId) => serviceIds.contains(serviceId);
}

class BarberWorkingHours {
  const BarberWorkingHours({
    required this.id,
    required this.barbershopId,
    required this.barberId,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.breakStartMinutes,
    this.breakEndMinutes,
    this.slotIntervalMinutes = 30,
    this.active = true,
  });

  final String id;
  final String barbershopId;
  final String barberId;

  /// DateTime.weekday: 1 = Monday ... 7 = Sunday.
  final int weekday;

  /// Minutes after midnight. Example: 9:00 = 540.
  final int startMinutes;
  final int endMinutes;
  final int? breakStartMinutes;
  final int? breakEndMinutes;
  final int slotIntervalMinutes;
  final bool active;

  List<String> generateStartTimes({required int serviceDurationMinutes}) {
    if (!active || slotIntervalMinutes <= 0 || serviceDurationMinutes <= 0) {
      return const [];
    }

    final times = <String>[];
    for (
      var start = startMinutes;
      start + serviceDurationMinutes <= endMinutes;
      start += slotIntervalMinutes
    ) {
      final end = start + serviceDurationMinutes;
      final breakStart = breakStartMinutes;
      final breakEnd = breakEndMinutes;
      final overlapsBreak = breakStart != null &&
          breakEnd != null &&
          start < breakEnd &&
          end > breakStart;

      if (!overlapsBreak) times.add(_minutesToTime(start));
    }
    return times;
  }

  static String _minutesToTime(int totalMinutes) {
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class AppointmentDraft {
  const AppointmentDraft({
    required this.barbershopId,
    required this.serviceId,
    required this.barberId,
    required this.date,
    required this.startTime,
  });

  final String barbershopId;
  final String serviceId;
  final String barberId;
  final DateTime date;
  final String startTime;
}
