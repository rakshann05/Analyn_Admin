import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_router.dart';
import '../screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,); // <-- THIS IS THE LINE TO CHANGE
  runApp(const TherapistApp());
}

class TherapistApp extends StatelessWidget {
  const TherapistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Therapist',
      theme: ThemeData(useMaterial3: true),
      home: SplashScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}


