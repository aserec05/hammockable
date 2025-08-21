import 'package:flutter/material.dart';

class LabelData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const LabelData(this.id, this.name, this.icon, this.color);
}

// Labels regroupés par catégories
const Map<String, List<LabelData>> labelCategories = {
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

// Un index rapide par id (pour lookup facile)
final Map<String, LabelData> allLabelsById = {
  for (var entry in labelCategories.entries)
    for (var label in entry.value) label.id: label
};