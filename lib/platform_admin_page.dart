import 'package:flutter/material.dart';
import 'appointment_store.dart';

class PlatformAdminPage extends StatefulWidget {
  const PlatformAdminPage({super.key});
  @override State<PlatformAdminPage> createState() => _PlatformAdminPageState();
}

class _PlatformAdminPageState extends State<PlatformAdminPage> {
  bool loading=true; String? error; List<Map<String,dynamic>> shops=[],plans=[],subs=[],barbers=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    if(!AppointmentStore.isPlatformAdmin)return;
    setState((){loading=true;error=null;});
    try { final c=AppointmentStore.client; final r=await Future.wait([
      c.from('barbershops').select('id,name,active').order('name'),
      c.from('subscription_plans').select('id,name,active,max_professionals,max_monthly_appointments').order('name'),
      c.from('barbershop_subscriptions').select('barbershop_id,plan_id,status,custom_max_professionals,custom_max_monthly_appointments'),
      c.from('barbers').select('id,barbershop_id,active')]);
      if(!mounted)return; setState((){shops=(r[0] as List).cast<Map<String,dynamic>>();plans=(r[1] as List).cast<Map<String,dynamic>>();subs=(r[2] as List).cast<Map<String,dynamic>>();barbers=(r[3] as List).cast<Map<String,dynamic>>();loading=false;});
    } catch(e){if(mounted)setState((){error=e.toString();loading=false;});}
  }
  Map<String,dynamic>? subFor(String id){for(final x in subs){if(x['barbershop_id']==id)return x;}return null;}
  Map<String,dynamic>? planFor(String? id){for(final x in plans){if(x['id']==id)return x;}return null;}
  int activePros(String id)=>barbers.where((x)=>x['barbershop_id']==id&&x['active']==true).length;
  int? limitFor(Map<String,dynamic>? s){if(s==null)return null;return (s['custom_max_professionals'] as int?)??(planFor(s['plan_id']?.toString())?['max_professionals'] as int?);}
  Future<void> toggleSub(Map<String,dynamic> shop) async { final s=subFor(shop['id'].toString()); if(s==null)return; final active=s['status']=='active';
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(active?'Suspender assinatura?':'Reativar assinatura?'),content:Text(active?'O estabelecimento ficará temporariamente indisponível.':'O estabelecimento voltará a operar conforme o plano atual.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(active?'Suspender':'Reativar'))]));
    if(ok!=true)return; await AppointmentStore.client.from('barbershop_subscriptions').update({'status':active?'suspended':'active','updated_at':DateTime.now().toUtc().toIso8601String()}).eq('barbershop_id',shop['id']); await load(); }
  Future<void> editPlan(Map<String,dynamic> p) async { final a=TextEditingController(text:(p['max_professionals']??'').toString()),b=TextEditingController(text:(p['max_monthly_appointments']??'').toString());
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text('Plano ${p['name']}'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Limite de profissionais')),TextField(controller:b,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Agendamentos por mês'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Salvar'))]));
    if(ok!=true)return; final pa=int.tryParse(a.text),pb=int.tryParse(b.text); if(pa==null||pb==null||pa<1||pb<1)return; await AppointmentStore.client.from('subscription_plans').update({'max_professionals':pa,'max_monthly_appointments':pb,'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',p['id']); await load(); }
  Widget shopCard(Map<String,dynamic> x){final s=subFor(x['id'].toString()),p=planFor(s?['plan_id']?.toString()),suspended=s?['status']=='suspended';return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(x['name']?.toString()??'Estabelecimento',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text('Plano: ${p?['name']?.toString() ?? s?['plan_id']?.toString() ?? 'Sem plano'}'),Text('Profissionais ativos: ${activePros(x['id'].toString())}'),Text('Limite do plano: ${limitFor(s)?.toString() ?? '—'}'),Text('Status: ${suspended ? 'Suspenso' : 'Ativo'}'),const SizedBox(height:8),OutlinedButton(onPressed:s==null?null:()=>toggleSub(x),child:Text(suspended?'Reativar assinatura':'Suspender assinatura'))])));}
  @override Widget build(BuildContext context){if(!AppointmentStore.isPlatformAdmin)return const Scaffold(body:Center(child:Text('Acesso não autorizado.')));return Scaffold(appBar:AppBar(title:const Text('Administração Geral'),actions:[IconButton(onPressed:loading?null:load,icon:const Icon(Icons.refresh))]),body:SafeArea(child:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
    const Text('AGENDA HUB',style:TextStyle(color:Color(0xFFD7A84B),fontWeight:FontWeight.w900,letterSpacing:2)),const SizedBox(height:12),const Text('Painel Geral',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:18),
    if(loading)const Center(child:Padding(padding:EdgeInsets.all(30),child:CircularProgressIndicator())) else if(error!=null)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[const Text('Não foi possível carregar o painel.'),TextButton(onPressed:load,child:const Text('Tentar novamente'))]))) else ...[
      Text('Estabelecimentos (${shops.length})',style:Theme.of(context).textTheme.titleLarge),...shops.map(shopCard),const SizedBox(height:18),Text('Planos (${plans.length})',style:Theme.of(context).textTheme.titleLarge),...plans.map((p)=>Card(child:ListTile(title:Text(p['name']?.toString()??p['id'].toString()),subtitle:Text('Profissionais: ${p['max_professionals']} • Agendamentos/mês: ${p['max_monthly_appointments']}'),trailing:IconButton(icon:const Icon(Icons.edit_outlined),onPressed:()=>editPlan(p)))))]
  ]))));}
}