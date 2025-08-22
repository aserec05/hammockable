import '../models/spot_data.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'label_icon_widget.dart';
class SpotModal extends StatelessWidget {
  final SpotData spot;
  final VoidCallback onViewDetails;
  final VoidCallback onClose;

  const SpotModal({
    super.key,
    required this.spot,
    required this.onViewDetails,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle pour glisser
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Carte principale
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image principale
                if (spot.photoUrl != null && spot.photoUrl!.isNotEmpty)
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
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
                          ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                          // Bouton fermer
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: onClose,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Contenu textuel
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et catégorie
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              spot.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (spot.category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D5016).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                spot.category!,
                                style: const TextStyle(
                                  color: Color(0xFF2D5016),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Rating, nombre d'avis et difficulté
                      Row(
                        children: [
                          // Afficher la note seulement s'il y a des avis
                          if (spot.reviewCount! > 0) ...[
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              spot.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${spot.reviewCount})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ] else ...[
                            // Cas où il n'y a aucun avis
                            Icon(Icons.star_outline, color: Colors.grey[400], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Aucun avis',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          
                          // Labels
                          if (spot.labels != null && spot.labels!.isNotEmpty) ...[
                            LabelIconsWidget(
                              labels: spot.labels,
                              maxIcons: 4,
                              iconSize: 14,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Description (limitée)
                      Text(
                        spot.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Bouton "Voir les détails"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onViewDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5016),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Voir les détails',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
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