import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'citas_page.dart'; // Edicion actividad 7
import 'dashboard_page.dart';
import 'graphics_page.dart'; // Edicion actividad 11 (Esta es la nueva pagina de graficas)


class Routes {
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String citas = '/citas'; // Edicion actividad 7
  static const String dashboard = '/dashboard';
  static const String graphics = '/graphics'; // Edicion actividad 11

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
      return MaterialPageRoute(builder: (_) => LoginPage());
      case home:
      return MaterialPageRoute(builder: (_) => const HomePage());
      case profile:
      return MaterialPageRoute(builder: (_) => const ProfilePage());
      case citas: // Edicion actividad 7
      return MaterialPageRoute(builder: (_) => const CitasPage());
      case dashboard:
      return MaterialPageRoute(builder: (_) => const DashboardPage()); 
      case graphics:
      return MaterialPageRoute(builder: (_) => const GraphicsPage());

      default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
    }
  }
}
