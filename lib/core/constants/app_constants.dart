class AppConstants {
  // Routes
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String roleDetectionRoute = '/role-detection';
  
  // Client Routes
  static const String clientDashboardRoute = '/client/dashboard';
  static const String clientRegisterRoute = '/client/register';
  static const String clientBiometricRoute = '/client/biometric';
  static const String clientConfirmationRoute = '/client/confirmation';
  static const String clientPeopleListRoute = '/client/people';
  
  // Admin Routes
  static const String adminDashboardRoute = '/admin/dashboard';
  static const String adminScannerRoute = '/admin/scanner';
  static const String adminIdentifiedRoute = '/admin/identified';
  static const String adminCallingRoute = '/admin/calling';
  static const String adminHistoryRoute = '/admin/history';
  
  // Shared Routes
  static const String settingsRoute = '/settings';
  static const String profileRoute = '/profile';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String personsCollection = 'persons';
  static const String biometricsCollection = 'biometrics';
  static const String emergencyScansCollection = 'emergencyScans';
  static const String auditLogsCollection = 'auditLogs';
  
  // User Roles
  static const String adminRole = 'admin';
  static const String clientRole = 'client';
  
  // Biometric Quality Threshold
  static const int biometricQualityThreshold = 70;
  
  // Contact Priority
  static const int maxEmergencyContacts = 3;
  
  // Timeouts
  static const Duration biometricScanTimeout = Duration(seconds: 30);
  static const Duration splashScreenDuration = Duration(seconds: 3);
  
  // Error Messages
  static const String genericErrorMessage = 'Une erreur est survenue. Veuillez réessayer.';
  static const String networkErrorMessage = 'Erreur de connexion. Vérifiez votre connexion internet.';
  static const String biometricErrorMessage = 'Échec de la capture biométrique. Veuillez réessayer.';
  static const String authErrorMessage = 'Échec de l\'authentification. Vérifiez vos identifiants.';
  
  // Success Messages
  static const String registrationSuccessMessage = 'Enregistrement réussi !';
  static const String biometricCaptureSuccessMessage = 'Empreinte capturée avec succès !';
  static const String identificationSuccessMessage = 'Personne identifiée !';
  static const String successColor = '#4CAF50';
  
  // App Info
  static const String appName = 'Gestion des Accidents';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Dr. Sawadogo';
  
  // Colors
  static const String primaryColor = '#2196F3';
  static const String secondaryColor = '#03DAC6';
  static const String errorColor = '#CF6679';
  static const String successColorHex = '#4CAF50';
}
