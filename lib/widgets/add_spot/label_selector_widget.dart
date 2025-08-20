import 'package:flutter/material.dart';

class LabelsSelectorWidget extends StatefulWidget {
  final Set<String> initialSelectedLabels;
  final Function(Set<String>) onLabelsChanged;

  const LabelsSelectorWidget({
    super.key,
    this.initialSelectedLabels = const {},
    required this.onLabelsChanged,
  });

  @override
  State<LabelsSelectorWidget> createState() => _LabelsSelectorWidgetState();
}

class _LabelsSelectorWidgetState extends State<LabelsSelectorWidget> {
  Set<String> _selectedLabels = {};

  // Labels prédéfinis organisés par catégories
  static const Map<String, List<LabelData>> _labelCategories = {
    '🌿 Confort': [
      LabelData('hamac_spots', 'Spots hamac', Icons.bed, Colors.green),
      LabelData('ombre', 'Ombragé', Icons.umbrella, Colors.blue),
      LabelData('abri', 'Abri naturel', Icons.home_outlined, Colors.brown),
      LabelData('vue_panoramique', 'Vue panoramique', Icons.landscape, Colors.purple),
      LabelData('calme', 'Endroit calme', Icons.volume_off, Colors.indigo),
    ],
    '🚗 Accès': [
      LabelData('parking', 'Parking proche', Icons.local_parking, Colors.grey),
      LabelData('acces_facile', 'Accès facile', Icons.accessible, Colors.green),
      LabelData('transport_public', 'Transport public', Icons.train, Colors.blue),
      LabelData('marche_courte', 'Marche courte', Icons.directions_walk, Colors.orange),
      LabelData('marche_longue', 'Randonnée requise', Icons.hiking, Colors.red),
    ],
    '💧 Services': [
      LabelData('point_eau', 'Point d\'eau', Icons.water_drop, Colors.blue),
      LabelData('wc', 'Toilettes', Icons.wc, Colors.brown),
      LabelData('poubelles', 'Poubelles', Icons.delete_outline, Colors.green),
      LabelData('restaurant', 'Restaurant/Café', Icons.restaurant, Colors.orange),
      LabelData('commerce', 'Commerce proche', Icons.store, Colors.purple),
    ],
    '⚠️ Attention': [
      LabelData('moustiques', 'Moustiques', Icons.bug_report, Colors.red),
      LabelData('vent', 'Zone ventée', Icons.air, Colors.cyan),
      LabelData('bruit', 'Peut être bruyant', Icons.volume_up, Colors.orange),
      LabelData('monde', 'Très fréquenté', Icons.groups, Colors.amber),
      LabelData('prive', 'Terrain privé', Icons.lock, Colors.red),
    ],
    '🌊 Environnement': [
      LabelData('eau', 'Bord de l\'eau', Icons.waves, Colors.blue),
      LabelData('foret', 'En forêt', Icons.park, Colors.green),
      LabelData('montagne', 'En montagne', Icons.terrain, Colors.grey),
      LabelData('plage', 'Plage', Icons.beach_access, Colors.yellow),
      LabelData('jardin', 'Jardin/Parc', Icons.local_florist, Colors.pink),
    ],
    '🎯 Activités': [
      LabelData('baignade', 'Baignade possible', Icons.pool, Colors.blue),
      LabelData('peche', 'Pêche autorisée', Icons.phishing, Colors.brown),
      LabelData('barbecue', 'Barbecue autorisé', Icons.outdoor_grill, Colors.red),
      LabelData('feu_camp', 'Feu de camp OK', Icons.local_fire_department, Colors.orange),
      LabelData('photo', 'Spot photo', Icons.camera_alt, Colors.purple),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedLabels = Set.from(widget.initialSelectedLabels);
  }

  void _toggleLabel(String labelId) {
    setState(() {
      if (_selectedLabels.contains(labelId)) {
        _selectedLabels.remove(labelId);
      } else {
        _selectedLabels.add(labelId);
      }
    });
    widget.onLabelsChanged(_selectedLabels);
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
          // Header fixe
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                
                if (_selectedLabels.isEmpty)
                  _buildEmptyState()
                else
                  _buildSelectedLabelsPreview(),
              ],
            ),
          ),
          
          // Zone scrollable des catégories
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildCategoriesList(),
            ),
          ),
          
          // Espace pour éviter le débordement
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Caractéristiques du spot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aidez les autres à savoir à quoi s\'attendre',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _selectedLabels.isNotEmpty
                ? const Color(0xFF2D5016).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_selectedLabels.length} sélectionnés',
            style: TextStyle(
              color: _selectedLabels.isNotEmpty
                  ? const Color(0xFF2D5016)
                  : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.label_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune caractéristique sélectionnée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Parcourez les catégories ci-dessous',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLabelsPreview() {
    final selectedLabelsData = <LabelData>[];
    
    for (final category in _labelCategories.values) {
      for (final label in category) {
        if (_selectedLabels.contains(label.id)) {
          selectedLabelsData.add(label);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2D5016).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2D5016),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Caractéristiques sélectionnées',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedLabelsData.map((label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: label.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: label.color.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    label.icon,
                    size: 14,
                    color: label.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label.name,
                    style: TextStyle(
                      color: label.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.separated(
      itemCount: _labelCategories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final categoryName = _labelCategories.keys.elementAt(index);
        final labels = _labelCategories[categoryName]!;
        
        return _buildCategorySection(categoryName, labels);
      },
    );
  }

  Widget _buildCategorySection(String categoryName, List<LabelData> labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: labels.map((label) => _buildLabelChip(label)).toList(),
        ),
      ],
    );
  }

  Widget _buildLabelChip(LabelData label) {
    final isSelected = _selectedLabels.contains(label.id);
    
    return GestureDetector(
      onTap: () => _toggleLabel(label.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? label.color.withOpacity(0.15)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? label.color.withOpacity(0.5)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: label.color.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label.icon,
              size: 20,
              color: isSelected ? label.color : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label.name,
              style: TextStyle(
                color: isSelected ? label.color : Colors.grey[700],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 16,
                color: label.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Classe pour les données des labels
class LabelData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const LabelData(this.id, this.name, this.icon, this.color);
}