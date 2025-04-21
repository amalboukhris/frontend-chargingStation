import 'package:flutter/material.dart';
import 'package:vehicul_charging_station/screens/Filtrage.dart';
import 'package:vehicul_charging_station/screens/Profile.dart';
import 'package:vehicul_charging_station/screens/WelcomeScreen.dart';
import 'package:vehicul_charging_station/screens/login_screens.dart';
import 'package:vehicul_charging_station/screens/mapScreen.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Charging Station',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: (RouteSettings settings) {
        final args = settings.arguments;
        switch (settings.name) {
          case AppRoutes.welcome:
            return MaterialPageRoute(builder: (_) => WelcomeScreen());
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const SignInScreen());
          case AppRoutes.profile:
            if (args is ProfileArguments) {
              return MaterialPageRoute(
                builder: (_) => ProfilePage(
                  userId: args.userId,
                  userEmail: args.userEmail,
                ),
              );
            }
            return _errorRoute();
          case AppRoutes.map:
            if (args is MapScreenArguments) {
              return MaterialPageRoute(
                builder: (_) => MainMapScreen(
                  userId: args.userId,
                  userEmail: args.userEmail,
                  token: args.token,
                ),
              );
            }
            return _errorRoute();
          default:
            return _errorRoute();
        }
      },
    );
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String map = '/map';
}

class MapScreenArguments {
  final String userId;
  final String userEmail;
  final String token;

  MapScreenArguments({
    required this.userId,
    required this.userEmail,
    required this.token,
  });
}

class ProfileArguments {
  final String userId;
  final String userEmail;

  ProfileArguments({
    required this.userId,
    required this.userEmail,
  });
}