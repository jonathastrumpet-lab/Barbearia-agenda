import 'dart:async';

import 'package:flutter/material.dart';

import 'appointment_store.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _register = false;
  String? _message;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _barbershopName = TextEditingController();
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = AppointmentStore.client.auth.onAuthStateChange.listen((_) {
      if (mounted) _refresh();
    });
    _refresh();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _barbershopName.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      if (AppointmentStore.signedIn) {
        await AppointmentStore.refreshMembership();
        if (!AppointmentStore.hasShop) {
          await _provisionAdminIfNeeded();
        }
      }
    } catch (e) {
      _message = _friendlyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _provisionAdminIfNeeded() async {
    final user = AppointmentStore.currentUser;
    if (user == null || AppointmentStore.hasShop) return;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    if (metadata['account_type'] != 'barbershop_admin') return;

    final shopName = (metadata['barbershop_name'] as String?)?.trim() ?? '';
    if (shopName.length < 2) {
      throw StateError('Nome da barbearia ausente no cadastro.');
    }

    await AppointmentStore.client.rpc(
      'bootstrap_barbershop_admin',
      params: {'p_barbershop_name': shopName},
    );
    await AppointmentStore.refreshMembership();
  }

  Future<void> _submitAuth() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.length < 6) {
      setState(() => _message = 'Informe um e-mail valido e senha com pelo menos 6 caracteres.');
      return;
    }

    if (_register &&
        (_fullName.text.trim().length < 2 || _barbershopName.text.trim().length < 2)) {
      setState(() => _message = 'Informe seu nome e o nome da barbearia.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      if (_register) {
        final response = await AppointmentStore.client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'com.barbeariaagenda.app://login-callback',
          data: {
            'full_name': _fullName.text.trim(),
            'barbershop_name': _barbershopName.text.trim(),
            'account_type': 'barbershop_admin',
          },
        );

        if (response.session != null) {
          await _refresh();
        } else {
          _message = 'Conta criada. Enviamos um e-mail de confirmacao. Toque no link para concluir o cadastro.';
        }
      } else {
        await AppointmentStore.signIn(email, password);
        if (!AppointmentStore.hasShop) {
          await _provisionAdminIfNeeded();
        }
      }
    } catch (e) {
      _message = _friendlyError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('Invalid login credentials')) return 'E-mail ou senha incorretos.';
    if (text.contains('Email not confirmed')) return 'Confirme seu e-mail antes de entrar.';
    if (text.contains('already registered')) return 'Este e-mail ja possui cadastro.';
    if (text.contains('Email confirmation required')) return 'Confirme seu e-mail antes de continuar.';
    if (text.contains('Authentication required')) return 'Sessao expirada. Entre novamente.';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!AppointmentStore.signedIn) {
      return _LoginPage(
        register: _register,
        email: _email,
        password: _password,
        fullName: _fullName,
        barbershopName: _barbershopName,
        message: _message,
        onSubmit: _submitAuth,
        onToggle: () => setState(() {
          _register = !_register;
          _message = null;
        }),
      );
    }

    if (!AppointmentStore.hasShop) {
      return _ProvisioningPage(
        email: AppointmentStore.currentUser?.email ?? 'Conta autenticada',
        message: _message ?? AppointmentStore.cloudError,
        onRetry: _refresh,
        onLogout: () async {
          await AppointmentStore.signOut();
          if (mounted) setState(() {});
        },
      );
    }

    return widget.child;
  }
}

class _LoginPage extends StatelessWidget {
  const _LoginPage({
    required this.register,
    required this.email,
    required this.password,
    required this.fullName,
    required this.barbershopName,
    required this.message,
    required this.onSubmit,
    required this.onToggle,
  });

  final bool register;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController fullName;
  final TextEditingController barbershopName;
  final String? message;
  final VoidCallback onSubmit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.content_cut_rounded, size: 58, color: Color(0xFFD7A84B)),
                  const SizedBox(height: 18),
                  Text(
                    register ? 'Criar conta da barbearia' : 'Entrar na Barbearia Agenda',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    register
                        ? 'Cadastre o administrador. A barbearia sera criada automaticamente apos a confirmacao do e-mail.'
                        : 'Acesse somente os dados do seu estabelecimento.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 28),
                  if (register) ...[
                    TextField(
                      controller: fullName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Seu nome',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: barbershopName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome da barbearia',
                        prefixIcon: Icon(Icons.storefront_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 14),
                    Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.amberAccent)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD7A84B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(register ? 'CRIAR CONTA' : 'ENTRAR', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  TextButton(
                    onPressed: onToggle,
                    child: Text(register ? 'Ja tenho conta' : 'Criar conta da barbearia'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProvisioningPage extends StatelessWidget {
  const _ProvisioningPage({
    required this.email,
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String email;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.storefront_outlined, size: 58, color: Color(0xFFD7A84B)),
                  const SizedBox(height: 18),
                  const Text('Configurando sua barbearia', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(email, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 24),
                  Text(
                    message ?? 'Aguarde enquanto concluimos seu cadastro.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.amberAccent),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD7A84B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('TENTAR NOVAMENTE', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  TextButton(onPressed: onLogout, child: const Text('Sair desta conta')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
