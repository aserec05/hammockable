import '../models/spot_data.dart';
import '../widgets/rating_comment.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/login_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/community_reviews.dart';
import '../constants/label_definitions.dart';

class SpotDetailScreen extends StatefulWidget {
  final SpotData spot;

  const SpotDetailScreen({super.key, required this.spot});

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> with SingleTickerProviderStateMixin {
  final User? user = Supabase.instance.client.auth.currentUser;
  bool isLiked = false;
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Variables pour la galerie de photos
  List<String> allPhotos = [];
  bool photosLoading = true;
  PageController _pageController = PageController();
  int currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Configuration de l'animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Vérifier si l'utilisateur a déjà liké
    _checkIfLiked();
    
    // Charger toutes les photos
    _loadAllPhotos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Nouvelle méthode pour charger toutes les photos
  Future<void> _loadAllPhotos() async {
    try {
      final response = await Supabase.instance.client
          .from('photos')
          .select('url')
          .eq('spot_id', widget.spot.id)
          .order('created_at');
      
      setState(() {
        allPhotos = response.map<String>((photo) => photo['url'] as String).toList();
        // Si il n'y a pas de photos dans la DB mais qu'on a une photo dans le spot
        if (allPhotos.isEmpty && widget.spot.photoUrl != null && widget.spot.photoUrl!.isNotEmpty) {
          allPhotos = [widget.spot.photoUrl!];
        }
        photosLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des photos: $e');
      setState(() {
        // Fallback: utiliser la photo du spot si disponible
        if (widget.spot.photoUrl != null && widget.spot.photoUrl!.isNotEmpty) {
          allPhotos = [widget.spot.photoUrl!];
        }
        photosLoading = false;
      });
    }
  }

  Future<void> _checkIfLiked() async {
    if (user == null) return;
    
    try {
      final response = await Supabase.instance.client
          .from('likes')
          .select()
          .eq('user_id', user!.id)
          .eq('spot_id', widget.spot.id)
          .maybeSingle();
      
      setState(() {
        isLiked = response != null;
      });
    } catch (e) {
      print('Erreur lors de la vérification du like: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (user == null) {
      // Afficher un message pour se connecter
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecte-toi pour liker ce spot !'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (isLiked) {
        // Supprimer le like
        await Supabase.instance.client
            .from('likes')
            .delete()
            .eq('user_id', user!.id)
            .eq('spot_id', widget.spot.id);
        
        setState(() {
          isLiked = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Like retiré !'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Ajouter le like
        await Supabase.instance.client
            .from('likes')
            .insert({
              'user_id': user!.id,
              'spot_id': widget.spot.id,
              'created_at': DateTime.now().toIso8601String(),
            });
        
        setState(() {
          isLiked = true;
        });
        
        // Animation du cœur
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spot ajouté aux favoris ! ❤️'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors du toggle like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Widget pour la galerie de photos
  Widget _buildPhotoGallery() {
    if (photosLoading) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (allPhotos.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.landscape, size: 100, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        // PageView pour les photos avec effet de parallaxe
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentPhotoIndex = index;
              });
            },
            itemCount: allPhotos.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  // Calcul de l'effet de parallaxe/slide
                  double value = 0.0;
                  if (_pageController.position.haveDimensions) {
                    value = index.toDouble() - (_pageController.page ?? 0);
                    // Limite l'effet à [-1, 1] pour éviter des transformations extrêmes
                    value = (value * 0.5).clamp(-1.0, 1.0);
                  }
                  
                  return Transform.translate(
                    offset: Offset(value * MediaQuery.of(context).size.width * 0.3, 0),
                    child: Transform.scale(
                      scale: 1.0 - (value.abs() * 0.1), // Léger effet de zoom
                      child: Opacity(
                        opacity: 1.0 - (value.abs() * 0.3), // Effet de fondu
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: value.abs() * 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(value.abs() * 20),
                            child: CachedNetworkImage(
                              imageUrl: allPhotos[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.landscape, size: 100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Indicateurs de pages (si plus d'une photo)
        if (allPhotos.length > 1) ...[
          // Indicateurs en bas avec animation
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: allPhotos.asMap().entries.map((entry) {
                bool isActive = currentPhotoIndex == entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isActive ? 20.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ] : null,
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Compteur en haut à droite avec animation
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                '${currentPhotoIndex + 1}/${allPhotos.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Flèches de navigation avec animations
          if (allPhotos.length > 1) ...[
            // Flèche gauche avec animation de slide
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: currentPhotoIndex > 0 ? 16 : -60,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: currentPhotoIndex > 0 ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: currentPhotoIndex > 0 ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      } : null,
                    ),
                  ),
                ),
              ),
            ),
            
            // Flèche droite avec animation de slide
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: currentPhotoIndex < allPhotos.length - 1 ? 16 : -60,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: currentPhotoIndex < allPhotos.length - 1 ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                      onPressed: currentPhotoIndex < allPhotos.length - 1 ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      } : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec galerie d'images
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF2D5016),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildPhotoGallery(),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: IconButton(
                        icon: isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                            ),
                        onPressed: isLoading ? null : _toggleLike,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et infos principales
                  Text(
                    widget.spot.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Métadonnées
                  Row(
                    children: [
                      if (widget.spot.rating != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                widget.spot.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (widget.spot.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D5016).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.spot.category!,
                            style: const TextStyle(
                              color: Color(0xFF2D5016),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Description complète
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.spot.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Équipements si disponibles
                  if (widget.spot.amenities != null && widget.spot.amenities!.isNotEmpty) ...[
                    const Text(
                      'Équipements',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.spot.amenities!.map((amenity) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          amenity,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                   
                  // Labels/Caractéristiques
                  if (widget.spot.labels != null && widget.spot.labels!.isNotEmpty) ...[
                    const Text(
                      'Caractéristiques',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.spot.labels!.map((label) {
                        // Récupérer les données du label depuis les définitions centralisées
                        final labelId = label['id'] as String?;
                        final labelData = labelId != null ? allLabelsById[labelId.toLowerCase()] : null;
                        
                        final labelName = label['name'] ?? labelData?.name ?? 'Inconnu';
                        final labelIcon = labelData?.icon ?? 
                          (label['icon'] != null 
                              ? IconData(label['icon'], fontFamily: 'MaterialIcons') 
                              : Icons.label);
                        final labelColor = labelData?.color ?? Colors.grey;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: labelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: labelColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                labelIcon,
                                size: 16,
                                color: labelColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                labelName,
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                 
                  const Text(
                      'Laisser un avis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                  const SizedBox(height: 12),

                  if (user != null) 
                    RatingCommentWidget(spotId: widget.spot.id)
                  else 
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(207, 182, 241, 158),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connecte-toi pour laisser un commentaire et rejoindre la communauté.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LoginButton(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Avis communautaires
                  CommunityReviewsWidget(spotId: widget.spot.id),

                  const SizedBox(height: 24),
                  
                  // Position
                  const Text(
                    'Localisation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latitude: ${widget.spot.lat.toStringAsFixed(6)}\nLongitude: ${widget.spot.lon.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      // Boutons d'action flottants
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "share",
            onPressed: () {
              // Action de partage
            },
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2D5016),
            child: const Icon(Icons.share),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "navigate",
            onPressed: () {
              // Ouvrir dans Maps
            },
            backgroundColor: const Color(0xFF2D5016),
            foregroundColor: Colors.white,
            child: const Icon(Icons.directions),
          ),
        ],
      ),
    );
  }
}