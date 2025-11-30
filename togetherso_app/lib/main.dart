import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_navigation.dart';
import 'providers/detection_provider.dart';
import 'providers/location_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EcoSightApp());
}

class EcoSightApp extends StatelessWidget {
  const EcoSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DetectionProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'EcoSight - Wildlife Protection',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF2D5F3F),
          scaffoldBackgroundColor: const Color(0xFFF5F5F0),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2D5F3F),
            primary: const Color(0xFF2D5F3F),
            secondary: const Color(0xFF4A7C59),
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const MainNavigation(),
      ),
    );
  }
}
