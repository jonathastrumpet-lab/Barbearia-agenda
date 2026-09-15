import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Appointment {
  const Appointment({required this.id, required this.service, required this.duration, required this.price, required this.barber, required this.dateIso, required this.time, required this.createdAtIso});
  final String id, service, duration, price, barber, dateIso, time, createdAtIso;
  DateTime get date => DateTime.parse(dateIso);
  Map<String, dynamic> toJson() => {'id': id, 'service': service, 'duration': duration, 'price': price, 'barber': barber, 'dateIso': dateIso, 'time': time, 'createdAtIso': createdAtIso};
  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(id:j['id'], service:j['service'], duration:j['duration'], price:j['price'], barber:j['barber'], dateIso:j['dateIso'], time:j['time'], createdAtIso:j['createdAtIso']);
  Map<String, dynamic> toCloudJson(String clientId) {
    final shop = AppointmentStore.shopId;
    if (shop == null) throw StateError('Usuario sem estabelecimento selecionado.');
    return {'id':id,'barbershop_id':shop,'client_id':clientId,'service':service,'duration':duration,'price':price,'barber':barber,'date_iso':dateIso,'time':time,'created_at_iso':createdAtIso,'status':'scheduled'};
  }
  factory Appointment.fromCloudJson(Map<String,dynamic> j) => Appointment(id:j['id'],service:j['service'],duration:j['duration'],price:j['price'],barber:j['barber'],dateIso:j['date_iso'],time:j['time'],createdAtIso:j['created_at_iso']);
}

class AppointmentConflictException implements Exception { const AppointmentConflictException(); }

class AppointmentStore {
  AppointmentStore._();
  static const _key='appointments_v1';
  static const _clientShopKey='client_shop_id_v1';
  static const _supabaseUrl=String.fromEnvironment('SUPABASE_URL',defaultValue:'https://drvaacngbtnjxdeakgnn.supabase.co');
  static const _supabasePublishableKey=String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY',defaultValue:'sb_publishable_FAPJ5-5m7nnvXP18vw85yQ_QuVAjum8');
  static bool _cloudReady=false;
  static String? _cloudError,_shopId,_memberRole;
  static bool get cloudEnabled=>_cloudReady;
  static String? get cloudError=>_cloudError;
  static String? get shopId=>_shopId;
  static String? get memberRole=>_memberRole;
  static bool get isAdmin=>_memberRole=='owner'||_memberRole=='admin'||_memberRole=='manager';
  static bool get isClient=>signedIn&&!isAdmin;
  static SupabaseClient get client=>Supabase.instance.client;
  static User? get currentUser=>client.auth.currentUser;
  static bool get signedIn=>currentUser!=null&&currentUser!.isAnonymous!=true;
  static bool get hasShop=>_shopId!=null;

  static Future<void> initializeCloud() async {
    _cloudReady=false; _cloudError=null; _shopId=null; _memberRole=null;
    if(_supabaseUrl.isEmpty||_supabasePublishableKey.isEmpty){_cloudError='Configuracao do Supabase ausente no APK.';return;}
    try{
      await Supabase.initialize(url:_supabaseUrl,publishableKey:_supabasePublishableKey);
      if(client.auth.currentUser?.isAnonymous==true) await client.auth.signOut();
      if(client.auth.currentUser!=null) await refreshMembership(); else _cloudError='Entre com sua conta.';
    }catch(e,s){_cloudReady=false;_cloudError=e.toString();debugPrint('[Supabase] Falha ao inicializar: $e');debugPrintStack(stackTrace:s);}
  }

  static Future<void> signIn(String email,String password) async { _cloudReady=false;_cloudError=null;await client.auth.signInWithPassword(email:email.trim(),password:password);await refreshMembership(); }
  static Future<bool> signUp(String email,String password) async { _cloudReady=false;_cloudError=null;final r=await client.auth.signUp(email:email.trim(),password:password);if(r.session!=null){await refreshMembership();return true;}_cloudError='Confirme seu e-mail e depois faca login.';return false; }
  static Future<void> signOut() async { await client.auth.signOut();_cloudReady=false;_shopId=null;_memberRole=null;_cloudError='Entre com sua conta.'; }

  static Future<void> refreshMembership() async {
    final user=client.auth.currentUser; _cloudReady=false;_shopId=null;_memberRole=null;
    if(user==null||user.isAnonymous==true){_cloudError='Login permanente necessario.';return;}
    final rows=await client.from('barbershop_members').select('barbershop_id,role').eq('user_id',user.id).limit(1);
    final list=rows as List<dynamic>;
    if(list.isNotEmpty){final row=list.first as Map<String,dynamic>;_shopId=row['barbershop_id'] as String;_memberRole=row['role'] as String?;_cloudReady=true;_cloudError=null;return;}
    final metadata=user.userMetadata??const <String,dynamic>{};
    if(metadata['account_type']=='barbershop_admin'){_cloudError='Conta da barbearia ainda nao configurada.';return;}
    final prefs=await SharedPreferences.getInstance();
    final saved=prefs.getString(_clientShopKey);
    if(saved!=null&&saved.isNotEmpty){_shopId=saved;_memberRole=null;_cloudReady=true;_cloudError=null;return;}
    _cloudError='Escolha uma barbearia para continuar.';
  }

  static Future<List<Map<String,dynamic>>> listActiveBarbershops() async {
    if(!signedIn) throw StateError('Faca login primeiro.');
    final rows=await client.from('barbershops').select('id,name,slug').eq('active',true).order('name');
    return (rows as List<dynamic>).cast<Map<String,dynamic>>();
  }

  static Future<void> selectClientShop(String id) async {
    if(!signedIn) throw StateError('Faca login primeiro.');
    final rows=await client.from('barbershops').select('id').eq('id',id).eq('active',true).limit(1);
    if((rows as List).isEmpty) throw StateError('Barbearia indisponivel.');
    final prefs=await SharedPreferences.getInstance();await prefs.setString(_clientShopKey,id);
    _shopId=id;_memberRole=null;_cloudReady=true;_cloudError=null;
  }

  static Future<void> clearClientShop() async { final prefs=await SharedPreferences.getInstance();await prefs.remove(_clientShopKey);_shopId=null;_cloudReady=false; }
  static Future<void> claimOwnerAccess(String inviteCode) async {if(!signedIn)throw StateError('Faca login primeiro.');await client.rpc('claim_barbershop_owner',params:{'invite_code':inviteCode.trim()});await refreshMembership();}

  static Future<List<Appointment>> load() async {if(cloudEnabled){try{final r=await _loadRemote();await _save(r);return r;}catch(e,s){_cloudError=e.toString();debugPrint('[Supabase] Falha ao carregar agenda: $e');debugPrintStack(stackTrace:s);}}return _loadLocal();}
  static Future<void> add(Appointment a) async {if(!cloudEnabled)throw StateError(_cloudError??'Agenda na nuvem indisponivel.');try{await _addRemote(a);_cloudError=null;}catch(e,s){_cloudError=e.toString();debugPrint('[Supabase] Falha ao inserir agendamento: $e');debugPrintStack(stackTrace:s);rethrow;}final items=await _loadLocal();items.removeWhere((x)=>x.id==a.id);items.add(a);items.sort(_compareAppointments);await _save(items);}
  static Future<void> remove(String id) async {if(!cloudEnabled)throw StateError(_cloudError??'Agenda na nuvem indisponivel.');try{await _removeRemote(id);_cloudError=null;}catch(e,s){_cloudError=e.toString();debugPrint('[Supabase] Falha ao cancelar agendamento: $e');debugPrintStack(stackTrace:s);rethrow;}final items=await _loadLocal();items.removeWhere((x)=>x.id==id);await _save(items);}
  static Future<List<Appointment>> _loadLocal() async {final p=await SharedPreferences.getInstance();final raw=p.getString(_key);if(raw==null||raw.isEmpty)return[];try{final d=jsonDecode(raw) as List<dynamic>;final items=d.map((x)=>Appointment.fromJson(x as Map<String,dynamic>)).toList();items.sort(_compareAppointments);return items;}catch(_){return[];}}
  static Future<List<Appointment>> _loadRemote() async {final user=client.auth.currentUser,shop=shopId;if(user==null)throw StateError('Sessao Supabase nao autenticada.');if(shop==null)throw StateError('Estabelecimento nao selecionado.');var q=client.from('appointments').select('id,service,duration,price,barber,date_iso,time,created_at_iso').eq('barbershop_id',shop).eq('status','scheduled');if(!isAdmin)q=q.eq('client_id',user.id);final rows=await q.order('date_iso').order('time');final items=(rows as List<dynamic>).map((x)=>Appointment.fromCloudJson(x as Map<String,dynamic>)).toList();items.sort(_compareAppointments);return items;}
  static Future<void> _addRemote(Appointment a) async {final user=client.auth.currentUser;if(user==null)throw StateError('Sessao Supabase nao autenticada.');try{await client.from('appointments').insert(a.toCloudJson(user.id));}on PostgrestException catch(e){if(e.code=='23505')throw const AppointmentConflictException();rethrow;}}
  static Future<void> _removeRemote(String id) async {final shop=shopId,user=client.auth.currentUser;if(user==null)throw StateError('Sessao Supabase nao autenticada.');if(shop==null)throw StateError('Estabelecimento nao selecionado.');var q=client.from('appointments').update({'status':'cancelled'}).eq('id',id).eq('barbershop_id',shop);if(!isAdmin)q=q.eq('client_id',user.id);await q;}
  static Future<void> _save(List<Appointment> items) async {final p=await SharedPreferences.getInstance();await p.setString(_key,jsonEncode(items.map((x)=>x.toJson()).toList()));}
  static int _compareAppointments(Appointment a,Appointment b){DateTime v(Appointment x){final p=x.time.split(':');return DateTime(x.date.year,x.date.month,x.date.day,int.parse(p[0]),int.parse(p[1]));}return v(a).compareTo(v(b));}
}
