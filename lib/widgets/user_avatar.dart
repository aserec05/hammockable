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
        future: _handleAvatarUrl(
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
        future: _handleAvatarUrl(userProfile!.id, userProfile!.avatarUrl),
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

  /// Gère l'URL de l'avatar (cache Supabase, sinon import Google)
  Future<String?> _handleAvatarUrl(String uid, String? url) async {
    final supabase = Supabase.instance.client;
    
    // Structure corrigée : public/{user_id}.jpg
    final filePath = 'public/$uid.jpg';
    
    try {
      // Vérifier si le fichier existe déjà dans le storage
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      
      if (await _checkIfFileExists(publicUrl)) {
        return publicUrl;
      }

      // Si pas d'upload autorisé, on s'arrête là
      if (!allowUpload) {
        return null;
      }

      // Sinon, si URL Google, on télécharge et on stocke
      if (url != null && url.contains('lh3.googleusercontent.com')) {
        return await _downloadAndStoreAvatar(uid, url, filePath);
      }
    } catch (e) {
      print('Erreur gestion avatar: $e');
    }

    return null;
  }

  /// Télécharge et stocke l'avatar depuis Google
  Future<String?> _downloadAndStoreAvatar(String uid, String googleUrl, String filePath) async {
    final supabase = Supabase.instance.client;
    
    try {
      // Vérifier si l'utilisateur est connecté pour l'upload
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null || currentUser.id != uid) {
        print('Upload non autorisé: utilisateur non connecté ou différent');
        return null;
      }

      print('Téléchargement de l\'avatar depuis Google...');
      final response = await http.get(
        Uri.parse(googleUrl),
        headers: {'User-Agent': 'Flutter App'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        print('Erreur téléchargement Google: ${response.statusCode}');
        return null;
      }

      print('Upload vers Supabase storage...');
      final bytes = response.bodyBytes;
      
      await supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final newUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      print('Avatar uploadé avec succès: $newUrl');

      // Mettre à jour la DB avec la nouvelle URL
      await supabase
          .from('profiles')
          .update({'avatar_url': newUrl})
          .eq('id', uid);

      return newUrl;
    } catch (e) {
      print('Erreur upload avatar: $e');
      return null;
    }
  }

  /// Vérifie si un fichier existe à l'URL donnée
  Future<bool> _checkIfFileExists(String url) async {
    try {
      final res = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Erreur vérification fichier: $e');
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
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
        print('Erreur chargement image: $error');
        return _buildDefaultAvatar('??');
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
    if (displayName != null && displayName.isNotEmpty) {
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