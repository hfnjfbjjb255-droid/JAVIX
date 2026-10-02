import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/javix_theme.dart';
import '../../../data/services/subscription_service.dart';
import '../../../widgets/gold_card.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});
  Future<void> _buy(BuildContext context, Future<void> Function() action) async { try { await action(); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', '')))); } }
  @override Widget build(BuildContext context) { final sub=context.watch<SubscriptionService>(); return Scaffold(appBar: AppBar(title: const Text('اشتراك JARVIS')), body: ListView(padding: const EdgeInsets.all(16), children: [GoldCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('JARVIS Pro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(sub.isPro ? 'اشتراكك الحالي: ${sub.plan}' : 'الحساب المجاني: 7 صور و3 فيديوهات يومياً', style: const TextStyle(color: JavixColors.textSecondary)), if(sub.expiresAt!=null) Text('ينتهي: ${sub.expiresAt}', style: const TextStyle(color: JavixColors.textTertiary,fontSize:12))])), const SizedBox(height:12), _Plan(title:'شهري',subtitle:'تجديد شهري',onTap:()=>_buy(context,sub.buyMonthly)), _Plan(title:'3 أشهر',subtitle:'اشتراك ربع سنوي',onTap:()=>_buy(context,sub.buyQuarterly)), _Plan(title:'سنوي',subtitle:'اشتراك سنوي',onTap:()=>_buy(context,sub.buyYearly)), const SizedBox(height:12), const Text('الدفع الفعلي يعتمد على إضافة المنتجات إلى Google Play / App Store وربط الخادم بالتحقق من عمليات الشراء.', textAlign:TextAlign.center,style:TextStyle(color:JavixColors.textTertiary,fontSize:11))])); }
}
class _Plan extends StatelessWidget { final String title,subtitle; final VoidCallback onTap; const _Plan({required this.title,required this.subtitle,required this.onTap}); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:10),child:GoldCard(child:ListTile(title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(subtitle),trailing:FilledButton(onPressed:onTap,style:FilledButton.styleFrom(backgroundColor:JavixColors.gold,foregroundColor:Colors.black),child:const Text('اشتراك'))))); }
