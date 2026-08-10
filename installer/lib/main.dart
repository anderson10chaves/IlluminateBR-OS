import 'package:flutter/material.dart';
import 'screens_install.dart';

void main(List<String> args) {
  String initialProfile = 'devops';

  // Verifica se o perfil foi repassado via linha de comando no boot
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--profile' && i + 1 < args.length) {
      initialProfile = args[i + 1];
    }
  }

  runApp(MyApp(initialProfile: initialProfile));
}

class MyApp extends StatelessWidget {
  final String initialProfile;

  const MyApp({super.key, required this.initialProfile});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IlluminateBR-OS Installer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: InstallProgressScreen(initialProfile: initialProfile),
    );
  }
}
