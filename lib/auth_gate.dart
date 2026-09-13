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
  final _invite = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      if (AppointmentStore.signedIn) {
        await AppointmentStore.refreshMembership();
      }
    } catch (e) {
      _message = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submitAuth() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _message = 'Informe um e-mail valido e senha com pelo menos 6 caracteres.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      if (_register) {
        final active = await AppointmentStore.signUp(_email.text, _password.text);
        _message = active
            ? 'Conta criada. Agora vincule esta conta a barbearia.'
            : AppointmentStore.cloudError;
      } else {
        await AppointmentStore.signIn(_email.text, _password.text);
      }
    } catch (e) {
      _message = _friendlyError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _claimShop() async {
    if (_invite.text.trim().isEmpty) {
      setState(() => _message = 'Digite o codigo de ativacao da barbearia.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await AppointmentStore.claimOwnerAccess(_invite.text);
      _message = 'Barbearia vinculada com sucesso.';
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
    if (text.contains('Invalid or already used invite code')) {
      return 'Codigo invalido ou ja utilizado.';
    }
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
        message: _message,
        onSubmit: _submitAuth,
        onToggle: () => setState(() {
          _register = !_register;
          _message = null;
        }),
      );
    }

    if (!AppointmentStore.hasShop) {
      return _MembershipPage(
        email: AppointmentStore.currentUser?.email ?? 'Conta autenticada',
        invite: _invite,
        message: _message ?? AppointmentStore.cloudError,
        onClaim: _claimShop,
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
    required this.message,
    required this.onSubmit,
    required this.onToggle,
  });

  final bool register;
  final TextEditingController email;
  final TextEditingController password;
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
                    register ? 'Criar login da barbearia' : 'Entrar na Barbearia Agenda',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    register
                        ? 'Use uma conta permanente para proteger a agenda.'
                        : 'Acesse somente os dados do seu estabelecimento.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 28),
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

class _MembershipPage extends StatelessWidget {
  const _MembershipPage({
    required this.email,
    required this.invite,
    required this.message,
    required this.onClaim,
    required this.onLogout,
  });

  final String email;
  final TextEditingController invite;
  final String? message;
  final VoidCallback onClaim;
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
                  const Icon(Icons.verified_user_outlined, size: 58, color: Color(0xFFD7A84B)),
                  const SizedBox(height: 18),
                  const Text('Vincular estabelecimento', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(email, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: invite,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Codigo de ativacao',
                      prefixIcon: Icon(Icons.key_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 14),
                    Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.amberAccent)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onClaim,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD7A84B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('ATIVAR ESTA BARBEARIA', style: TextStyle(fontWeight: FontWeight.w900)),
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
