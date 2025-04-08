import 'package:flutter/material.dart';
import 'package:vehicul_charging_station/screens/login_screens.dart';
import 'package:vehicul_charging_station/screens/register_screens.dart';

class WelcomeScreen extends StatelessWidget {
  static const routeName = '/welcome-screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  '/assets/jamie-antoine-tZ6FRpxgKaA-unsplash.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60, left: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Bienvenue',
                        style: TextStyle(
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Trouvez les bornes de recharge les plus proches et commencez à recharger en toute sécurité',
                        style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildButton(
                      context,
                      'Se connecter',
                      const Color(0x9E01B73B),
                      const Color(0xFFFFFFFF),
                      () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      ),
                    ),
                    _buildButton(
                      context,
                      'S\'inscrire',
                      Colors.white,
                      const Color(0x9E01B73B),
                      () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color buttonColor, Color textColor, VoidCallback onPressed) {
    return Container(
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: buttonColor,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
