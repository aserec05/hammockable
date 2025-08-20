import 'package:latlong2/latlong.dart';

class NewSpotData {
  String title;
  String description;
  LatLng? location;
  String? locationName;
  List<String> photoPaths;
  List<String> photoBytes; // Pour le web
  Set<String> selectedLabels;
  bool isPublic;

  NewSpotData({
    this.title = '',
    this.description = '',
    this.location,
    this.locationName,
    this.photoPaths = const [],
    this.photoBytes = const [],
    this.selectedLabels = const {},
    this.isPublic = true,
  });

  bool get isValid {
    return title.trim().isNotEmpty &&
           description.trim().isNotEmpty &&
           location != null &&
           photoPaths.isNotEmpty &&
           selectedLabels.isNotEmpty;
  }

  double get completionPercentage {
    int completed = 0;
    int total = 5;

    if (title.trim().isNotEmpty) completed++;
    if (description.trim().isNotEmpty) completed++;
    if (location != null) completed++;
    if (photoPaths.isNotEmpty) completed++;
    if (selectedLabels.isNotEmpty) completed++;

    return completed / total;
  }

  NewSpotData copyWith({
    String? title,
    String? description,
    LatLng? location,
    String? locationName,
    List<String>? photoPaths,
    List<String>? photoBytes,
    Set<String>? selectedLabels,
    bool? isPublic,
  }) {
    return NewSpotData(
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      photoPaths: photoPaths ?? this.photoPaths,
      photoBytes: photoBytes ?? this.photoBytes,
      selectedLabels: selectedLabels ?? this.selectedLabels,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}