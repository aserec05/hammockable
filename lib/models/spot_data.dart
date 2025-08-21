// models/spot_data.dart
class SpotData {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lon;
  final String? photoUrl;
  final double? rating;
  final String? category;
  final List<String>? amenities;
  final List<Map<String, dynamic>>? labels; // Ajout des labels

  SpotData({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lon,
    this.photoUrl,
    this.rating,
    this.category,
    this.amenities,
    this.labels,
  });

  factory SpotData.fromJson(Map<String, dynamic> json) {
    return SpotData(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      lat: json['lat'],
      lon: json['lon'],
      photoUrl: json['photo_url'],
      rating: json['rating']?.toDouble(),
      category: json['category'],
      amenities: json['amenities'] != null 
          ? List<String>.from(json['amenities'])
          : null,
      labels: json['labels'] != null
          ? List<Map<String, dynamic>>.from(json['labels'])
          : null,
    );
  }
}