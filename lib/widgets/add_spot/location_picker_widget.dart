import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialLocationName;
  final Function(LatLng location, String locationName) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    this.initialLocationName,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MapController _mapController;
  
  LatLng? _selectedLocation;
  String? _selectedLocationName;
  bool _isLoadingCurrentLocation = false;
  
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mapController = MapController();
    
    _selectedLocation = widget.initialLocation;
    _selectedLocationName = widget.initialLocationName;
    
    if (_selectedLocation != null) {
      _latController.text = _selectedLocation!.latitude.toStringAsFixed(6);
      _lngController.text = _selectedLocation!.longitude.toStringAsFixed(6);
    }
    
    if (_selectedLocationName != null) {
      _nameController.text = _selectedLocationName!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de géolocalisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de géolocalisation refusée définitivement');
      }

      // Obtenir la position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final location = LatLng(position.latitude, position.longitude);
      final locationName = 'Ma position actuelle';
      
      setState(() {
        _selectedLocation = location;
        _selectedLocationName = locationName;
      });

      // Centrer la carte sur la position
      _mapController.move(location, 15.0);
      
      widget.onLocationSelected(location, locationName);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingCurrentLocation = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _selectedLocationName = 'Position sélectionnée';
    });
    
    widget.onLocationSelected(point, _selectedLocationName!);
  }

  void _onManualLocationSet() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    final name = _nameController.text.trim();

    if (lat != null && lng != null && name.isNotEmpty) {
      final location = LatLng(lat, lng);
      setState(() {
        _selectedLocation = location;
        _selectedLocationName = name;
      });
      
      _mapController.move(location, 15.0);
      widget.onLocationSelected(location, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec onglets
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016).withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Localisation du spot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez la méthode qui vous convient',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.map, size: 20),
                      text: 'Carte',
                    ),
                    Tab(
                      icon: Icon(Icons.my_location, size: 20),
                      text: 'Position',
                    ),
                    Tab(
                      icon: Icon(Icons.edit_location, size: 20),
                      text: 'Manuel',
                    ),
                  ],
                  labelColor: const Color(0xFF2D5016),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF2D5016),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Contenu des onglets
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildCurrentLocationTab(),
                _buildManualTab(),
              ],
            ),
          ),

          // Résumé de la sélection
          if (_selectedLocation != null) _buildLocationSummary(),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: Color(0xFF2D5016),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Touchez la carte pour sélectionner l\'emplacement',
                    style: TextStyle(
                      color: Color(0xFF2D5016),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _selectedLocation ?? const LatLng(48.8566, 2.3522),
                  zoom: _selectedLocation != null ? 15.0 : 5.0,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.place,
                            color: Color(0xFF2D5016),
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
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
            child: Icon(
              Icons.my_location,
              size: 60,
              color: const Color(0xFF2D5016).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Utiliser ma position actuelle',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nous utiliserons le GPS de votre appareil pour localiser précisément votre spot',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoadingCurrentLocation ? null : _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              icon: _isLoadingCurrentLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.gps_fixed, size: 24),
              label: Text(
                _isLoadingCurrentLocation 
                    ? 'Localisation en cours...' 
                    : 'Obtenir ma position',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nom du lieu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Ex: Lac de Sainte-Croix, Parc des Buttes-Chaumont...',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latitude',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '48.856614',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Longitude',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '2.352222',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _onManualLocationSet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'Confirmer la position',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Astuce: Vous pouvez copier les coordonnées depuis Google Maps',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSummary() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2D5016).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF2D5016),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Localisation sélectionnée',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D5016),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedLocationName ?? 'Position sélectionnée',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}