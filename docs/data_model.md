# Modelo inicial da Barbearia Agenda

Este modelo foi preparado antes da integração com o banco em nuvem para evitar retrabalho na estrutura dos dados.

## 1. Barbearia

Coleção/tabela sugerida: `barbershops`

Campos principais:
- `id`
- `name`
- `phone`
- `address`
- `timeZone`
- `active`

No futuro podem ser adicionados logo, descrição, redes sociais, formas de pagamento e configurações de cancelamento.

## 2. Serviços

Coleção/tabela sugerida: `services`

Campos principais:
- `id`
- `barbershopId`
- `name`
- `durationMinutes`
- `priceCents`
- `active`

O preço deve ser salvo em centavos para evitar problemas de arredondamento. Exemplo: R$ 45,00 = `4500`.

## 3. Barbeiros

Coleção/tabela sugerida: `barbers`

Campos principais:
- `id`
- `barbershopId`
- `name`
- `serviceIds`
- `active`

`serviceIds` define quais serviços cada profissional pode executar.

## 4. Horários de trabalho

Coleção/tabela sugerida: `working_hours`

Campos principais:
- `id`
- `barbershopId`
- `barberId`
- `weekday`
- `startMinutes`
- `endMinutes`
- `breakStartMinutes`
- `breakEndMinutes`
- `slotIntervalMinutes`
- `active`

Os horários disponíveis não devem ser gravados como uma lista fixa. Eles devem ser calculados a partir da jornada do barbeiro, duração do serviço, intervalo e agendamentos já ocupados.

Exemplo:
- barbeiro: Carlos
- terça-feira: 09:00 às 19:00
- almoço: 12:00 às 13:30
- intervalo entre inícios: 30 minutos
- serviço: Corte, 45 minutos

O app gera os possíveis horários de início e depois remove os que conflitam com almoço, bloqueios ou agendamentos existentes.

## 5. Agendamentos

Coleção/tabela sugerida: `appointments`

Estrutura alvo para a etapa de nuvem:
- `id`
- `barbershopId`
- `customerId`
- `serviceId`
- `barberId`
- `date`
- `startTime`
- `endTime`
- `priceCents`
- `status` (`confirmed`, `cancelled`, `completed`, `noShow`)
- `createdAt`

O agendamento deve guardar IDs, e não somente os nomes visíveis. Isso permite alterar nome do serviço ou barbeiro sem perder o vínculo histórico.

## 6. Disponibilidade

Regra principal:

`horários de trabalho do barbeiro` - `intervalos` - `bloqueios` - `agendamentos confirmados` = `horários disponíveis`

Na integração com o banco, a confirmação deve ser feita de forma atômica/transacional para impedir que dois clientes reservem o mesmo barbeiro no mesmo horário.

## 7. Dados de demonstração atuais

Enquanto não existe banco em nuvem, o projeto usa dados locais de exemplo:
- Serviços: Corte, Barba e Corte + Barba
- Barbeiros: Carlos, Rafael e Bruno
- Segunda a sexta: 09:00 às 19:00, intervalo 12:00 às 13:30
- Sábado: 08:00 às 14:00
- Domingo: fechado

Esses dados estão em `lib/data/sample_barbershop.dart` e podem ser trocados depois pelos dados reais da primeira barbearia.
