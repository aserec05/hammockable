import 'package:flutter/material.dart';

/// Widget qui affiche la bio et génère dynamiquement des badges
/// en fonction du contenu de la bio.
class ProfileBadges extends StatelessWidget {
  final String? bio;

  const ProfileBadges({super.key, required this.bio});

  List<Widget> _getAdventureBadges(String bio) {
    final lowerBio = bio.toLowerCase();
    List<Widget> badges = [];

    if (lowerBio.contains('jungle') || lowerBio.contains('forêt')) {
      badges.add(_buildBadge(Icons.park, "Aventurier nature"));
    }
    if (lowerBio.contains('montagne')) {
      badges.add(_buildBadge(Icons.landscape, "Montagnard"));
    }
    if (lowerBio.contains('plage') ||
        lowerBio.contains('mer') ||
        lowerBio.contains('océan')) {
      badges.add(_buildBadge(Icons.beach_access, "Esprit plage"));
    }
    if (lowerBio.contains('heureux') ||
        lowerBio.contains('joyeux') ||
        lowerBio.contains('vibes')) {
      badges.add(_buildBadge(Icons.sentiment_satisfied, "Good vibes"));
    }
    if (lowerBio.contains('hamac')) {
      badges.add(_buildBadge(Icons.holiday_village, "Hamac lover"));
    }

    return badges;
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2D5016)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D5016),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bio == null || bio!.isEmpty) {
      return const SizedBox.shrink();
    }

    final badges = _getAdventureBadges(bio!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Affichage de la bio
        Text(
          bio!,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        // Affichage des badges
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: badges.isEmpty
              ? const SizedBox.shrink()
              : Wrap(children: badges),
        ),
      ],
    );
  }
}
