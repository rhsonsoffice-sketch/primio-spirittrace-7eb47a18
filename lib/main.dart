import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_locales.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'repositories/investigation_repository.dart';
import 'router/app_router.dart';
import 'theme/theme.dart';
import 'services/purchase_service.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();
SystemChrome.setPreferredOrientations([
DeviceOrientation.portraitUp,
DeviceOrientation.portraitDown,
]);
SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
statusBarColor: Colors.transparent,
statusBarIconBrightness: Brightness.light,
));
runApp(const SpiritTraceApp());
}

class SpiritTraceApp extends StatelessWidget {
const SpiritTraceApp({super.key});

@override
Widget build(BuildContext context) {
return MultiProvider(
providers: [
Provider(create: (_) => InvestigationRepository()),
ChangeNotifierProvider(
create: (_) => PurchaseService(),
),
ChangeNotifierProvider(
create: (ctx) => LocaleProvider(
repository: ctx.read<InvestigationRepository>(),
)..load(),
),
],
child: Consumer<LocaleProvider>(
builder: (context, localeProvider, _) => MaterialApp.router(
title: 'spirit trace',
debugShowCheckedModeBanner: false,
theme: AppTheme.darkTheme,
locale: localeProvider.locale,
supportedLocales: kSupportedLocales,
localizationsDelegates: const [
AppLocalizations.delegate,
GlobalMaterialLocalizations.delegate,
GlobalWidgetsLocalizations.delegate,
GlobalCupertinoLocalizations.delegate,
],
routerConfig: AppRouter.router,
),
),
);
}
}

