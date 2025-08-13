import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/user_avatar.dart';

class ProfileOptions extends StatelessWidget {
  final User? currentUser;
  final VoidCallback onSignOut;
  final VoidCallback onProfileTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onContributionsTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onShowOptions;

  const ProfileOptions({
    Key? key,
    required this.currentUser,
    required this.onSignOut,
    required this.onProfileTap,
    required this.onFavoritesTap,
    required this.onContributionsTap,
    required this.onSettingsTap,
    required this.onShowOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7, // Augmenter la hauteur initiale
      minChildSize: 0.5, // Augmenter la hauteur minimale
      maxChildSize: 0.9, // Conserver la hauteur maximale
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Ajuster le padding vertical
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Photo et nom de l'utilisateur
                if (currentUser != null) ...[
                  Center(
                    child: UserAvatar(user: currentUser),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      currentUser!.userMetadata?['full_name'] ?? currentUser!.email ?? 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5016),
                      ),
                    ),
                  ),
                  if (currentUser!.email != null)
                    Center(
                      child: Text(
                        currentUser!.email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],

                _buildProfileOptionTile(
                  icon: Icons.person,
                  title: 'Mon profil',
                  subtitle: 'Informations personnelles',
                  onTap: onProfileTap,
                ),
                const Divider(height: 32),
                _buildProfileOptionTile(
                  icon: Icons.logout,
                  title: 'Se déconnecter',
                  subtitle: 'Retour à l\'écran de connexion',
                  onTap: onSignOut,
                  isDestructive: true,
                ),
                _buildProfileOptionTile(
                  icon: Icons.favorite,
                  title: 'Mes favoris',
                  subtitle: 'Spots sauvegardés',
                  onTap: onFavoritesTap,
                ),
                _buildProfileOptionTile(
                  icon: Icons.add_location,
                  title: 'Mes contributions',
                  subtitle: 'Spots que j\'ai ajoutés',
                  onTap: onContributionsTap,
                ),
                _buildProfileOptionTile(
                  icon: Icons.settings,
                  title: 'Paramètres',
                  subtitle: 'Configuration de l\'app',
                  onTap: onSettingsTap,
                ),
                const SizedBox(height: 40), // Augmenter l'espace en bas
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : const Color(0xFF2D5016).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF2D5016),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}
