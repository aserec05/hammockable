import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/spot_data.dart';
import '../models/user_profile.dart';
import '../utils/navigations.dart';
import '../widgets/user_avatar.dart';
import 'spot_detail_screen.dart';
import 'login_screen.dart';

class LikedSpotsScreen extends StatefulWidget {
  final User? targetUser; // L'utilisateur dont on veut voir les favoris (optionnel)
  final UserProfile? targetUserProfile; // Profil de l'utilisateur cible (optionnel)
  final String? targetUserId; // ID de l'utilisateur cible (optionnel)

  const LikedSpotsScreen({
    super.key,
    this.targetUser,
    this.targetUserProfile,
    this.targetUserId,
  });

  @override
  State<LikedSpotsScreen> createState() => _LikedSpotsScreenState();
}

class _LikedSpotsScreenState extends State<LikedSpotsScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  User? currentUser; // L'utilisateur actuellement connecté
  UserProfile? targetProfile; // Le profil de l'utilisateur dont on regarde les favoris
  List<SpotData> likedSpots = [];
  bool isLoading = true;
  String? errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initUser();
    _loadTargetProfile();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _initUser() {
    currentUser = supabase.auth.currentUser;
    
    // Écouter les changements d'authentification
    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          currentUser = data.session?.user;
        });
      }
    });
  }

  Future<void> _loadTargetProfile() async {
    // Si on a déjà un profil utilisateur, on l'utilise
    if (widget.targetUserProfile != null) {
      setState(() {
        targetProfile = widget.targetUserProfile;
      });
      _loadLikedSpots();
      return;
    }

    // Si on a un User, on crée un profil à partir de ses métadonnées
    if (widget.targetUser != null) {
      setState(() {
        targetProfile = UserProfile(
          id: widget.targetUser!.id,
          displayName: widget.targetUser!.userMetadata?['display_name'] as String?,
          avatarUrl: widget.targetUser!.userMetadata?['avatar_url'] as String?,
        );
      });
      _loadLikedSpots();
      return;
    }

    // Si on a juste un ID, on charge le profil depuis la DB
    if (widget.targetUserId != null) {
      try {
        final response = await supabase
            .from('profiles')
            .select('id, display_name, avatar_url, email')
            .eq('id', widget.targetUserId!)
            .single();
        
        setState(() {
          targetProfile = UserProfile.fromMap(response);
        });
        _loadLikedSpots();
      } catch (e) {
        setState(() {
          errorMessage = 'Impossible de charger le profil utilisateur';
          isLoading = false;
        });
      }
      return;
    }

    // Aucun paramètre fourni, on utilise l'utilisateur connecté
    if (currentUser != null) {
      setState(() {
        targetProfile = UserProfile(
          id: currentUser!.id,
          displayName: currentUser!.userMetadata?['display_name'] as String?,
          avatarUrl: currentUser!.userMetadata?['avatar_url'] as String?,
        );
      });
      _loadLikedSpots();
    } else {
      // Pas d'utilisateur connecté et pas de paramètres
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isCurrentUserLikes {
    return currentUser != null && targetProfile != null && currentUser!.id == targetProfile!.id;
  }

  bool get _isUserConnected {
    return currentUser != null;
  }

  bool get _hasTargetUser {
    return targetProfile != null;
  }

  // Nouvelle méthode pour obtenir l'ID de l'utilisateur cible
  String? get _getTargetUserId {
    if (widget.targetUser != null) return widget.targetUser!.id;
    if (widget.targetUserId != null) return widget.targetUserId;
    if (widget.targetUserProfile != null) return widget.targetUserProfile!.id;
    if (targetProfile != null) return targetProfile!.id;
    return currentUser?.id; // Fallback sur l'utilisateur connecté
  }

  String get _displayName {
    if (targetProfile?.displayName != null && targetProfile!.displayName!.isNotEmpty) {
      return targetProfile!.displayName!;
    }
    return 'Utilisateur';
  }

  String get _pageTitle {
    if (_isCurrentUserLikes) {
      return 'Mes favoris';
    }
    return 'Favoris de $_displayName';
  }

  Future<void> _loadLikedSpots() async {
    final targetUserId = _getTargetUserId;
    
    if (targetUserId == null) {
      setState(() {
        isLoading = false;
        likedSpots = [];
        errorMessage = 'Aucun utilisateur spécifié';
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('Chargement des favoris pour l\'utilisateur: $targetUserId');

      // Récupérer les spots likés avec leurs infos complètes pour l'utilisateur spécifique
      final response = await supabase
          .from('likes')
          .select('''
            spot_id,
            created_at,
            spots_with_main_photo!inner(
              id,
              title,
              description,
              lat,
              long,
              photo_url,
              average_rating
            )
          ''')
          .eq('user_id', targetUserId) // Utiliser l'ID de l'utilisateur cible
          .order('created_at', ascending: false);

      final List<SpotData> spots = [];
      
      for (final item in response) {
        final spotData = item['spots_with_main_photo'];
        if (spotData != null) {
          spots.add(SpotData(
            id: spotData['id'],
            title: spotData['title'] ?? 'Sans titre',
            description: spotData['description'] ?? 'Pas de description',
            lat: (spotData['lat'] ?? 0.0).toDouble(),
            lon: (spotData['long'] ?? 0.0).toDouble(),
            photoUrl: spotData['photo_url'],
            rating: spotData['average_rating'] != null 
                ? (spotData['average_rating'] as num).toDouble() 
                : null,
          ));
        }
      }

      print('Spots favoris chargés: ${spots.length} spots trouvés');

      setState(() {
        likedSpots = spots;
        isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      print('Erreur lors du chargement des favoris: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors du chargement: $e';
      });
    }
  }

  Future<void> _removeLike(String spotId) async {
    if (!_isCurrentUserLikes || currentUser == null) return;

    try {
      await supabase
          .from('likes')
          .delete()
          .eq('user_id', currentUser!.id)
          .eq('spot_id', spotId);

      setState(() {
        likedSpots.removeWhere((spot) => spot.id == spotId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retiré des favoris'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRemoveDialog(SpotData spot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Retirer des favoris'),
          content: Text('Êtes-vous sûr de vouloir retirer "${spot.title}" de vos favoris ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeLike(spot.id);
              },
              child: const Text(
                'Retirer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasTargetUser && !isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadLikedSpots,
              tooltip: 'Actualiser',
            ),
        ],
      ),
      body: _hasTargetUser 
          ? RefreshIndicator(
              onRefresh: _loadLikedSpots,
              child: _buildContentWithUser(),
            )
          : _buildUnauthenticatedBody(),
    );
  }

  Widget _buildUnauthenticatedBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5016).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: Color(0xFF2D5016),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Connectez-vous pour voir vos favoris',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sauvegardez vos spots préférés et retrouvez-les facilement en vous connectant à votre compte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      goToScreen(context, const LoginScreen());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5016),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🚀 Inscription bientôt disponible !'),
                        backgroundColor: Color(0xFF2D5016),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Pas encore de compte ? S\'inscrire',
                    style: TextStyle(
                      color: Color(0xFF2D5016),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentWithUser() {
    return Column(
      children: [
        // Header avec info utilisateur (seulement si ce ne sont pas ses propres favoris)
        if (!_isCurrentUserLikes) _buildUserHeader(),
        
        // Contenu principal
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(
            user: widget.targetUser,
            userProfile: widget.targetUserProfile ?? targetProfile,
            userId: widget.targetUserId,
            radius: 30,
            enableClick: false,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${likedSpots.length} spot${likedSpots.length > 1 ? 's' : ''} en favoris',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D5016)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des favoris...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oups ! Une erreur s\'est produite',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadLikedSpots,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (likedSpots.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isCurrentUserLikes 
                        ? 'Aucun spot en favori'
                        : '$_displayName n\'a pas encore de favoris',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isCurrentUserLikes 
                        ? 'Explorez la carte et ajoutez des spots à vos favoris en appuyant sur le cœur !'
                        : 'Les spots favoris apparaîtront ici une fois ajoutés.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  if (_isCurrentUserLikes) ...[
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Retour à la carte
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5016),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.explore),
                      label: const Text('Explorer la carte'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: likedSpots.length,
        itemBuilder: (context, index) {
          return _buildSpotCard(likedSpots[index]);
        },
      ),
    );
  }

  Widget _buildSpotCard(SpotData spot) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          goToScreen(context, SpotDetailScreen(spot: spot));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec overlay
            Container(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    // Image
                    spot.photoUrl != null && spot.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: spot.photoUrl!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D5016)),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.landscape, 
                                size: 50,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.landscape, 
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                    
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                    
                    // Bouton supprimer des favoris (seulement si c'est l'utilisateur connecté)
                    if (_isCurrentUserLikes)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _showRemoveDialog(spot),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    
                    // Rating (si disponible)
                    if (spot.rating != null && spot.rating! > 0)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                spot.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Contenu textuel
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    spot.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    spot.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Bouton voir détails
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          goToScreen(context, SpotDetailScreen(spot: spot));
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Color(0xFF2D5016),
                        ),
                        label: const Text(
                          'Voir détails',
                          style: TextStyle(
                            color: Color(0xFF2D5016),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}