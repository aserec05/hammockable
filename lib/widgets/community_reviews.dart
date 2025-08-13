import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_avatar.dart';
import '../models/user_profile.dart';

class CommunityReviewsWidget extends StatefulWidget {
  final String spotId;
  
  const CommunityReviewsWidget({
    super.key,
    required this.spotId,
  });

  @override
  State<CommunityReviewsWidget> createState() => _CommunityReviewsWidgetState();
}

class _CommunityReviewsWidgetState extends State<CommunityReviewsWidget> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  final User? currentUser = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      // Utilisation de la vue ratings_with_users pour récupérer les infos utilisateur
      final response = await Supabase.instance.client
          .from('ratings_with_users')
          .select('mark, comment, created_at, user_id, user_display_name, user_avatar_url, email')
          .eq('spot_id', widget.spotId)
          .order('created_at', ascending: false);

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Erreur lors du chargement des avis : $error');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section
        Row(
          children: [
            const Text(
              'Avis de la communauté',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_reviews.length}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Contenu
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline, 
                  color: Colors.grey[400], 
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucun avis pour le moment',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Soyez le premier à partager votre expérience !',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildReviewCard(_reviews[index]);
            },
          ),
      ],
    );
  }

  // Dans le fichier CommunityReviewsWidget, modifier la méthode _buildReviewCard :

// Dans CommunityReviewsWidget, maintenant vous pouvez simplement faire :

Widget _buildReviewCard(Map<String, dynamic> review) {
  final mark = review['mark'] as int;
  final comment = review['comment'] as String?;
  final createdAt = DateTime.parse(review['created_at']);
  final userId = review['user_id'] as String;
  
  // User info from the view
  final userDisplayName = review['user_display_name'] as String?;
  final avatarUrl = review['user_avatar_url'] as String?;
  final email = review['email'] as String?;
  
  final userProfile = UserProfile(
    id: userId,
    displayName: userDisplayName,
    avatarUrl: avatarUrl,
    email: email,
  );
  
  final displayName = userDisplayName?.isNotEmpty == true
      ? userDisplayName!
      : email?.split('@').first ?? 'Voyageur ${userId.substring(0, 6).toUpperCase()}';
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatar(userProfile: userProfile),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            color: index < mark ? Colors.amber : Colors.grey[300],
                            size: 18,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$mark/5',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (comment != null && comment.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      comment,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}