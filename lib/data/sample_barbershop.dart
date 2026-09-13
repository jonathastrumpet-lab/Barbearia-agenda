import '../models/barbershop_models.dart';

const sampleBarbershop = BarbershopProfile(
  id: 'barbershop_demo',
  name: 'Barbearia Agenda',
  phone: '(27) 99999-9999',
  address: 'Endereço a definir',
  timeZone: 'America/Sao_Paulo',
);

const sampleServices = <BarbershopService>[
  BarbershopService(
    id: 'service_cut',
    barbershopId: 'barbershop_demo',
    name: 'Corte',
    durationMinutes: 45,
    priceCents: 4500,
  ),
  BarbershopService(
    id: 'service_beard',
    barbershopId: 'barbershop_demo',
    name: 'Barba',
    durationMinutes: 30,
    priceCents: 3500,
  ),
  BarbershopService(
    id: 'service_cut_beard',
    barbershopId: 'barbershop_demo',
    name: 'Corte + Barba',
    durationMinutes: 75,
    priceCents: 7000,
  ),
];

const sampleBarbers = <Barber>[
  Barber(
    id: 'barber_carlos',
    barbershopId: 'barbershop_demo',
    name: 'Carlos',
    serviceIds: ['service_cut', 'service_beard', 'service_cut_beard'],
  ),
  Barber(
    id: 'barber_rafael',
    barbershopId: 'barbershop_demo',
    name: 'Rafael',
    serviceIds: ['service_cut', 'service_beard', 'service_cut_beard'],
  ),
  Barber(
    id: 'barber_bruno',
    barbershopId: 'barbershop_demo',
    name: 'Bruno',
    serviceIds: ['service_cut', 'service_beard', 'service_cut_beard'],
  ),
];

final sampleWorkingHours = _buildWorkingHours();

List<BarberWorkingHours> _buildWorkingHours() {
  const barberIds = ['barber_carlos', 'barber_rafael', 'barber_bruno'];
  final items = <BarberWorkingHours>[];

  for (final barberId in barberIds) {
    // Monday to Friday: 09:00-19:00, lunch 12:00-13:30.
    for (var weekday = DateTime.monday; weekday <= DateTime.friday; weekday++) {
      items.add(
        BarberWorkingHours(
          id: '${barberId}_weekday_$weekday',
          barbershopId: 'barbershop_demo',
          barberId: barberId,
          weekday: weekday,
          startMinutes: 9 * 60,
          endMinutes: 19 * 60,
          breakStartMinutes: 12 * 60,
          breakEndMinutes: 13 * 60 + 30,
          slotIntervalMinutes: 30,
        ),
      );
    }

    // Saturday: 08:00-14:00, without a fixed break.
    items.add(
      BarberWorkingHours(
        id: '${barberId}_saturday',
        barbershopId: 'barbershop_demo',
        barberId: barberId,
        weekday: DateTime.saturday,
        startMinutes: 8 * 60,
        endMinutes: 14 * 60,
        slotIntervalMinutes: 30,
      ),
    );
  }

  return items;
}
