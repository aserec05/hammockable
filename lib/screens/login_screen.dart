import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Handlers pour l'authentification
  Future<void> _signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      // Gérer l'erreur
      print('Erreur Google Sign-In: $e');
    }
  }

  Future<void> _signInWithApple() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.apple);
    } catch (e) {
      // Gérer l'erreur
      print('Erreur Apple Sign-In: $e');
    }
  }

  Future<void> _continueAsGuest() async {
    // Navigation vers HomeScreen sans authentification
    print('Continuer en tant qu\'invité');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Dégradé terre/forêt/montagne
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D5016), // Vert forêt foncé
              Color(0xFF3E6B24), // Vert mousse
              Color(0xFF8B4513), // Brun terre
              Color(0xFF654321), // Brun montagne
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Motif montagne en arrière-plan
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: MountainPainter(),
                ),
              ),
            ),
            
            // Éléments décoratifs flottants
            const Positioned(
              top: 60,
              left: 30,
              child: Icon(
                Icons.terrain,
                color: Colors.white24,
                size: 40,
              ),
            ),
            const Positioned(
              top: 100,
              right: 40,
              child: Icon(
                Icons.forest,
                color: Colors.white24,
                size: 35,
              ),
            ),
            const Positioned(
              bottom: 120,
              left: 50,
              child: Icon(
                Icons.hiking,
                color: Colors.white24,
                size: 30,
              ),
            ),
            const Positioned(
              bottom: 80,
              right: 30,
              child: Icon(
                Icons.landscape,
                color: Colors.white24,
                size: 38,
              ),
            ),
            
            // Contenu principal
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo et titre
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Image.asset(
      'assets/images/logo.png',
      width: 24,
      height: 24,
      fit: BoxFit.contain,
    ),
  ), 
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Hammockable',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Votre aventure commence ici 🏕️',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Message d'accueil
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.explore, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Explorez • Partagez • Détendez-vous',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Découvrez les plus beaux endroits en montagne et en forêt pour suspendre votre hamac. Ne stressez plus avant la nuit.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Bouton Google
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              icon: Image.asset(
                                'assets/google_logo.png', // Ajoutez le logo Google
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.login, size: 24);
                                },
                              ),
                              label: const Text(
                                'Continuer avec Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Bouton Apple
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _signInWithApple,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              icon: const Icon(Icons.apple, size: 24),
                              label: const Text(
                                'Continuer avec Apple',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'ou',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Bouton invité
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _continueAsGuest,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                              icon: const Icon(
                                Icons.hiking,
                                color: Colors.white,
                                size: 24,
                              ),
                              label: const Text(
                                'Explorer en tant qu\'aventurier',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Footer
                    const Text(
                      '🏔️ Rejoignez une communauté de passionnés d\'aventure, n\'hésitez pas à partgager votre installation d qui est souvent un art. 🌲',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter pour dessiner des montagnes stylisées
class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Première montagne
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.6, size.height * 0.8);
    path.lineTo(0, size.height * 0.8);
    path.close();
    
    // Deuxième montagne
    path.moveTo(size.width * 0.5, size.height * 0.9);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.5, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}