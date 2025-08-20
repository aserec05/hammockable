import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import '../widgets/add_spot/location_picker_widget.dart';
import '../widgets/add_spot/photo_picker_widget.dart';
import '../widgets/add_spot/label_selector_widget.dart';
import 'package:uuid/uuid.dart';

class AddSpotScreen extends StatefulWidget {
  const AddSpotScreen({super.key});

  @override
  State<AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<AddSpotScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageController = PageController();
  late TabController _tabController;
  
  final supabase = Supabase.instance.client;
  
  // État des données du formulaire
  int _currentStep = 0;
  bool _isSubmitting = false;
  
  // Données du spot
  LatLng? _selectedLocation;
  String? _selectedLocationName;
  List<String> _photoPaths = [];
  List<String> _photoBytes = [];
  Set<String> _selectedLabels = {};
  bool _isPublic = true; // Public par défaut

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Écouter les changements de titre et description
    _titleController.addListener(_updateState);
    _descriptionController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {
      // Force la mise à jour de l'état pour réactiver les boutons
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateState);
    _descriptionController.removeListener(_updateState);
    _titleController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabController.animateTo(_currentStep);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabController.animateTo(_currentStep);
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        // Étape Info : titre ET description obligatoires
        return _titleController.text.trim().isNotEmpty &&
               _descriptionController.text.trim().isNotEmpty;
      case 1:
        // Étape Lieu : localisation obligatoire
        return _selectedLocation != null;
      case 2:
        // Étape Photos : au moins une photo obligatoire
        return _photoPaths.isNotEmpty || _photoBytes.isNotEmpty;
      case 3:
        // Étape Labels : optionnelle, toujours valide
        return true;
      default:
        return false;
    }
  }

  Future<void> _submitSpot() async {
  // Validation finale
  if (_titleController.text.trim().isEmpty ||
      _descriptionController.text.trim().isEmpty ||
      _selectedLocation == null ||
      (_photoPaths.isEmpty && _photoBytes.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veuillez remplir tous les champs obligatoires'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isSubmitting = true;
  });

  try {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Vous devez être connecté pour ajouter un spot');
    }

    // 1. Créer le spot dans la base de données
    final spotId = const Uuid().v4();
    final spotData = {
      'id': spotId,
      'user_id': user.id,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'lat': _selectedLocation!.latitude,
      'long': _selectedLocation!.longitude,
      'is_public': _isPublic,
    };

    await supabase.from('spots').insert(spotData);

    // 2. Upload des photos
    if (_photoPaths.isNotEmpty || _photoBytes.isNotEmpty) {
      await _uploadPhotos(spotId);
    }

    // 3. Ajouter les labels (même si vide)
    if (_selectedLabels.isNotEmpty) {
      await _addLabels(spotId);
    }

    // 4. REFRESH LA VUE MATÉRIALISÉE 
    try {
      await supabase.rpc('refresh_spots_view');
    } catch (e) {
      print('Erreur refresh vue: $e');
      // Ne pas faire échouer l'ajout si le refresh échoue
    }

    // Succès !
    if (mounted) {
      Navigator.pop(context, true); // Retourner true pour indiquer succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre spot a été ajouté avec succès !'),
          backgroundColor: Color(0xFF2D5016),
        ),
      );
    }

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

  Future<void> _uploadPhotos(String spotId) async {
  try {
    // Upload des photos depuis les chemins de fichiers (mobile)
    for (int i = 0; i < _photoPaths.length; i++) {
      final file = File(_photoPaths[i]);
      final fileName = '${spotId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      
      // Upload du fichier vers le bucket
      await supabase.storage
          .from('spot_photos')
          .upload(fileName, file);

      // Récupérer l'URL publique du fichier uploadé
      final publicUrl = supabase.storage
          .from('spot_photos')
          .getPublicUrl(fileName);

      // Ajouter l'enregistrement dans la table photos avec l'URL
      await supabase.from('photos').insert({
        'spot_id': spotId,
        'url': publicUrl,
      });
    }

    // Upload des photos depuis les bytes (web)
    for (int i = 0; i < _photoBytes.length; i++) {
      final fileName = '${spotId}_${DateTime.now().millisecondsSinceEpoch}_web_$i.jpg';
      
      // Les données sont déjà en bytes, pas besoin de décoder
      Uint8List bytes;
      
      // Vérifier le type de données reçues
      final photoData = _photoBytes[i];
      
      if (photoData is String) {
        // Si c'est une string, vérifier si c'est du base64 ou des bytes string
        if (photoData.startsWith('data:image/') || photoData.contains('base64,')) {
          // C'est une data URL base64
          final base64String = photoData.split(',').last;
          bytes = base64Decode(base64String);
        } else {
          // C'est probablement une string de bytes, essayer de la parser
          try {
            // Supprimer les crochets et espaces, puis split par virgule
            final cleanString = photoData.replaceAll(RegExp(r'[\[\]\s]'), '');
            final bytesList = cleanString.split(',').map((e) => int.parse(e)).toList();
            bytes = Uint8List.fromList(bytesList);
          } catch (e) {
            print('Erreur parsing bytes string: $e');
            continue; // Passer à la photo suivante si erreur
          }
        }
      } else if (photoData is List<int>) {
        // C'est déjà une liste d'entiers
        bytes = Uint8List.fromList(photoData as List<int>);
      } else if (photoData is Uint8List) {
        // C'est déjà des Uint8List
        bytes = photoData as Uint8List;
      } else {
        print('Type de données photo non supporté: ${photoData.runtimeType}');
        continue; // Passer à la photo suivante
      }
      
      // Upload des bytes vers le bucket
      await supabase.storage
          .from('spot_photos')
          .uploadBinary(fileName, bytes);

      // Récupérer l'URL publique du fichier uploadé
      final publicUrl = supabase.storage
          .from('spot_photos')
          .getPublicUrl(fileName);

      // Ajouter l'enregistrement dans la table photos avec l'URL
      await supabase.from('photos').insert({
        'spot_id': spotId,
        'url': publicUrl,
      });
    }
    
  } catch (e) {
    print('Erreur upload photos: $e');
    rethrow;
  }
}

  Future<void> _addLabels(String spotId) async {
    try {
      final labelsData = _selectedLabels.map((label) => {
        'spot_id': spotId,
        'labels': label,
      }).toList();

      await supabase.from('labels').insert(labelsData);
    } catch (e) {
      print('Erreur ajout labels: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Ajouter un spot',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              labelColor: const Color(0xFF2D5016),
              unselectedLabelColor: Colors.grey[400],
              indicatorColor: const Color(0xFF2D5016),
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentStep >= 0 ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      const Text('Info', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentStep >= 1 ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      const Text('Lieu', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentStep >= 2 ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      const Text('Photos', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentStep >= 3 ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      const Text('Labels', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            Container(
              height: 4,
              color: Colors.grey[200],
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D5016)),
              ),
            ),
            
            // Contenu des étapes
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildInfoStep(),
                  _buildLocationStep(),
                  _buildPhotosStep(),
                  _buildLabelsStep(),
                ],
              ),
            ),
            
            // Boutons de navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parlez-nous de votre spot',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Donnez envie aux autres hamackers de venir découvrir ce lieu',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          
          // Titre du spot
          Text(
            'Nom du spot *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Ex: Lac de Sainte-Croix, Parc des Buttes-Chaumont...',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom du spot est obligatoire';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Description
          Text(
            'Description *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Décrivez ce qui rend ce spot spécial...\n\nMentionnez l\'ambiance, l\'accessibilité, les points d\'intérêt à proximité, ou tout ce qui pourrait être utile aux autres hamackers.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Une description est obligatoire';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Visibilité
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.visibility,
                      color: Color(0xFF2D5016),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Visibilité du spot',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(_isPublic ? 'Public' : 'Privé'),
                  subtitle: Text(
                    _isPublic 
                        ? 'Visible par tous les utilisateurs'
                        : 'Visible uniquement par vous',
                  ),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                  activeColor: const Color(0xFF2D5016),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Où se trouve votre spot ?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aidez les autres à trouver ce petit coin de paradis',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LocationPickerWidget(
              initialLocation: _selectedLocation,
              initialLocationName: _selectedLocationName,
              onLocationSelected: (location, name) {
                setState(() {
                  _selectedLocation = location;
                  _selectedLocationName = name;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Montrez votre spot',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Une image vaut mille mots. Partagez la beauté de votre découverte',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PhotoPickerWidget(
              initialPhotoPaths: _photoPaths,
              initialPhotoBytes: _photoBytes,
              onPhotosChanged: (paths, bytes) {
                setState(() {
                  _photoPaths = paths;
                  _photoBytes = bytes;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelsStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Caractérisez votre spot',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez des informations pratiques pour aider les futurs visiteurs',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          // CORRECTION: Donner une hauteur fixe au widget des labels
          Container(
            height: MediaQuery.of(context).size.height * 0.6, // 60% de la hauteur de l'écran
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LabelsSelectorWidget(
              initialSelectedLabels: _selectedLabels,
              onLabelsChanged: (labels) {
                setState(() {
                  _selectedLabels = labels;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bouton Précédent
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D5016),
                    side: const BorderSide(color: Color(0xFF2D5016)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Précédent',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: 16),
            
            // Bouton Suivant/Publier
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _isSubmitting 
                    ? null 
                    : _currentStep == 3 
                        ? _submitSpot 
                        : _canProceedToNextStep() 
                            ? _nextStep 
                            : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 3 ? 'Publier le spot' : 'Suivant',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep == 3 ? Icons.publish : Icons.arrow_forward,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}