import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'appointment_store.dart';

class OwnerSubscriptionPage extends StatefulWidget {
  const OwnerSubscriptionPage({super.key});
  @override State<OwnerSubscriptionPage> createState()=>_OwnerSubscriptionPageState();
}
class _OwnerSubscriptionPageState extends State<OwnerSubscriptionPage>{
  static const gold=Color(0xFFD7A84B);
  static const pixCopyPaste='00020126580014BR.GOV.BCB.PIX0136f0d56560-9a6d-4453-958e-b5d9d9f9da545204000053039865802BR5921JONATHAS CORREIA LIMA6010VILA VELHA62070503***63043274';
  static const pixKey='f0d56560-9a6d-4453-958e-b5d9d9f9da54';
  bool loading=true; Map<String,dynamic>? sub,plan; String? error;
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    if(!AppointmentStore.isEstablishmentAdmin||AppointmentStore.shopId==null){setState((){loading=false;error='Acesso disponível somente para o Dono do estabelecimento.';});return;}
    try{
      final db=AppointmentStore.client,id=AppointmentStore.shopId!;
      final s=await db.from('barbershop_subscriptions').select().eq('barbershop_id',id).maybeSingle();
      Map<String,dynamic>? p;
      if(s!=null&&s['plan_id']!=null)p=await db.from('subscription_plans').select().eq('id',s['plan_id']).maybeSingle();
      if(!mounted)return;setState((){sub=s;plan=p;loading=false;});
    }catch(e){if(!mounted)return;setState((){loading=false;error='Não foi possível carregar sua assinatura.';});}
  }
  String date(dynamic v){final d=DateTime.tryParse(v?.toString()??'')?.toLocal();if(d==null)return '—';String n(int x)=>x.toString().padLeft(2,'0');return '${n(d.day)}/${n(d.month)}/${d.year}';}
  String status(dynamic v)=>switch(v?.toString()){'active'=>'Ativa','past_due'=>'Em tolerância','suspended'=>'Suspensa','trial'=>'Teste','cancelled'=>'Cancelada',_=>'—'};
  int? priceCents(){for(final k in ['price_cents','monthly_price_cents','amount_cents']){final v=plan?[k];if(v is num)return v.toInt();}return null;}
  String money(){final c=priceCents();if(c==null)return 'Valor definido pelo administrador';return 'R\$ ${(c/100).toStringAsFixed(2).replaceAll('.',',')}';}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Minha assinatura')),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
    if(error!=null)Card(child:Padding(padding:const EdgeInsets.all(18),child:Text(error!))) else ...[
      Text(AppointmentStore.shopName??'Estabelecimento',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:16),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('ASSINATURA',style:TextStyle(color:gold,fontWeight:FontWeight.w900,letterSpacing:1.4)),const SizedBox(height:14),
        _row('Plano',plan?['name']?.toString()??sub?['plan_id']?.toString()??'—'),_row('Valor',money()),_row('Status',status(sub?['status'])),_row('Vencimento',date(sub?['current_period_end'])),
        if(sub?['status']=='past_due')const Padding(padding:EdgeInsets.only(top:8),child:Text('Pagamento em tolerância de 3 dias.',style:TextStyle(color:Colors.orangeAccent,fontWeight:FontWeight.w700))),
      ]))),
      const SizedBox(height:16),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
        const Align(alignment:Alignment.centerLeft,child:Text('PAGAR / RENOVAR VIA PIX',style:TextStyle(color:gold,fontWeight:FontWeight.w900,letterSpacing:1.2))),const SizedBox(height:16),
        Container(color:Colors.white,padding:const EdgeInsets.all(12),child:QrImageView(data:pixCopyPaste,size:210)),
        const SizedBox(height:14),const Text('Escaneie o QR Code no aplicativo do seu banco.',textAlign:TextAlign.center),
        const SizedBox(height:12),SelectableText('Chave Pix: $pixKey',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w700)),
        const SizedBox(height:14),const Text('Após pagar, aguarde a confirmação manual do Agenda Hub. A assinatura será renovada quando o pagamento for confirmado.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white70,height:1.4)),
      ]))),
    ]
  ])));
  Widget _row(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(a,style:const TextStyle(color:Colors.white60))),Flexible(child:Text(b,textAlign:TextAlign.right,style:const TextStyle(fontWeight:FontWeight.w800)))]));
}
