import 'package:flutter/material.dart';
import 'appointment_store.dart';

class PlatformAdminPage extends StatefulWidget {
  const PlatformAdminPage({super.key});
  @override State<PlatformAdminPage> createState()=>_PlatformAdminPageState();
}
class _PlatformAdminPageState extends State<PlatformAdminPage>{
  int _index=0;
  static const _gold=Color(0xFFD7A84B);
  static const _items=[
    (Icons.dashboard_rounded,'Dashboard'),
    (Icons.storefront_rounded,'Estabelecimentos'),
    (Icons.credit_card_rounded,'Assinaturas'),
    (Icons.inventory_2_rounded,'Planos'),
    (Icons.query_stats_rounded,'Limites e uso'),
    (Icons.people_alt_rounded,'Usuários'),
    (Icons.admin_panel_settings_rounded,'Permissões'),
    (Icons.history_rounded,'Auditoria'),
    (Icons.settings_rounded,'Configurações'),
  ];
  @override Widget build(BuildContext context){
    if(!AppointmentStore.isPlatformAdmin)return const Scaffold(body:Center(child:Text('Acesso não autorizado.')));
    return Scaffold(
      appBar:AppBar(title:const Text('Administração Geral'),actions:[IconButton(tooltip:'Atualizar',onPressed:()=>setState((){}),icon:const Icon(Icons.refresh_rounded))]),
      drawer:Drawer(child:SafeArea(child:Column(children:[
        const ListTile(leading:Icon(Icons.calendar_month_rounded,color:_gold),title:Text('AGENDA HUB',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('Platform Admin')),
        const Divider(),
        Expanded(child:ListView.builder(itemCount:_items.length,itemBuilder:(context,i){final item=_items[i];return ListTile(selected:i==_index,leading:Icon(item.$1),title:Text(item.$2),onTap:(){setState(()=>_index=i);Navigator.pop(context);});})),
      ]))),
      body:SafeArea(child:_body()),
    );
  }
  Widget _body()=>switch(_index){
    0=>const _Dashboard(),
    1=>const _AdminSection(title:'Estabelecimentos',subtitle:'Gerencie status, plano e detalhes de cada estabelecimento.',icon:Icons.storefront_rounded),
    2=>const _AdminSection(title:'Assinaturas',subtitle:'Acompanhe trial, assinaturas ativas, vencidas, suspensas e canceladas.',icon:Icons.credit_card_rounded),
    3=>const _AdminSection(title:'Planos',subtitle:'Configure os planos e seus limites sem depender de uma nova versão do APK.',icon:Icons.inventory_2_rounded),
    4=>const _AdminSection(title:'Limites e uso',subtitle:'Consulte consumo e exceções de limite por estabelecimento.',icon:Icons.query_stats_rounded),
    5=>const _AdminSection(title:'Usuários',subtitle:'Consulte donos e administradores vinculados aos estabelecimentos.',icon:Icons.people_alt_rounded),
    6=>const _AdminSection(title:'Permissões',subtitle:'Área global protegida. Promoção para platform_admin nunca é feita pelo cliente.',icon:Icons.admin_panel_settings_rounded),
    7=>const _AdminSection(title:'Auditoria',subtitle:'Histórico das ações administrativas críticas.',icon:Icons.history_rounded),
    _=>const _AdminSection(title:'Configurações',subtitle:'Parâmetros globais do Agenda Hub.',icon:Icons.settings_rounded),
  };
}
class _Dashboard extends StatelessWidget{
 const _Dashboard();
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(20),children:[
   const Text('AGENDA HUB',style:TextStyle(color:Color(0xFFD7A84B),fontWeight:FontWeight.w900,letterSpacing:2)),
   const SizedBox(height:8),const Text('Painel Geral',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),
   const SizedBox(height:8),const Text('Administração da plataforma. A operação dos estabelecimentos continua isolada.',style:TextStyle(color:Colors.white60)),
   const SizedBox(height:24),
   Wrap(spacing:12,runSpacing:12,children:const [
     _Metric(label:'Estabelecimentos',value:'—',icon:Icons.storefront_rounded),
     _Metric(label:'Assinaturas ativas',value:'—',icon:Icons.verified_rounded),
     _Metric(label:'Em teste',value:'—',icon:Icons.hourglass_top_rounded),
     _Metric(label:'Suspensos',value:'—',icon:Icons.pause_circle_rounded),
   ]),
   const SizedBox(height:24),
   const Card(child:Padding(padding:EdgeInsets.all(18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.security_rounded,color:Color(0xFFD7A84B)),SizedBox(width:12),Expanded(child:Text('Acesso protegido por autorização do backend. Dados operacionais de clientes não são liberados automaticamente ao Administrador Geral.'))]))),
 ]);
}
class _Metric extends StatelessWidget{
 const _Metric({required this.label,required this.value,required this.icon}); final String label,value;final IconData icon;
 @override Widget build(BuildContext context)=>SizedBox(width:165,child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:const Color(0xFFD7A84B)),const SizedBox(height:18),Text(value,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(label,style:const TextStyle(color:Colors.white60,fontSize:12))]))));
}
class _AdminSection extends StatelessWidget{
 const _AdminSection({required this.title,required this.subtitle,required this.icon});final String title,subtitle;final IconData icon;
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(20),children:[
   Icon(icon,size:42,color:const Color(0xFFD7A84B)),const SizedBox(height:14),Text(title,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(subtitle,style:const TextStyle(color:Colors.white60)),
   const SizedBox(height:24),const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('Estrutura preparada. Os dados desta área serão carregados somente pelas funções administrativas protegidas do Supabase.'))),
 ]);
}