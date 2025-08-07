import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/services/auth_service.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? requiredRole;
  final bool requireAuth;

  const AuthGuard({
    Key? key,
    required this.child,
    this.requiredRole,
    this.requireAuth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        if (requireAuth && !snapshot.hasData) {
          // User is not logged in, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
          });
          return const SizedBox.shrink();
        }

        // If no role requirement, return the child
        if (requiredRole == null) {
          return child;
        }

        // Check user role
        final user = snapshot.data;
        if (user != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                // User document doesn't exist
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(
                      context, AppConstants.loginRoute);
                });
                return const SizedBox.shrink();
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final userRole = userData['role'] ?? AppConstants.clientRole;

              // Check if user has the required role
              if (userRole != requiredRole) {
                // User doesn't have the required role, redirect appropriately
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final route = userRole == AppConstants.clientRole
                      ? AppConstants.clientDashboardRoute
                      : AppConstants.adminDashboardRoute;
                  Navigator.pushReplacementNamed(context, route);
                });
                return const SizedBox.shrink();
              }

              // User has the required role, show the child widget
              return child;
            },
          );
        }

        return child;
      },
    );
  }
}

// Wrapper for client-only pages
class ClientAuthGuard extends StatelessWidget {
  final Widget child;

  const ClientAuthGuard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      requiredRole: AppConstants.clientRole,
      child: child,
    );
  }
}

// Wrapper for admin-only pages
class AdminAuthGuard extends StatelessWidget {
  final Widget child;

  const AdminAuthGuard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      requiredRole: AppConstants.adminRole,
      child: child,
    );
  }
}
