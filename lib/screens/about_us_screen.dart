// screens/about_us_screen.dart
import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('À propos de nous'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2D5016), width: 2),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            
            // Titre
            const Text(
              'Hammockable',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 8),
            
            // Slogan
            const Text(
              'Trouvez votre havre de paix',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            
            // Histoire
            _buildSection(
              title: 'Notre histoire',
              content: 'Hammockable est né pendant un road trip, alors que, comme d\'hab, le soleil commençait à descendre et que cette question existentielle nous taraudait : "Où allons-nous dormir ce soir ?"\n\nL\'idée : ne plus jamais stresser avant la tombée de la nuit. Plus de recherche interminable, plus d\'improvisation hasardeuse. Juste l\'assurance de trouver le spot parfait pour déployer son hamac, sa tente, et profiter du coucher de soleil en toute sérénité.',
              icon: Icons.history,
            ),
            
            const SizedBox(height: 24),
            
            // Mission
            _buildSection(
              title: 'Notre mission',
              content: 'Connecter la communauté des hamac lovers et partager les meilleurs spots pour des moments de détente inoubliables.',
              icon: Icons.flag,
            ),
            
            const SizedBox(height: 24),
            
            // Innovation IA
            _buildSection(
              title: 'Innovation IA 🌟 (En développement)',
              content: 'Nous développons une I.A qui scanne les images satellites pour détecter automatiquement les spots hamacables parfaits !\n\n• Détection d\'arbres adaptés\n• Analyse de la végétation\n• Repérage des points d\'eau\n• Identification des zones abritées\n\nBientôt, trouver votre prochain spot de rêve sera encore plus intuitif !',
              icon: Icons.satellite_alt,
            ),
            
            const SizedBox(height: 24),
            
            // Fonctionnalités
            _buildSection(
              title: 'Ce que nous offrons',
              content: '• Découverte de spots hamacables vérifiés\n• Partage d\'expériences communautaires\n• Notation et commentaires détaillés\n• Cartographie interactive en temps réel\n• Alertes météo intégrées',
              icon: Icons.explore,
            ),
            
            const SizedBox(height: 24),
            
            // Philosophie
            _buildSection(
              title: 'Notre philosophie',
              content: 'Voyagez l\'esprit léger. Profitez du moment présent sans vous soucier de la logistique. Chez Hammockable, nous croyons que les meilleures aventures commencent quand on arrête de planifier et qu\'on se laisse guider par l\'instant.',
              icon: Icons.psychology,
            ),
            
            const SizedBox(height: 24),
            
            // Contact
            _buildSection(
              title: 'Rejoignez-nous',
              content: 'Une suggestion ? Une question ? Un spot secret à partager ?\n\nContactez-nous à : contact@hammockable.com\n\nNous adorons entendre vos histoires de road trip et vos découvertes !',
              icon: Icons.email,
            ),
            
            const SizedBox(height: 32),
            
            // Citation inspirante
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.format_quote,
                    color: Color(0xFF2D5016),
                    size: 24,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '"Le vrai voyage, c\'est de ne pas savoir où l\'on dormira le soir, mais d\'être certain que ça sera unique."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF2D5016),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Version
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bouton fermer
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2D5016), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}