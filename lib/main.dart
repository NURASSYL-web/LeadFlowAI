import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/salon_provider.dart';
import 'providers/inquiry_provider.dart';
import 'providers/whatsapp_connection_provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseInitError;

  try {
    firebaseInitError =
        DefaultFirebaseOptions.currentPlatformConfigurationError;

    if (firebaseInitError == null) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on UnsupportedError catch (error) {
    firebaseInitError = error.message ?? error.toString();
  } on FirebaseException catch (error) {
    firebaseInitError = error.message ?? error.toString();
  } catch (error) {
    firebaseInitError = error.toString();
  }

  runApp(LeadFlowApp(firebaseInitError: firebaseInitError));
}

class LeadFlowApp extends StatelessWidget {
  const LeadFlowApp({super.key, this.firebaseInitError});

  final String? firebaseInitError;

  @override
  Widget build(BuildContext context) {
    if (firebaseInitError != null) {
      return MaterialApp(
        title: 'LeadFlow AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _FirebaseSetupRequiredScreen(error: firebaseInitError!),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SalonProvider()),
        ChangeNotifierProvider(create: (_) => InquiryProvider()),
        ChangeNotifierProvider(create: (_) => WhatsAppConnectionProvider()),
      ],
      child: MaterialApp(
        title: 'LeadFlow AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

class _FirebaseSetupRequiredScreen extends StatelessWidget {
  const _FirebaseSetupRequiredScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase setup required',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Firebase is not configured for the current platform yet, so the app is staying in setup mode instead of failing during sign-in.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      error,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Run `flutterfire configure`, regenerate `lib/firebase_options.dart`, and add the platform config file such as `android/app/google-services.json` before launching the full app.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
