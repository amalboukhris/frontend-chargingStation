import 'package:flutter/material.dart';
import 'package:vehicul_charging_station/screens/login_screens.dart';
import 'package:vehicul_charging_station/screens/register_screens.dart';

class WelcomeScreen extends StatelessWidget {
  static const routeName = '/welcome-screen';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Modern background with gradient overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  '/assets/jamie-antoine-tZ6FRpxgKaA-unsplash.jpg',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                
                // Modern title with gradient text
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.lightGreen.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Bienvenue',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle with modern typography
                Text(
                  'Trouvez les bornes de recharge les plus proches et commencez à recharger en toute sécurité',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Modern buttons with nice effects
                _buildModernButton(
                  context,
                  'Se connecter',
                  LinearGradient(
                    colors: [const Color(0xFF00C853), const Color(0xFF01B73B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  Colors.white,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                  ),),
                
                const SizedBox(height: 16),
                
                // Outlined button for secondary action
                _buildOutlinedButton(
                  context,
                  'S\'inscrire',
                  Colors.white,
                  const Color(0xFF01B73B),
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton(
    BuildContext context, 
    String text, 
    Gradient gradient, 
    Color textColor, 
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            height: 60,
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(
    BuildContext context, 
    String text, 
    Color borderColor, 
    Color textColor, 
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: Colors.transparent,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}