import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_avatar.dart';

class RatingCommentWidget extends StatefulWidget {
  final String spotId; // UUID du spot
  
  const RatingCommentWidget({
    super.key, 
    required this.spotId,
  });

  @override
  State<RatingCommentWidget> createState() => _StatefulRatingCommentWidgetState();
}

class _StatefulRatingCommentWidgetState extends State<RatingCommentWidget> {
  int _rating = 0;
  final TextEditingController _controller = TextEditingController();
  final User? currentUser = Supabase.instance.client.auth.currentUser;
  bool _isSubmitting = false;
  bool _hasExistingRating = false;
  bool _isLoading = true;
  Map<String, dynamic>? _existingRatingData;

  @override
  void initState() {
    super.initState();
    _checkExistingRating();
  }

  Future<void> _checkExistingRating() async {
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('ratings')
          .select('mark, comment, created_at')
          .eq('spot_id', widget.spotId)
          .eq('user_id', currentUser!.id)
          .maybeSingle();

      setState(() {
        _hasExistingRating = response != null;
        _existingRatingData = response;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Erreur lors de la vérification : $error');
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez donner une note avant d\'envoyer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour laisser un avis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Insertion dans la table ratings
      await Supabase.instance.client.from('ratings').insert({
        'spot_id': widget.spotId, // UUID du spot
        'user_id': currentUser!.id, // UUID de l'utilisateur
        'mark': _rating, // int2 (1-5)
        'comment': _controller.text.trim().isEmpty ? null : _controller.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis envoyé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset du formulaire
        _controller.clear();
        setState(() {
          _rating = 0;
        });
        
        // Recharger pour vérifier l'état
        _checkExistingRating();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi : $error'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasExistingRating) {
      return _buildExistingRatingDisplay();
    }

    return _buildRatingForm();
  }

  Widget _buildExistingRatingDisplay() {
    final rating = _existingRatingData!['mark'] as int;
    final comment = _existingRatingData!['comment'] as String?;
    final createdAt = DateTime.parse(_existingRatingData!['created_at']);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Votre avis a été envoyé',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              UserAvatar(avatarUrl: currentUser?.userMetadata?['avatar_url']),
              const SizedBox(width: 8),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    color: index < rating ? Colors.amber : Colors.grey[300],
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '$rating/5',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comment,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Publié le ${_formatDate(createdAt)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatar(avatarUrl: currentUser?.userMetadata?['avatar_url']),
            const SizedBox(width: 8),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: _isSubmitting ? null : () {
                    setState(() {
                      _rating = index + 1; // int au lieu de double
                    });
                  },
                  icon: Icon(
                    Icons.star,
                    color: index < _rating ? Colors.amber : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            if (_rating > 0)
              Text(
                '$_rating/5', // Plus besoin de toInt()
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          enabled: !_isSubmitting,
          maxLines: 3,
          maxLength: 500, // Limite de caractères
          decoration: InputDecoration(
            hintText: 'Écris ton avis ici... (optionnel)',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitRating,
            icon: _isSubmitting 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send),
            label: Text(_isSubmitting ? 'Envoi...' : 'Envoyer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}