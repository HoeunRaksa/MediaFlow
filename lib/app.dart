import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/sakura_theme.dart';
import 'features/materials/presentation/selling_desktop_shell.dart';

class MaterialQuoteFoundationApp extends StatelessWidget {
  const MaterialQuoteFoundationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
      theme: AppTheme.light(fontFamily: AppConstants.khmerFontFamily),
      home: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.isLoading) {
            return Scaffold(
              body: Center(
                child: MediaQuery.sizeOf(context).width < 1000
                    ? const CupertinoActivityIndicator(radius: 14)
                    : const CircularProgressIndicator(),
              ),
            );
          }
          if (state.loadError != null) {
            return Scaffold(
              body: Center(child: Text('Load failed: ${state.loadError}')),
            );
          }
          return const SellingDesktopShell();
        },
      ),
    );
  }
}
