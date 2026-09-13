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

## 4. Modelos de horário da barbearia

O sistema oferece modelos prontos somente como ponto de partida. Depois de escolher um modelo, a barbearia pode alterar qualquer campo.

Modelos iniciais:

### Padrão comercial
- Segunda a sexta: 09:00 às 19:00
- Intervalo: 12:00 às 13:30
- Sábado: 08:00 às 14:00
- Domingo: fechado

### Abre cedo
- Segunda a sexta: 08:00 às 19:00
- Intervalo inicial sugerido: 12:00 às 13:00
- Sábado: 08:00 às 16:00
- Domingo: fechado

### Sem intervalo
- Segunda a sexta: 09:00 às 19:00
- Sábado: 08:00 às 16:00
- Sem parada fixa para almoço

### Personalizado
- Todos os dias começam desativados
- A barbearia configura dias, abertura, fechamento e intervalos do zero

Campos configuráveis por dia:
- `weekday`
- `enabled`
- `startMinutes`
- `endMinutes`
- `breakEnabled`
- `breakStartMinutes`
- `breakEndMinutes`

Configuração geral:
- `templateId`
- `slotIntervalMinutes`

O modelo escolhido nunca deve bloquear edições posteriores.

## 5. Exceções por barbeiro

Cada barbeiro pode usar o horário geral da barbearia ou ter uma exceção própria.

Coleção/tabela sugerida: `barber_schedule_exceptions`

Campos principais:
- `id`
- `barbershopId`
- `barberId`
- `weekday` para regra recorrente opcional
- `date` para uma exceção pontual opcional
- `closed`
- `startMinutes`
- `endMinutes`
- `breakEnabled`
- `breakStartMinutes`
- `breakEndMinutes`

Exemplos:
- Carlos usa o horário geral da barbearia.
- Rafael entra toda terça às 10:00.
- Bruno não trabalha em uma data específica.
- Um barbeiro pode trabalhar sem intervalo mesmo que a barbearia tenha intervalo padrão.

Ordem de prioridade:

`exceção do barbeiro na data` > `exceção recorrente do barbeiro` > `horário geral da barbearia`

## 6. Horários disponíveis

Os horários disponíveis não devem ser gravados como uma lista fixa. Eles devem ser calculados a partir da configuração efetiva do dia.

Regra principal:

`horário configurado` - `intervalos` - `bloqueios` - `agendamentos confirmados` = `horários disponíveis`

A duração do serviço também participa do cálculo. Um serviço só pode ser oferecido se terminar antes do fechamento ou antes do início de um intervalo/bloqueio.

## 7. Agendamentos

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

Na integração com o banco, a confirmação deve ser feita de forma atômica/transacional para impedir que dois clientes reservem o mesmo barbeiro no mesmo horário.

## 8. Arquivos atuais do projeto

- `lib/models/barbershop_models.dart`: modelos principais de barbearia, serviços, barbeiros, horários, agenda e exceções.
- `lib/data/schedule_templates.dart`: modelos prontos de horário.
- `lib/data/sample_barbershop.dart`: dados de demonstração atuais.

Os dados de demonstração serão substituídos pelos dados configurados pela própria barbearia quando criarmos a tela de administração e o banco em nuvem.
