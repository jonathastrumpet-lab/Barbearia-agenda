import 'appointment_store.dart';

class PlatformAdminStore {
  PlatformAdminStore._();
  static get _db => AppointmentStore.client;
  static Future<bool> isPlatformAdmin() async { if (!AppointmentStore.signedIn) return false; return await _db.rpc('is_platform_admin') == true; }
  static Future<List<Map<String,dynamic>>> loadShops() async {
    final shops=(await _db.from('barbershops').select('id,name,slug,phone,active,created_at').order('name') as List).cast<Map<String,dynamic>>();
    final subs=(await _db.from('barbershop_subscriptions').select() as List).cast<Map<String,dynamic>>();
    final barbers=(await _db.from('barbers').select('barbershop_id,id') as List).cast<Map<String,dynamic>>();
    final appointments=(await _db.from('appointments').select('barbershop_id,id') as List).cast<Map<String,dynamic>>();
    final subByShop={for(final s in subs)s['barbershop_id'].toString():s};
    return shops.map((s){final id=s['id'].toString();return {...s,'subscription':subByShop[id],'professionals':barbers.where((x)=>x['barbershop_id'].toString()==id).length,'appointments':appointments.where((x)=>x['barbershop_id'].toString()==id).length};}).toList();
  }
  static Future<List<Map<String,dynamic>>> loadPlans() async => (await _db.from('subscription_plans').select().order('name') as List).cast<Map<String,dynamic>>();
  static Future<List<Map<String,dynamic>>> loadAudit() async => (await _db.from('platform_audit_log').select().order('created_at',ascending:false).limit(50) as List).cast<Map<String,dynamic>>();
  static Future<void> setShopActive(String id,bool active) async {await _db.from('barbershops').update({'active':active}).eq('id',id);await _audit('shop_active_changed','barbershop',id,{'active':active});}
  static Future<void> updateSubscription(String id,{required String planId,required String status,int? maxProfessionals,int? maxAppointments}) async {await _db.from('barbershop_subscriptions').update({'plan_id':planId,'status':status,'custom_max_professionals':maxProfessionals,'custom_max_monthly_appointments':maxAppointments,'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('barbershop_id',id);await _audit('subscription_changed','barbershop',id,{'plan_id':planId,'status':status});}
  static Future<void> updatePlan(String id,{required int? maxProfessionals,required int? maxAppointments,required bool active}) async {await _db.from('subscription_plans').update({'max_professionals':maxProfessionals,'max_monthly_appointments':maxAppointments,'active':active,'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',id);await _audit('plan_limits_changed','plan',id,{'max_professionals':maxProfessionals,'max_appointments':maxAppointments,'active':active});}
  static Future<void> _audit(String action,String type,String id,Map<String,dynamic> details)async{final u=AppointmentStore.currentUser;if(u!=null)await _db.from('platform_audit_log').insert({'actor_user_id':u.id,'action':action,'entity_type':type,'entity_id':id,'details':details});}
}
