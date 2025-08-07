class SpotData {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lon;
  final String? photoUrl;
  final List<String>? additionalPhotos;
  final String? category;
  final double? rating;
  final String? difficulty;
  final List<String>? amenities;

  SpotData({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lon,
    this.photoUrl,
    this.additionalPhotos,
    this.category,
    this.rating,
    this.difficulty,
    this.amenities,
  });

  
}