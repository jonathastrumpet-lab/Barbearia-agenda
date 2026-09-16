import 'package:flutter/material.dart';

import 'appointment_store.dart';
import 'barber_store.dart';
import 'data/schedule_templates.dart';
import 'models/barbershop_models.dart';

class ScheduleSettingsPage extends StatefulWidget {
  const ScheduleSettingsPage({super.key});
  @override
  State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage> {
  static const _gold = Color(0xFFD7A84B);
  static const _card = Color(0xFF1D1D1D);
  late ScheduleTemplate _template;
  late List<DaySchedule> _days;
  List<BarberRecord> _barbers = [];
  final Map<String, bool> _barberCustom = {};
  final Map<String, List<DaySchedule>> _barberDays = {};
  bool _loading = true, _saving = false;

  @override
  void initState() { super.initState(); _applyTemplate(scheduleTemplates.first); _load(); }
  void _applyTemplate(ScheduleTemplate t) { _template=t; _days=[for(final d in t.days)d.copyWith()]; }
  List<DaySchedule> _copyDays(List<DaySchedule> source)=>[for(final d in source)d.copyWith()];

  Future<void> _load() async {
    final shop=AppointmentStore.shopId;
    if(shop==null){if(mounted)setState(()=>_loading=false);return;}
    try{
      final results=await Future.wait<dynamic>([
        AppointmentStore.client.from('barbershop_business_hours').select('weekday,enabled,start_minutes,end_minutes,break_enabled,break_start_minutes,break_end_minutes').eq('barbershop_id',shop).order('weekday'),
        BarberStore.loadAll(),
      ]);
      final rows=results[0] as List<dynamic>;
      if(rows.isNotEmpty){
        final by=<int,Map<String,dynamic>>{for(final x in rows)(x as Map<String,dynamic>)['weekday'] as int:x};
        _days=[for(final f in _days) if(by[f.weekday]==null) f else DaySchedule(weekday:f.weekday,enabled:by[f.weekday]!['enabled'] as bool? ?? false,startMinutes:by[f.weekday]!['start_minutes'] as int?,endMinutes:by[f.weekday]!['end_minutes'] as int?,breakEnabled:by[f.weekday]!['break_enabled'] as bool? ?? false,breakStartMinutes:by[f.weekday]!['break_start_minutes'] as int?,breakEndMinutes:by[f.weekday]!['break_end_minutes'] as int?)];
      }
      _barbers=results[1] as List<BarberRecord>;
      for(final b in _barbers){_barberCustom[b.id]=false;_barberDays[b.id]=_copyDays(_days);}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Não foi possível carregar os horários: $e')));}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  String _dayName(int w)=>const{1:'Segunda',2:'Terça',3:'Quarta',4:'Quinta',5:'Sexta',6:'Sábado',7:'Domingo'}[w]!;
  String _time(int? m){if(m==null)return'--:--';return '${(m~/60).toString().padLeft(2,'0')}:${(m%60).toString().padLeft(2,'0')}';}
  Future<int?> _pick(int initial)async{final v=await showTimePicker(context:context,initialTime:TimeOfDay(hour:initial~/60,minute:initial%60),helpText:'Escolha o horário',cancelText:'Cancelar',confirmText:'OK');return v==null?null:v.hour*60+v.minute;}

  Future<void> _editGeneral(int i,String field)async{final d=_days[i];final v=await _pick(field=='start'?(d.startMinutes??540):field=='end'?(d.endMinutes??1140):field=='breakStart'?(d.breakStartMinutes??720):(d.breakEndMinutes??780));if(v==null)return;setState(()=>_days[i]=_changed(d,field,v));}
  Future<void> _editBarber(String id,int i,String field)async{final list=_barberDays[id]!;final d=list[i];final v=await _pick(field=='start'?(d.startMinutes??540):field=='end'?(d.endMinutes??1140):field=='breakStart'?(d.breakStartMinutes??720):(d.breakEndMinutes??780));if(v==null)return;setState(()=>list[i]=_changed(d,field,v));}
  DaySchedule _changed(DaySchedule d,String f,int v){switch(f){case'start':return d.copyWith(startMinutes:v);case'end':return d.copyWith(endMinutes:v);case'breakStart':return d.copyWith(breakStartMinutes:v);default:return d.copyWith(breakEndMinutes:v);}}

  bool _valid(List<DaySchedule> list){for(final d in list){if(d.enabled&&(d.startMinutes==null||d.endMinutes==null||d.startMinutes!>=d.endMinutes!))return false;if(d.breakEnabled&&(d.breakStartMinutes==null||d.breakEndMinutes==null||d.breakStartMinutes!>=d.breakEndMinutes!))return false;}return true;}
  Future<void> _saveHours()async{
    if(_saving)return; final shop=AppointmentStore.shopId;
    if(shop==null||!AppointmentStore.isAdmin){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Somente o DONO/ADMIN pode salvar horários.')));return;}
    if(!_valid(_days)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Revise os horários: abertura deve ser anterior ao fechamento.')));return;}
    for(final b in _barbers){if((_barberCustom[b.id]??false)&&!_valid(_barberDays[b.id]!)){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Revise o horário personalizado de ${b.name}.')));return;}}
    setState(()=>_saving=true);
    try{
      final now=DateTime.now().toUtc().toIso8601String();
      await AppointmentStore.client.from('barbershop_business_hours').upsert(_days.map((d)=><String,dynamic>{'barbershop_id':shop,'weekday':d.weekday,'enabled':d.enabled,'start_minutes':d.startMinutes,'end_minutes':d.endMinutes,'break_enabled':d.breakEnabled,'break_start_minutes':d.breakStartMinutes,'break_end_minutes':d.breakEndMinutes,'updated_at':now}).toList(),onConflict:'barbershop_id,weekday');
      if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Horários do estabelecimento salvos. Horários personalizados serão ligados ao banco na próxima etapa.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erro ao salvar horários: $e')));}
    finally{if(mounted)setState(()=>_saving=false);}
  }

  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Horários do estabelecimento',style:TextStyle(fontWeight:FontWeight.w800))),body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.fromLTRB(18,8,18,30),children:[
    const Text('Escolha um modelo',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('O modelo é só o ponto de partida. Você pode alterar tudo depois.',style:TextStyle(color:Colors.white60)),const SizedBox(height:16),
    ...scheduleTemplates.map((t)=>Padding(padding:const EdgeInsets.only(bottom:9),child:_templateCard(t))),const SizedBox(height:18),const Text('Dias e horários',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:10),...List.generate(_days.length,(i)=>_dayCard(_days,i,null)),const SizedBox(height:22),
    const Text('Horários por profissional',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('Por padrão, todos seguem o horário do estabelecimento. Ative para personalizar um profissional.',style:TextStyle(color:Colors.white60)),const SizedBox(height:10),
    if(_barbers.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('Nenhum profissional cadastrado neste estabelecimento.'))),
    ..._barbers.map(_professionalCard),const SizedBox(height:22),FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:_gold,foregroundColor:Colors.black,padding:const EdgeInsets.symmetric(vertical:16)),onPressed:_saving?null:_saveHours,icon:_saving?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save_rounded),label:Text(_saving?'SALVANDO...':'SALVAR HORÁRIOS',style:const TextStyle(fontWeight:FontWeight.w900)))
  ]));

  Widget _professionalCard(BarberRecord b){final custom=_barberCustom[b.id]??false;return Card(color:_card,margin:const EdgeInsets.only(bottom:10),child:Column(children:[SwitchListTile(activeThumbColor:_gold,title:Text(b.name,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(custom?'Horário personalizado — configure abaixo':'Usa o horário geral do estabelecimento'),value:custom,onChanged:(v)=>setState((){_barberCustom[b.id]=v;if(v)_barberDays[b.id]=_copyDays(_days);})),if(custom)Padding(padding:const EdgeInsets.fromLTRB(10,0,10,10),child:Column(children:[const Divider(),...List.generate(_barberDays[b.id]!.length,(i)=>_dayCard(_barberDays[b.id]!,i,b.id))]))]));}

  Widget _dayCard(List<DaySchedule> list,int i,String? barberId){final d=list[i];void replace(DaySchedule x)=>setState(()=>list[i]=x);return Card(color:barberId==null?_card:Colors.black26,margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,14),child:Column(children:[SwitchListTile(contentPadding:EdgeInsets.zero,activeThumbColor:_gold,title:Text(_dayName(d.weekday),style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(d.enabled?'Dia trabalhado':'Fechado'),value:d.enabled,onChanged:(v)=>replace(d.copyWith(enabled:v))),if(d.enabled)...[Row(children:[Expanded(child:_timeButton('Abertura',_time(d.startMinutes),()=>barberId==null?_editGeneral(i,'start'):_editBarber(barberId,i,'start'))),const SizedBox(width:10),Expanded(child:_timeButton('Fechamento',_time(d.endMinutes),()=>barberId==null?_editGeneral(i,'end'):_editBarber(barberId,i,'end')))]),SwitchListTile(contentPadding:EdgeInsets.zero,activeThumbColor:_gold,title:const Text('Intervalo / almoço'),subtitle:Text(d.breakEnabled?'${_time(d.breakStartMinutes)} às ${_time(d.breakEndMinutes)}':'Sem intervalo'),value:d.breakEnabled,onChanged:(v)=>replace(d.copyWith(breakEnabled:v))),if(d.breakEnabled)Row(children:[Expanded(child:_timeButton('Início intervalo',_time(d.breakStartMinutes),()=>barberId==null?_editGeneral(i,'breakStart'):_editBarber(barberId,i,'breakStart'))),const SizedBox(width:10),Expanded(child:_timeButton('Fim intervalo',_time(d.breakEndMinutes),()=>barberId==null?_editGeneral(i,'breakEnd'):_editBarber(barberId,i,'breakEnd')))])]])));}
  Widget _timeButton(String l,String v,VoidCallback tap)=>OutlinedButton(onPressed:tap,style:OutlinedButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:12)),child:Column(children:[Text(l,style:const TextStyle(fontSize:11)),const SizedBox(height:3),Text(v,style:const TextStyle(fontWeight:FontWeight.w900))]));
  Widget _templateCard(ScheduleTemplate t){final selected=_template.id==t.id;return Material(color:_card,borderRadius:BorderRadius.circular(15),child:InkWell(borderRadius:BorderRadius.circular(15),onTap:()=>setState(()=>_applyTemplate(t)),child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(borderRadius:BorderRadius.circular(15),border:Border.all(color:selected?_gold:Colors.white10,width:selected?2:1)),child:Row(children:[Icon(selected?Icons.radio_button_checked:Icons.radio_button_off,color:selected?_gold:Colors.white54),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t.name,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(t.description,style:const TextStyle(color:Colors.white60,fontSize:12))]))]))));}
}
