import 'package:flutter/material.dart';
import 'package:vehicul_charging_station/screens/Profile.dart';
import 'package:vehicul_charging_station/screens/WelcomeScreen.dart';
import 'package:vehicul_charging_station/screens/login_screens.dart';
import 'package:vehicul_charging_station/screens/mapScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Vehicle Charging Station',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // Solution 1: Utilisez soit 'routes' soit 'onGenerateRoute', pas les deux ensemble
        // Option avec 'routes' seulement:

        routes: {
          '/': (context) => WelcomeScreen(),
          '/login': (context) => const SignInScreen(),
          '/profile': (context) => const ProfilePage(),
          '/map': (context) => const Mapscreen(
                userId: '',
                userEmail: '',
                token: '',
              ),
        });
  }
}
      
      
      // Option recommandée: Utilisez onGenerateRoute pour plus de flexibilité
//       initialRoute: '/',
//       onGenerateRoute: (RouteSettings settings) {
//         switch (settings.name) {
//           case '/':
//             return MaterialPageRoute(builder: (_) =>  WelcomeScreen());
//           case '/login':
//             return MaterialPageRoute(builder: (_) => const SignInScreen());
//           case '/profile':
//             return MaterialPageRoute(builder: (_) => const ProfilePage());
//           case '/map':
//             return MaterialPageRoute(builder: (_) => const Mapscreen());
//           default:
//             return MaterialPageRoute(
//               builder: (_) => Scaffold(
//                 appBar: AppBar(title: const Text('Error')),
//                 body: const Center(child: Text('Page not found')),
//               ),
//             );
//         }
//       },
//     );
//   }
// }

// // Ajoutez ceci si vous utilisez la page NotFoundScreen
// class NotFoundScreen extends StatelessWidget {
//   const NotFoundScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Page Not Found')),
//       body: const Center(child: Text('The requested page was not found')),
//     );
//   }
// }