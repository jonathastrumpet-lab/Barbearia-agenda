import 'package:flutter/material.dart';

import 'data/sample_barbershop.dart';
import 'data/schedule_templates.dart';
import 'models/barbershop_models.dart';

class ScheduleSettingsPage extends StatefulWidget {
  const ScheduleSettingsPage({super.key});
  @override State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage> {
  static const _gold = Color(0xFFD7A84B); static const _card = Color(0xFF1D1D1D);
  late ScheduleTemplate _template; late List<DaySchedule> _days; final Map<String, bool> _barberCustom = {};
  @override void initState() { super.initState(); _applyTemplate(scheduleTemplates.first); }
  void _applyTemplate(ScheduleTemplate template) { _template = template; _days = [for (final day in template.days) day.copyWith()]; }
  String _dayName(int weekday) => const {1:'Segunda',2:'Terça',3:'Quarta',4:'Quinta',5:'Sexta',6:'Sábado',7:'Domingo'}[weekday]!;
  String _time(int? minutes) => minutes == null ? '--:--' : '${(minutes ~/ 60).toString().padLeft(2,'0')}:${(minutes % 60).toString().padLeft(2,'0')}';
  Future<int?> _pickMinutes(int initial) async { final value = await showTimePicker(context: context, initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60), helpText:'Escolha o horário', cancelText:'Cancelar', confirmText:'OK'); return value == null ? null : value.hour * 60 + value.minute; }
  void _replaceDay(int index, DaySchedule value) => setState(() => _days[index] = value);
  Future<void> _editTime(int index, String field) async { final day=_days[index]; final initial=switch(field){'start'=>day.startMinutes??540,'end'=>day.endMinutes??1140,'breakStart'=>day.breakStartMinutes??720,_=>day.breakEndMinutes??780}; final value=await _pickMinutes(initial); if(value==null)return; _replaceDay(index,switch(field){'start'=>day.copyWith(startMinutes:value),'end'=>day.copyWith(endMinutes:value),'breakStart'=>day.copyWith(breakStartMinutes:value),_=>day.copyWith(breakEndMinutes:value)}); }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Horários da barbearia',style:TextStyle(fontWeight:FontWeight.w800))),
    body: ListView(padding:const EdgeInsets.fromLTRB(18,8,18,30),children:[
      const Text('Escolha um modelo',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)), const SizedBox(height:6), const Text('O modelo é só o ponto de partida. Você pode alterar tudo depois.',style:TextStyle(color:Colors.white60)), const SizedBox(height:16),
      ...scheduleTemplates.map((template)=>Padding(padding:const EdgeInsets.only(bottom:9),child:_templateCard(template))),
      const SizedBox(height:18), const Text('Dias e horários',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)), const SizedBox(height:10), ...List.generate(_days.length,_buildDay),
      const SizedBox(height:22), const Text('Exceções por barbeiro',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)), const SizedBox(height:5), const Text('Por padrão, todos seguem o horário da barbearia. Ative para personalizar um profissional.',style:TextStyle(color:Colors.white60)), const SizedBox(height:10),
      ...sampleBarbers.map((barber)=>Card(color:_card,child:SwitchListTile(activeThumbColor:_gold,title:Text(barber.name,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text((_barberCustom[barber.id]??false)?'Horário personalizado ativado':'Usa o horário geral da barbearia'),value:_barberCustom[barber.id]??false,onChanged:(value)=>setState(()=>_barberCustom[barber.id]=value)))),
      const SizedBox(height:22), FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:_gold,foregroundColor:Colors.black,padding:const EdgeInsets.symmetric(vertical:16)),onPressed:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Configuração pronta para ser ligada ao banco na próxima etapa.'))),icon:const Icon(Icons.save_rounded),label:const Text('SALVAR HORÁRIOS',style:TextStyle(fontWeight:FontWeight.w900)))
    ])
  );

  Widget _templateCard(ScheduleTemplate template) { final selected=_template.id==template.id; return Material(color:_card,borderRadius:BorderRadius.circular(15),child:InkWell(borderRadius:BorderRadius.circular(15),onTap:()=>setState(()=>_applyTemplate(template)),child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(borderRadius:BorderRadius.circular(15),border:Border.all(color:selected?_gold:Colors.white10,width:selected?2:1)),child:Row(children:[Icon(selected?Icons.radio_button_checked:Icons.radio_button_off,color:selected?_gold:Colors.white54),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(template.name,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(template.description,style:const TextStyle(color:Colors.white60,fontSize:12))]))]))))); }

  Widget _buildDay(int index) { final day=_days[index]; return Card(color:_card,margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,14),child:Column(children:[
    SwitchListTile(contentPadding:EdgeInsets.zero,activeThumbColor:_gold,title:Text(_dayName(day.weekday),style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(day.enabled?'Dia trabalhado':'Fechado'),value:day.enabled,onChanged:(value)=>_replaceDay(index,day.copyWith(enabled:value))),
    if(day.enabled)...[Row(children:[Expanded(child:_timeButton('Abertura',_time(day.startMinutes),()=>_editTime(index,'start'))),const SizedBox(width:10),Expanded(child:_timeButton('Fechamento',_time(day.endMinutes),()=>_editTime(index,'end')))]),SwitchListTile(contentPadding:EdgeInsets.zero,activeThumbColor:_gold,title:const Text('Intervalo / almoço'),subtitle:Text(day.breakEnabled?'${_time(day.breakStartMinutes)} às ${_time(day.breakEndMinutes)}':'Sem intervalo'),value:day.breakEnabled,onChanged:(value)=>_replaceDay(index,day.copyWith(breakEnabled:value))),if(day.breakEnabled)Row(children:[Expanded(child:_timeButton('Início intervalo',_time(day.breakStartMinutes),()=>_editTime(index,'breakStart'))),const SizedBox(width:10),Expanded(child:_timeButton('Fim intervalo',_time(day.breakEndMinutes),()=>_editTime(index,'breakEnd')))])]
  ])))); }
  Widget _timeButton(String label,String value,VoidCallback onTap)=>OutlinedButton(onPressed:onTap,style:OutlinedButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:12)),child:Column(children:[Text(label,style:const TextStyle(fontSize:11)),const SizedBox(height:3),Text(value,style:const TextStyle(fontWeight:FontWeight.w900))]));
}
