import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../screens/profile_screen.dart';
import '../utils/navigations.dart';

class UserAvatar extends StatelessWidget {
  final User? user;
  final UserProfile? userProfile;
  final String? userId;
  final double radius;
  final bool allowUpload;
  final bool enableClick;

  const UserAvatar({
    super.key,
    this.user,
    this.userProfile,
    this.userId,
    this.radius = 30.0,
    this.allowUpload = true,
    this.enableClick = true,
  }) : assert(
          user != null || userProfile != null || userId != null,
          'Au moins un des paramètres user, userProfile ou userId doit être fourni',
        );

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;

    if (user != null) {
      avatarWidget = FutureBuilder<String?>(
        future: _getAvatarUrl(
          user!.id,
          user!.userMetadata?['avatar_url'] as String?,
        ),
        builder: _avatarBuilder(
          displayName: user!.userMetadata?['display_name'] as String?,
          fallbackId: user!.id,
        ),
      );
    } else if (userProfile != null) {
      avatarWidget = FutureBuilder<String?>(
        future: _getAvatarUrl(userProfile!.id, userProfile!.avatarUrl),
        builder: _avatarBuilder(
          displayName: userProfile!.displayName,
          fallbackId: userProfile!.id,
        ),
      );
    } else if (userId != null) {
      avatarWidget = FutureBuilder<UserProfile?>(
        future: _loadUserProfile(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingAvatar();
          }
          if (!snapshot.hasData) {
            return _buildDefaultAvatar(userId!);
          }
          return UserAvatar(
            userProfile: snapshot.data!, 
            radius: radius,
            allowUpload: allowUpload,
            enableClick: enableClick,
          );
        },
      );
    } else {
      avatarWidget = _buildDefaultAvatar('unknown');
    }

    // Emballer dans GestureDetector si le clic est activé
    if (enableClick) {
      return GestureDetector(
        onTap: () => _navigateToProfile(context),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  /// Navigation vers l'écran de profil
  void _navigateToProfile(BuildContext context) {
    String targetUserId;
    
    // Déterminer l'ID utilisateur à afficher
    if (user != null) {
      targetUserId = user!.id;
    } else if (userProfile != null) {
      targetUserId = userProfile!.id;
    } else if (userId != null) {
      targetUserId = userId!;
    } else {
      // Ne devrait pas arriver grâce à l'assert, mais on gère le cas
      print('Erreur: Aucun userId disponible pour la navigation');
      return;
    }

    goToScreen(
      context,
      ProfileScreen(userId: targetUserId),
    );
  }

  /// Charge le profil depuis Supabase
  Future<UserProfile?> _loadUserProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, display_name, avatar_url, bio, created_at, updated_at')
          .eq('id', userId)
          .single();
      return UserProfile.fromMap(response);
    } catch (e) {
      print('Erreur chargement profil: $e');
      return null;
    }
  }

  /// Logique principale pour récupérer l'URL de l'avatar
  /// 1️⃣ TOUJOURS vérifier le storage Supabase en premier
  /// 2️⃣ Si pas trouvé ET URL Google disponible, tenter de l'importer
  /// 3️⃣ Sinon retourner null (fallback sur initiales)
  Future<String?> _getAvatarUrl(String uid, String? googleUrl) async {
    final supabase = Supabase.instance.client;
    final filePath = 'public/$uid.jpg';
    
    try {
      // 🔥 ÉTAPE 1: TOUJOURS vérifier le storage Supabase en premier
      final storageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      
      print('🔍 Vérification storage pour $uid: $storageUrl');
      
      if (await _checkIfFileExists(storageUrl)) {
        print('✅ Image trouvée dans le storage: $storageUrl');
        return storageUrl;
      }
      
      print('❌ Pas d\'image dans le storage pour $uid');

      // 🔥 ÉTAPE 2: Si pas dans storage ET URL Google disponible, l'importer
      if (allowUpload && googleUrl != null && googleUrl.contains('googleusercontent.com')) {
        print('🔄 Tentative d\'import depuis Google pour $uid');
        final importedUrl = await _importGoogleAvatar(uid, googleUrl, filePath);
        if (importedUrl != null) {
          print('✅ Avatar Google importé avec succès: $importedUrl');
          return importedUrl;
        }
        print('❌ Échec import Google pour $uid');
      }

      // 🔥 ÉTAPE 3: Aucune image disponible
      print('🔘 Aucune image disponible pour $uid, utilisation des initiales');
      return null;
      
    } catch (e) {
      print('❌ Erreur récupération avatar pour $uid: $e');
      return null;
    }
  }

  /// Importe un avatar depuis Google vers le storage Supabase
  Future<String?> _importGoogleAvatar(String uid, String googleUrl, String filePath) async {
    final supabase = Supabase.instance.client;
    
    try {
      // Sécurité: vérifier que l'utilisateur connecté peut uploader pour cet UID
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null || currentUser.id != uid) {
        print('🔒 Import refusé: utilisateur non autorisé (connecté: ${currentUser?.id}, demandé: $uid)');
        return null;
      }

      print('⬇️ Téléchargement depuis Google: $googleUrl');
      final response = await http.get(
        Uri.parse(googleUrl),
        headers: {'User-Agent': 'Flutter App'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('❌ Échec téléchargement Google: ${response.statusCode}');
        return null;
      }

      if (response.bodyBytes.isEmpty) {
        print('❌ Image Google vide');
        return null;
      }

      print('⬆️ Upload vers Supabase storage...');
      final bytes = response.bodyBytes;
      
      await supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final newStorageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      
      print('💾 Mise à jour de la DB avec la nouvelle URL...');
      // Mettre à jour la DB avec l'URL du storage (pas Google)
      await supabase
          .from('profiles')
          .update({'avatar_url': newStorageUrl})
          .eq('id', uid);

      print('✅ Import terminé avec succès: $newStorageUrl');
      return newStorageUrl;
      
    } catch (e) {
      print('❌ Erreur lors de l\'import Google: $e');
      return null;
    }
  }

  /// Vérifie si un fichier existe à l'URL donnée
  Future<bool> _checkIfFileExists(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 8),
      );
      return response.statusCode == 200;
    } catch (e) {
      // Pas de log ici car c'est normal qu'un fichier n'existe pas
      return false;
    }
  }

  /// Builder générique pour éviter la répétition de code
  AsyncWidgetBuilder<String?> _avatarBuilder({
    required String? displayName,
    required String fallbackId,
  }) {
    return (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingAvatar();
      }
      
      if (snapshot.hasError) {
        print('Erreur dans _avatarBuilder: ${snapshot.error}');
        return _buildInitialsAvatar(
          displayName: displayName,
          fallbackId: fallbackId,
        );
      }
      
      if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
        return _buildInitialsAvatar(
          displayName: displayName,
          fallbackId: fallbackId,
        );
      }
      
      return _buildImageAvatar(snapshot.data!);
    };
  }

  /// Affiche un avatar depuis une image réseau
  Widget _buildImageAvatar(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, _) => _buildLoadingAvatar(),
      errorWidget: (context, url, error) {
        print('❌ Erreur chargement CachedNetworkImage: $error');
        // En cas d'erreur, fallback sur les initiales
        return _buildInitialsAvatar(
          displayName: user?.userMetadata?['display_name'] as String? ??
                     userProfile?.displayName,
          fallbackId: user?.id ?? userProfile?.id ?? userId ?? 'U',
        );
      },
    );
  }

  /// Affiche un avatar avec initiales
  Widget _buildInitialsAvatar({
    String? displayName,
    required String fallbackId,
  }) {
    String initials = _getInitials(displayName, fallbackId);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2D5016),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Extrait les initiales
  String _getInitials(String? displayName, String fallbackId) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    
    // Utiliser le fallback ID
    return fallbackId.length >= 2 
        ? fallbackId.substring(0, 2).toUpperCase()
        : fallbackId[0].toUpperCase();
  }

  /// Loader
  Widget _buildLoadingAvatar() => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        child: SizedBox(
          width: radius * 0.6,
          height: radius * 0.6,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  /// Avatar par défaut
  Widget _buildDefaultAvatar(String fallbackId) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Text(
          fallbackId.length >= 2 
              ? fallbackId.substring(0, 2).toUpperCase()
              : fallbackId[0].toUpperCase(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: radius * 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}