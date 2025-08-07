import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/firebase/firebase_options.dart';

// Auth screens
import 'package:accident_management4/screens/auth/splash_screen.dart';
import 'package:accident_management4/screens/auth/login_screen.dart';
import 'package:accident_management4/screens/auth/signup_screen.dart';
import 'package:accident_management4/screens/auth/role_detection_screen.dart';

// Client screens
import 'package:accident_management4/screens/client/client_dashboard_screen.dart';
import 'package:accident_management4/screens/client/client_register_screen.dart';
import 'package:accident_management4/screens/client/client_biometric_screen.dart';
import 'package:accident_management4/screens/client/client_confirmation_screen.dart';
import 'package:accident_management4/screens/client/client_people_list_screen.dart';

// Admin screens
import 'package:accident_management4/screens/admin/admin_dashboard_screen.dart';
import 'package:accident_management4/screens/admin/admin_scanner_screen.dart';
import 'package:accident_management4/screens/admin/admin_identified_screen.dart';

// Auth Guards
import 'package:accident_management4/widgets/auth/auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
   // Initialize Firebase
  await _initializeFirebase();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Option 1: Utiliser directement MaterialApp sans MultiProvider pour l'instant
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppConstants.splashRoute,
      routes: {
        // Auth routes
        AppConstants.splashRoute: (context) => const SplashScreen(),
        AppConstants.loginRoute: (context) => const LoginScreen(),
        AppConstants.signupRoute: (context) => const SignupScreen(),
        AppConstants.roleDetectionRoute: (context) => const RoleDetectionScreen(),
        
        // Client routes (protected with ClientAuthGuard)
        AppConstants.clientDashboardRoute: (context) => const ClientAuthGuard(
          child: ClientDashboardScreen(),
        ),
        AppConstants.clientRegisterRoute: (context) => const ClientAuthGuard(
          child: ClientRegisterScreen(),
        ),
        AppConstants.clientBiometricRoute: (context) => const ClientAuthGuard(
          child: ClientBiometricScreen(),
        ),
        AppConstants.clientConfirmationRoute: (context) => const ClientAuthGuard(
          child: ClientConfirmationScreen(),
        ),
        AppConstants.clientPeopleListRoute: (context) => const ClientAuthGuard(
          child: ClientPeopleListScreen(),
        ),
        
        // Admin routes (protected with AdminAuthGuard)
        AppConstants.adminDashboardRoute: (context) => const AdminAuthGuard(
          child: AdminDashboardScreen(),
        ),
        AppConstants.adminScannerRoute: (context) => const AdminAuthGuard(
          child: AdminScannerScreen(),
        ),
        AppConstants.adminIdentifiedRoute: (context) => const AdminAuthGuard(
          child: AdminIdentifiedScreen(),
        ),
        // TODO: Add remaining admin routes
        // AppConstants.adminCallingRoute: (context) => const AdminCallingScreen(),
        // AppConstants.adminHistoryRoute: (context) => const AdminHistoryScreen(),
        
        // Shared routes
        // TODO: Add shared routes
        // AppConstants.settingsRoute: (context) => const SettingsScreen(),
        // AppConstants.profileRoute: (context) => const ProfileScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
    );
    
    // Option 2: Si vous voulez garder MultiProvider pour l'utiliser plus tard,
    // créez au moins un provider temporaire :
    /*
    return MultiProvider(
      providers: [
        // Provider temporaire pour éviter l'erreur
        Provider<String>.value(value: 'temp'),
        // Vos vrais providers seront ajoutés ici plus tard
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => PersonProvider()),
        // ChangeNotifierProvider(create: (_) => BiometricProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppConstants.splashRoute,
        routes: {
          // ... routes
        },
      ),
    );
    */
  }
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } else {
      print('Firebase already initialized');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Handle the error appropriately
  }
}
