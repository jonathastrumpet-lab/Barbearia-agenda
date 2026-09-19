import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'appointment_store.dart';
import 'appointments_page.dart';
import 'auth_gate.dart';
import 'booking_page.dart';
import 'schedule_settings_page.dart';
import 'services_page.dart';
import 'team_page.dart';
import 'platform_admin_page.dart';
import 'platform_admin_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppointmentStore.initializeCloud();
  runApp(const AgendaHubApp());
}

class AgendaHubApp extends StatelessWidget {
  const AgendaHubApp({super.key});
  static const _background=Color(0xFF111111),_surface=Color(0xFF1B1B1B),_gold=Color(0xFFD7A84B);
  @override Widget build(BuildContext context)=>MaterialApp(title:'Agenda Hub',debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:_background,colorScheme:const ColorScheme.dark(primary:_gold,secondary:_gold,surface:_surface),appBarTheme:const AppBarTheme(backgroundColor:_background,foregroundColor:Colors.white,elevation:0)),home:const AuthGate(child:HomePage()));
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage>{
  static const _gold=Color(0xFFD7A84B),_card=Color(0xFF1D1D1D);
  String _appVersion=''; bool _platformAdmin=false;
  @override void initState(){super.initState();_loadAppVersion();_loadPlatformAdmin();}
  Future<void> _loadPlatformAdmin()async{try{final v=await PlatformAdminStore.isPlatformAdmin();if(mounted)setState(()=>_platformAdmin=v);}catch(_){}}
  Future<void> _loadAppVersion()async{final info=await PackageInfo.fromPlatform();if(!mounted)return;setState(()=>_appVersion='Versão ${info.version} • Build ${info.buildNumber}');}
  void _open(BuildContext context,Widget page)=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>page));
  Future<void> _logout()async{await AppointmentStore.signOut();if(!mounted)return;Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder:(_)=>const AuthGate(child:HomePage())),(_)=>false);}
  Future<void> _changeShop()async{await AppointmentStore.clearClientShop();if(!mounted)return;Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder:(_)=>const AuthGate(child:HomePage())),(_)=>false);}
  @override Widget build(BuildContext context){
    final admin=AppointmentStore.isAdmin;
    final actions=<Widget>[
      if(_platformAdmin)_HomeActionCard(icon:Icons.admin_panel_settings_rounded,title:'Administração Agenda Hub',subtitle:'Assinaturas, limites e estabelecimentos',highlighted:true,onTap:()=>_open(context,const PlatformAdminPage())),
      _HomeActionCard(icon:Icons.calendar_month_rounded,title:'Agendar horário',subtitle:'Escolha serviço, profissional e horário',highlighted:true,onTap:()=>_open(context,const BookingPage())),
      _HomeActionCard(icon:Icons.event_available_rounded,title:admin?'Agenda do estabelecimento':'Meus agendamentos',subtitle:admin?'Veja os próximos horários do estabelecimento':'Veja e cancele seus próximos horários',onTap:()=>_open(context,const AppointmentsPage())),
      if(!admin)_HomeActionCard(icon:Icons.storefront_outlined,title:'Trocar estabelecimento',subtitle:'Escolha outro estabelecimento',onTap:_changeShop),
      if(admin)_HomeActionCard(icon:Icons.schedule_rounded,title:'Horários',subtitle:'Configure funcionamento e equipe',onTap:()=>_open(context,const ScheduleSettingsPage())),
      if(admin)_HomeActionCard(icon:Icons.groups_2_rounded,title:'Profissionais',subtitle:'Equipe e fotos dos profissionais',onTap:()=>_open(context,const TeamPage())),
      if(admin)_HomeActionCard(icon:Icons.design_services_rounded,title:'Serviços',subtitle:'Nome, valor, duração e disponibilidade',onTap:()=>_open(context,const ServicesPage())),
    ];
    return Scaffold(body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,12,20,28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      _topBar(admin),const SizedBox(height:16),_cloudStatusCard(admin),const SizedBox(height:18),_hero(context,admin),const SizedBox(height:28),
      Text(admin?'Gerenciar estabelecimento':'O que você deseja fazer?',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:16),
      GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:14,mainAxisSpacing:14,childAspectRatio:1.08,children:actions),
      const SizedBox(height:28),Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:_card,borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white10)),child:Row(children:[const Icon(Icons.verified_user_rounded,color:_gold,size:27),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(admin?'Acesso administrativo protegido':'Conta de cliente protegida',style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:4),Text(admin?'Você gerencia somente os dados deste estabelecimento.':'Você acessa somente seus agendamentos em ${AppointmentStore.shopName??'seu estabelecimento selecionado'}.',style:const TextStyle(color:Color(0xFFAAAAAA),fontSize:13))]))]))
    ]))));
  }
  Widget _cloudStatusCard(bool admin){final ok=AppointmentStore.cloudEnabled;final shop=AppointmentStore.shopName;final message=ok?(admin?'Supabase conectado. Administração vinculada a ${shop??'seu estabelecimento'}.':'Conectado a ${shop??'estabelecimento selecionado'}.'):'Supabase offline: ${AppointmentStore.cloudError??'falha desconhecida.'}';return Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:ok?const Color(0xFF13271B):const Color(0xFF32191B),borderRadius:BorderRadius.circular(14),border:Border.all(color:ok?const Color(0xFF2E7D4B):const Color(0xFFB74A52))),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(ok?Icons.cloud_done_rounded:Icons.cloud_off_rounded,color:ok?const Color(0xFF7ED69C):const Color(0xFFFF7B82)),const SizedBox(width:10),Expanded(child:SelectableText(message,style:TextStyle(color:ok?const Color(0xFFB9F2CB):const Color(0xFFFFC1C5),fontSize:12.5,height:1.35,fontWeight:FontWeight.w600)))]));}
  Widget _topBar(bool admin)=>Row(children:[const _Logo(),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(admin?'ADMINISTRAÇÃO':'CLIENTE',style:const TextStyle(color:_gold,fontSize:12,fontWeight:FontWeight.w800,letterSpacing:2.2)),const SizedBox(height:2),const Text('Agenda Hub',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800)),const SizedBox(height:2),Text(_appVersion.isEmpty?'Versão ...':_appVersion,style:const TextStyle(color:Colors.white54,fontSize:10.5,fontWeight:FontWeight.w600))])),IconButton(tooltip:'Sair',onPressed:_logout,icon:const Icon(Icons.logout_rounded,color:Colors.white70))]);
  Widget _hero(BuildContext context,bool admin)=>Container(width:double.infinity,padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF2A2317),Color(0xFF171717)]),border:Border.all(color:const Color(0xFF3A3224))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(admin?'PAINEL DO ESTABELECIMENTO':'AGENDE DO SEU JEITO',style:const TextStyle(color:_gold,fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1.1)),const SizedBox(height:16),Text(admin?'Sua agenda em\num só lugar':'Seu próximo horário\na poucos toques',style:const TextStyle(fontSize:30,height:1.08,fontWeight:FontWeight.w900)),const SizedBox(height:10),Text(admin?'Acompanhe agendamentos e configure sua operação.':'Agende em ${AppointmentStore.shopName??'seu estabelecimento'} em poucos passos.',style:const TextStyle(color:Color(0xFFC4C4C4),fontSize:15)),const SizedBox(height:20),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>_open(context,admin?const AppointmentsPage():const BookingPage()),style:FilledButton.styleFrom(backgroundColor:_gold,foregroundColor:Colors.black,padding:const EdgeInsets.symmetric(vertical:15)),icon:Icon(admin?Icons.event_available_rounded:Icons.calendar_month_rounded),label:Text(admin?'VER AGENDA':'AGENDAR AGORA',style:const TextStyle(fontWeight:FontWeight.w900))))]));
}
class _Logo extends StatelessWidget{const _Logo();@override Widget build(BuildContext context)=>Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFD7A84B),borderRadius:BorderRadius.circular(14)),child:const Icon(Icons.calendar_month_rounded,color:Colors.black,size:28));}
class _HomeActionCard extends StatelessWidget{const _HomeActionCard({required this.icon,required this.title,required this.subtitle,required this.onTap,this.highlighted=false});final IconData icon;final String title,subtitle;final VoidCallback onTap;final bool highlighted;@override Widget build(BuildContext context)=>Material(color:highlighted?const Color(0xFF282115):const Color(0xFF1D1D1D),borderRadius:BorderRadius.circular(20),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),border:Border.all(color:highlighted?const Color(0xFF5A4522):Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:43,height:43,decoration:BoxDecoration(color:const Color(0xFFD7A84B).withValues(alpha:.13),borderRadius:BorderRadius.circular(13)),child:Icon(icon,color:const Color(0xFFD7A84B),size:24)),const Spacer(),Text(title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:15,height:1.15,fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Color(0xFF9D9D9D),fontSize:11.5,height:1.25))]))));}
