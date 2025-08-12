import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/firebase/firebase_options.dart';
import 'package:accident_management4/services/auth_service.dart';

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
import 'package:accident_management4/screens/client/profile_completion_screen.dart';
import 'package:accident_management4/screens/client/emergency_contacts_screen.dart';
import 'package:accident_management4/screens/client/client_profile_screen.dart';
import 'package:accident_management4/screens/client/medical_info_screen.dart';

// Admin screens
import 'package:accident_management4/screens/admin/admin_dashboard_screen.dart';
import 'package:accident_management4/screens/admin/admin_scanner_screen.dart';
import 'package:accident_management4/screens/admin/admin_identified_screen.dart';
import 'package:accident_management4/screens/admin/admin_history_screen.dart';

// Auth Guards
import 'package:accident_management4/widgets/auth/auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await _initializeFirebase();
  
  // Check and handle session
  await _handleSession();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: _getInitialScreen(snapshot),
          onGenerateRoute: (settings) {
            // Check if user is authenticated
            final user = FirebaseAuth.instance.currentUser;
            final isAuthenticated = user != null;
            
            // Prevent authenticated users from accessing auth screens
            if (isAuthenticated) {
              if (settings.name == AppConstants.loginRoute ||
                  settings.name == AppConstants.signupRoute) {
                // Redirect to role detection to determine where to go
                return MaterialPageRoute(
                  builder: (context) => const RoleDetectionScreen(),
                );
              }
            }
            
            // Define all routes
            switch (settings.name) {
              // Auth routes (no guards needed, handled above)
              case AppConstants.splashRoute:
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                );
              case AppConstants.loginRoute:
                return MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                );
              case AppConstants.signupRoute:
                return MaterialPageRoute(
                  builder: (context) => const SignupScreen(),
                );
              case AppConstants.roleDetectionRoute:
                return MaterialPageRoute(
                  builder: (context) => const RoleDetectionScreen(),
                );
              
              // Client routes (protected with ClientAuthGuard)
              case AppConstants.clientDashboardRoute:
                return MaterialPageRoute(
                  builder: (context) => const ClientAuthGuard(
                    child: ClientDashboardScreen(),
                  ),
                );
              case AppConstants.clientRegisterRoute:
                return MaterialPageRoute(
                  builder: (context) => const ClientAuthGuard(
                    child: ClientRegisterScreen(),
                  ),
                );
              case AppConstants.clientBiometricRoute:
                return MaterialPageRoute(
                  builder: (context) => const ClientAuthGuard(
                    child: ClientBiometricScreen(),
                  ),
                  settings: settings, // Pass settings for arguments
                );
              case AppConstants.clientConfirmationRoute:
                return MaterialPageRoute(
                  builder: (context) => const ClientAuthGuard(
                    child: ClientConfirmationScreen(),
                  ),
                  settings: settings,
                );
              case AppConstants.clientPeopleListRoute:
                return MaterialPageRoute(
                  builder: (context) => const ClientAuthGuard(
                    child: ClientPeopleListScreen(),
                  ),
                );
              case '/client/profile-completion':
                return MaterialPageRoute(
                  builder: (context) => const ClientAuthGuard(
                    child: ProfileCompletionScreen(),
                  ),
                );
              case '/client/emergency-contacts':
                return MaterialPageRoute(
                  builder: (context) => const ClientAuthGuard(
                    child: EmergencyContactsScreen(),
                  ),
                );
              case '/client/profile':
              case AppConstants.profileRoute:
                return MaterialPageRoute(
                  builder: (context) => const ClientAuthGuard(
                    child: ClientProfileScreen(),
                  ),
                );
              case '/client/medical-info':
                return MaterialPageRoute(
                  builder: (context) => const ClientAuthGuard(
                    child: MedicalInfoScreen(),
                  ),
                );
              
              // Admin routes (protected with AdminAuthGuard)
              case AppConstants.adminDashboardRoute:
                return MaterialPageRoute(
                  builder: (context) => const AdminAuthGuard(
                    child: AdminDashboardScreen(),
                  ),
                );
              case AppConstants.adminScannerRoute:
                return MaterialPageRoute(
                  builder: (context) => const AdminAuthGuard(
                    child: AdminScannerScreen(),
                  ),
                );
              case AppConstants.adminIdentifiedRoute:
                return MaterialPageRoute(
                  builder: (context) => const AdminAuthGuard(
                    child: AdminIdentifiedScreen(),
                  ),
                  settings: settings,
                );
              case AppConstants.adminHistoryRoute:
                return MaterialPageRoute(
                  builder: (context) => const AdminAuthGuard(
                    child: AdminHistoryScreen(),
                  ),
                );
              
              // Default fallback
              default:
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                );
            }
          },
        );
      },
    );
  }

  Widget _getInitialScreen(AsyncSnapshot<User?> snapshot) {
    // Show splash screen while checking auth state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SplashScreen();
    }
    
    // If user is authenticated, go to role detection
    if (snapshot.hasData && snapshot.data != null) {
      // Check if session is still valid
      _checkSessionValidity(snapshot.data!);
      return const RoleDetectionScreen();
    }
    
    // Otherwise show splash screen which will navigate to login
    return const SplashScreen();
  }

  void _checkSessionValidity(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginTime = prefs.getInt('last_login_time');
    
    if (lastLoginTime != null) {
      final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
      final now = DateTime.now();
      final difference = now.difference(lastLogin);
      
      // If more than 24 hours, sign out
      if (difference.inHours >= 24) {
        await FirebaseAuth.instance.signOut();
        await prefs.remove('last_login_time');
        await prefs.remove('user_role');
      }
    }
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
  }
}

Future<void> _handleSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Check if session is expired
      final lastLoginTime = prefs.getInt('last_login_time');
      
      if (lastLoginTime != null) {
        final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
        final now = DateTime.now();
        final difference = now.difference(lastLogin);
        
        // If session is expired (more than 24 hours)
        if (difference.inHours >= 24) {
          print('Session expired, signing out user');
          await FirebaseAuth.instance.signOut();
          await prefs.remove('last_login_time');
          await prefs.remove('user_role');
        } else {
          print('Session still valid, ${24 - difference.inHours} hours remaining');
        }
      } else {
        // No session timestamp, create one
        await prefs.setInt('last_login_time', DateTime.now().millisecondsSinceEpoch);
      }
    }
  } catch (e) {
    print('Error handling session: $e');
  }
}

// Session manager class to handle login/logout
class SessionManager {
  static Future<void> onUserLogin(String? role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_login_time', DateTime.now().millisecondsSinceEpoch);
    if (role != null) {
      await prefs.setString('user_role', role);
    }
  }
  
  static Future<void> onUserLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_login_time');
    await prefs.remove('user_role');
  }
  
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginTime = prefs.getInt('last_login_time');
    
    if (lastLoginTime == null) return false;
    
    final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    
    return difference.inHours < 24;
  }
  
  static Future<int> getSessionRemainingHours() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginTime = prefs.getInt('last_login_time');
    
    if (lastLoginTime == null) return 0;
    
    final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    
    final remainingHours = 24 - difference.inHours;
    return remainingHours > 0 ? remainingHours : 0;
  }
}
