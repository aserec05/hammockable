import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/spot_data.dart';
import 'spot_detail_screen.dart';

class LikedSpotsScreen extends StatefulWidget {

  const LikedSpotsScreen({super.key});


  @override
  State<LikedSpotsScreen> createState() => _LikedSpotsScreenState();
}

class _LikedSpotsScreenState extends State<LikedSpotsScreen> {
  final User? user = Supabase.instance.client.auth.currentUser;
  List<SpotData> likedSpots = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLikedSpots();
  }

  Future<void> _loadLikedSpots() async {
    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Vous devez être connecté pour voir vos favoris';
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Récupérer les spots likés avec leurs infos complètes
      final response = await Supabase.instance.client
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
          .eq('user_id', user!.id)
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

      setState(() {
        likedSpots = spots;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors du chargement: $e';
      });
    }
  }

  Future<void> _removeLike(String spotId) async {
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('likes')
          .delete()
          .eq('user_id', user!.id)
          .eq('spot_id', spotId);

      setState(() {
        likedSpots.removeWhere((spot) => spot.id == spotId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retiré des favoris'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpotDetailScreen(spot: spot),
            ),
          );
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
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.landscape, size: 50),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.landscape, size: 50),
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
                    
                    // Bouton supprimer des favoris
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SpotDetailScreen(spot: spot),
                            ),
                          );
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
        title: const Text(
          'Mes favoris',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadLikedSpots,
              tooltip: 'Actualiser',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLikedSpots,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
              'Chargement de vos favoris...',
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLikedSpots,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (likedSpots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun spot en favori',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explorez et ajoutez des spots à vos favoris\nen appuyant sur le cœur !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: likedSpots.length,
      itemBuilder: (context, index) {
        return _buildSpotCard(likedSpots[index]);
      },
    );
  }
}