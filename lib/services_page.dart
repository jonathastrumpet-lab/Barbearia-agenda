import 'package:flutter/material.dart';

import 'service_store.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  static const _gold = Color(0xFFD7A84B);

  bool _loading = true;
  bool _saving = false;
  List<ServiceRecord> _services = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final services = await ServiceStore.loadAll();
      if (!mounted) return;
      setState(() {
        _services = services;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Não foi possível carregar os serviços.');
    }
  }

  Future<_ServiceFormResult?> _askService({ServiceRecord? service}) async {
    final name = TextEditingController(text: service?.name ?? '');
    final price = TextEditingController(
      text: service == null ? '' : service.price.toStringAsFixed(2).replaceAll('.', ','),
    );
    final duration = TextEditingController(
      text: service?.durationMinutes.toString() ?? '',
    );

    final result = await showDialog<_ServiceFormResult>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: Text(service == null ? 'Cadastrar serviço' : 'Editar serviço'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome do serviço'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  hintText: '60,00',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração em minutos',
                  hintText: '45',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final cleanName = name.text.trim();
              final parsedPrice = double.tryParse(price.text.trim().replaceAll(',', '.'));
              final parsedDuration = int.tryParse(duration.text.trim());
              if (cleanName.isEmpty ||
                  parsedPrice == null ||
                  parsedPrice < 0 ||
                  parsedDuration == null ||
                  parsedDuration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informe nome, valor e duração válidos.'),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                _ServiceFormResult(cleanName, parsedPrice, parsedDuration),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    name.dispose();
    price.dispose();
    duration.dispose();
    return result;
  }

  Future<void> _addService() async {
    if (_saving) return;
    final value = await _askService();
    if (value == null) return;
    setState(() => _saving = true);
    try {
      await ServiceStore.add(
        name: value.name,
        price: value.price,
        durationMinutes: value.durationMinutes,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${value.name} cadastrado com sucesso.')),
      );
    } catch (_) {
      if (mounted) _showError('Não foi possível cadastrar o serviço.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editService(ServiceRecord service) async {
    if (_saving) return;
    final value = await _askService(service: service);
    if (value == null) return;
    setState(() => _saving = true);
    try {
      await ServiceStore.update(
        id: service.id,
        name: value.name,
        price: value.price,
        durationMinutes: value.durationMinutes,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço atualizado com sucesso.')),
      );
    } catch (_) {
      if (mounted) _showError('Não foi possível editar o serviço.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setActive(ServiceRecord service, bool active) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ServiceStore.setActive(service.id, active);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            active
                ? '${service.name} reativado.'
                : '${service.name} desativado para novos agendamentos.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) _showError('Não foi possível alterar o status do serviço.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _addService,
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text(
          'NOVO SERVIÇO',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const Text(
              'Serviços',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre, edite valor e duração e escolha quais serviços ficam disponíveis para novos agendamentos.',
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),
            const SizedBox(height: 22),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_services.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.design_services_outlined, size: 44, color: Colors.white38),
                    SizedBox(height: 12),
                    Text(
                      'Nenhum serviço cadastrado',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Use “Novo serviço” para cadastrar o primeiro serviço.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              )
            else
              for (final service in _services) ...[
                _ServiceCard(
                  service: service,
                  disabled: _saving,
                  onEdit: () => _editService(service),
                  onActiveChanged: (value) => _setActive(service, value),
                ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.disabled,
    required this.onEdit,
    required this.onActiveChanged,
  });

  final ServiceRecord service;
  final bool disabled;
  final VoidCallback onEdit;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: service.active
              ? Colors.white10
              : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: service.active
                ? const Color(0xFF2B2418)
                : Colors.white10,
            child: Icon(
              Icons.design_services_rounded,
              color: service.active ? _ServicesPageState._gold : Colors.white38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: service.active ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.formattedPrice} • ${service.formattedDuration}',
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 4),
                Text(
                  service.active ? 'Ativo para agendamentos' : 'Desativado',
                  style: TextStyle(
                    color: service.active ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar serviço',
            onPressed: disabled ? null : onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          Switch(
            value: service.active,
            onChanged: disabled ? null : onActiveChanged,
            activeTrackColor: _ServicesPageState._gold,
          ),
        ],
      ),
    );
  }
}

class _ServiceFormResult {
  const _ServiceFormResult(this.name, this.price, this.durationMinutes);

  final String name;
  final double price;
  final int durationMinutes;
}
