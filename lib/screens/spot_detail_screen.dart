import '../models/spot_data.dart';
import '../widgets/rating_comment.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/login_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/community_reviews.dart';

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF2D5016),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.spot.photoUrl != null && widget.spot.photoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.spot.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.landscape, size: 100),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.landscape, size: 100),
                    ),
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