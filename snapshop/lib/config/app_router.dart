import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_observer.dart';
import '../features/home/home_page.dart';
import '../features/recognition/recognition_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/login_page.dart';
import '../features/settings/change_password_page.dart';
import '../features/settings/change_phone_page.dart';
import '../features/settings/account_security_page.dart';
import '../features/profile/profile_page.dart';
import '../features/product_list/product_detail_page.dart';
import '../core/mock_data.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    observers: [routeObserver],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) => const RecognitionPage(),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/change-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChangePasswordPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/change-phone',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChangePhonePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/account-security',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AccountSecurityPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/product-detail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          MockProduct product;
          bool? initialIsFavorited;
          
          if (extra is MockProduct) {
            product = extra;
          } else if (extra is Map) {
            product = extra['product'] as MockProduct;
            initialIsFavorited = extra['initialIsFavorited'] as bool?;
          } else {
            throw ArgumentError('Invalid extra type for product-detail route');
          }
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: ProductDetailPage(
              product: product,
              initialIsFavorited: initialIsFavorited,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
    ],
    redirect: (context, state) {
      final loc = state.uri.toString();
      if (state.matchedLocation == state.uri.path) return null;
      if (state.uri.path.isNotEmpty && state.matchedLocation == '/') return '/';
      return null;
    },
  );
});
