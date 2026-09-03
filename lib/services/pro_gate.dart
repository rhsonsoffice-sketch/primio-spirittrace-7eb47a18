import 'package:flutter/material.dart';
import 'purchase_service.dart';

class ProGate {
static bool isPro(BuildContext context) {
return PurchaseService.of(context).isPro;
}

static bool requirePro(
BuildContext context, {
String feature = 'This feature',
}) {
final purchase = PurchaseService.of(context);

if (purchase.isPro) {
return true;
}

showDialog<void>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('SPIRIT TRACE PRO'),
content: const Text(
'Unlock the full SPIRIT TRACE investigation system.\n\n'
'PRO includes:\n'
'• Trace Memory\n'
'• Pattern Detection\n'
'• Connections\n'
'• Repeatability Testing\n'
'• Full Trace Field & Trace Pulse\n'
'• Environmental Analysis\n'
'• Full Case Files\n'
'• Unlimited saved investigations',
),
actions: [
TextButton(
onPressed: () {
Navigator.of(dialogContext).pop();
},
child: const Text('NOT NOW'),
),
ElevatedButton(
onPressed: () {
Navigator.of(dialogContext).pop();

Navigator.of(context).pushNamed('/settings');
},
child: const Text('UNLOCK PRO'),
),
],
);
},
);

return false;
}
}
