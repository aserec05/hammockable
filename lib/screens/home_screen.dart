import 'package:flutter/material.dart';
import '../models/spot_data.dart';
import '../screens/spot_detail_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import '../widgets/user_avatar.dart';
import '../widgets/profile_option.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/spot_modal.dart';
import '../utils/navigations.dart';
import '../widgets/login_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Marker> markers = [];
  bool loading = true;
  String? error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Variables pour l'état de l'utilisateur
  User? currentUser;

  List<SpotData> spots = []; // Pour stocker les données complètes des spots
  SpotData? selectedSpot; // Pour gérer le spot sélectionné

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Écouter les changements d'état de l'authentification
    _setupAuthListener();
    
    // Récupérer l'utilisateur actuel
    currentUser = supabase.auth.currentUser;
    
    loadSpots();
  }

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      setState(() {
        currentUser = session?.user;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadSpots() async {
    try {
      final List<dynamic> data = await supabase.from('spots_with_main_photo').select();

      List<SpotData> loadedSpots = [];
      List<Marker> loadedMarkers = [];

      for (var spot in data) {
        try {
          print(spot);
          print(spot['title']);
          final spotData = SpotData(
            id: spot['id'] as String,
            title: spot['title'] as String,
            description: spot['description'] as String? ?? "Description non disponible",
            lat: spot['lat'] as double,
            lon: spot['long'] as double,
            photoUrl: spot['photo_url'] as String,
            
          );
          loadedSpots.add(spotData);

          final marker = Marker(
            point: LatLng(spotData.lat, spotData.lon),
            width: 40,
            height: 50,
            child: GestureDetector(
              onTap: () => _showSpotModal(spotData), // Ajout de l'interaction
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Le pin avec animation au survol
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.place,
                      size: selectedSpot?.id == spotData.id ? 45 : 40,
                      color: selectedSpot?.id == spotData.id 
                          ? const Color(0xFF2D5016)
                          : Colors.green.withOpacity(0.7),
                    ),
                  ),
                  // Photo ronde
                  if (spotData.photoUrl != null && spotData.photoUrl!.isNotEmpty)
                    Positioned(
                      top: selectedSpot?.id == spotData.id ? 2 : 4,
                      child: Container(
                        width: selectedSpot?.id == spotData.id ? 32 : 28,
                        height: selectedSpot?.id == spotData.id ? 32 : 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white, 
                            width: selectedSpot?.id == spotData.id ? 3 : 2
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: selectedSpot?.id == spotData.id ? 6 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: spotData.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) => const Icon(Icons.place, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 6,
                      child: const Icon(Icons.place, color: Colors.white, size: 28),
                    ),
                ],
              ),
            ),
          );
          loadedMarkers.add(marker);
        } catch (e) {
          print('Erreur lors du chargement du spot: $e');
        }
      }

      setState(() {
        spots = loadedSpots;
        markers = loadedMarkers;
        loading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // 4. Méthode pour afficher la modal flottante
  void _showSpotModal(SpotData spot) {
    setState(() {
      selectedSpot = spot;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SpotModal(
        spot: spot,
        onViewDetails: () {
          Navigator.pop(context); // Fermer la modal
          _navigateToSpotDetails(spot); // Ouvrir l'écran détaillé
        },
        onClose: () {
          setState(() {
            selectedSpot = null;
          });
          Navigator.pop(context);
        },
      ),
    ).whenComplete(() {
      setState(() {
        selectedSpot = null;
      });
    });
  }

  // 5. Navigation vers l'écran détaillé
  void _navigateToSpotDetails(SpotData spot) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SpotDetailScreen(spot: spot),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goToLoginScreen() {
    goToLoginScreen(context);
  }

  void _showProfileOptions() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // Important pour permettre le défilement
    builder: (context) => ProfileOptions(
      currentUser: currentUser,
      onSignOut: _signOut,
      onProfileTap: () => _showComingSoon(context, 'Profil'),
      onFavoritesTap: () => _showComingSoon(context, 'Favoris'),
      onContributionsTap: () => _showComingSoon(context, 'Contributions'),
      onSettingsTap: () => _showComingSoon(context, 'Paramètres'),
      onShowOptions: () => _showProfileOptions(),
    ),
  );
}


  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pop(context); // Fermer le bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez été déconnecté'),
            backgroundColor: Color(0xFF2D5016),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          color: isDestructive 
              ? Colors.red.withOpacity(0.1)
              : const Color(0xFF2D5016).withOpacity(0.1),
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

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true, // Important!
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    builder: (context, scrollController) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController, // Required to scroll inside DraggableSheet
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // your widgets...
            ],
          ),
        ),
      );
    },
  ),
);
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF2D5016).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF2D5016),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
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

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚀 $feature bientôt disponible !'),
        backgroundColor: const Color(0xFF2D5016),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAuthButton() {
    if (currentUser != null) {
      // Utilisateur connecté - afficher la photo de profil
      return GestureDetector(
        onTap: _showProfileOptions,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: UserAvatar(avatarUrl: currentUser?.userMetadata?['avatar_url']),
      ));
    } else {
      // Utilisateur non connecté - afficher le bouton de connexion
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: LoginButton()
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.travel_explore,
                  color: Color.fromARGB(255, 20, 58, 21),
                  size: 30,
                )
              ), 
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Color(0xFF2D5016),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Chargement des endroits hamacables...',
                style: TextStyle(
                  color: Color(0xFF2D5016),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
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
                  color: Colors.red,
                  size: 40,
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
                'Erreur : $error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    loading = true;
                    error = null;
                  });
                  loadSpots();
                },
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

    return Scaffold(
      body: Stack(
        children: [
          // Carte principale
          FadeTransition(
            opacity: _fadeAnimation,
            child: FlutterMap(
              mapController: MapController(),
              options: MapOptions(
                center: markers.isNotEmpty ? markers.first.point : const LatLng(48.8566, 2.3522),
                zoom: markers.isNotEmpty ? 8.0 : 5.0,
                minZoom: 3.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          
          // Header avec dégradé
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2D5016).withOpacity(0.8),
                    const Color(0xFF2D5016).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // AppBar personnalisée
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Logo et titre
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          ),     
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Hammockable',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Trouvez votre havre de paix',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Bouton Auth dynamique
                    _buildAuthButton(),
                  ],
                ),
              ),
            ),
          ),
          
          // Panel d'actions flottant
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barre de recherche
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un lieu, une ville...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Recherche bientôt disponible !'),
                                  backgroundColor: Color(0xFF2D5016),
                                ),
                              );
                            },
                            icon: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D5016),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Boutons d'action principaux
                    Row(
                      children: [
                        // Bouton IA Discovery
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D5016), Color(0xFF3E6B24)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🛰️ IA Discovery bientôt disponible !'),
                                    backgroundColor: Color(0xFF2D5016),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.satellite_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'IA Discovery',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Bouton Ajouter un spot
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pour partager'),
                                  backgroundColor: Color(0xFF2D5016),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.add_location_alt,
                              color: Color(0xFF2D5016),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Bouton Options/Filtres
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              _showOptionsBottomSheet(context);
                            },
                            icon: const Icon(
                              Icons.tune,
                              color: Color(0xFF2D5016),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}