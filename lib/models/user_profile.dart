
// Modèle pour le profil utilisateur public qui est visible par tout le monde !
class UserProfile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? email; // Optionnel selon vos besoins de confidentialité

  UserProfile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.email,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      email: map['email'] as String?,
    );
  }
}