import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class DropVoiceApp extends StatelessWidget {
  const DropVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DROPVOICE',
      debugShowCheckedModeBanner: false,
      theme: DropVoiceTheme.dark,
      routerConfig: appRouter,
    );
  }
}
