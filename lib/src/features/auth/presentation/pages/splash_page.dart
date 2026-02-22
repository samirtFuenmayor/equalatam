// lib/src/features/auth/presentation/pages/splash_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Pequeña pausa para mostrar el splash
    await Future.delayed(const Duration(milliseconds: 800));

    final repo  = AuthRepositoryImpl();
    final token = await repo.getToken();
    final role  = await repo.getRole();

    if (!mounted) return;

    if (token != null) {
      _redirectByRole(role ?? 'CLIENTE');
    } else {
      context.go('/login');
    }
  }

  void _redirectByRole(String role) {
    switch (role) {
      case 'ADMIN':
      case 'SUPERVISOR':
      case 'EMPLEADO':
        context.go('/dashboard');
      case 'REPARTIDOR':
        context.go('/operations/tracking');
      default:
      // CLIENTE → cuando tengas las rutas del cliente listas
        context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text('Equalatam',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5)),
              SizedBox(height: 48),
              SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white60, strokeWidth: 2)),
            ],
          ),
        ),
      ),
    );
  }
}