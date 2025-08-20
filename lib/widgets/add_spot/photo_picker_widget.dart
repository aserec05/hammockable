import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:html' as html;
import 'dart:typed_data';

class PhotoPickerWidget extends StatefulWidget {
  final List<String> initialPhotoPaths;
  final List<String> initialPhotoBytes;
  final Function(List<String> paths, List<String> bytes) onPhotosChanged;

  const PhotoPickerWidget({
    super.key,
    this.initialPhotoPaths = const [],
    this.initialPhotoBytes = const [],
    required this.onPhotosChanged,
  });

  @override
  State<PhotoPickerWidget> createState() => _PhotoPickerWidgetState();
}

class _PhotoPickerWidgetState extends State<PhotoPickerWidget> {
  static const int maxPhotos = 5;
  final ImagePicker _picker = ImagePicker();

  List<String> _photoPaths = [];
  List<Uint8List> _photoBytes = []; // Pour le web
  List<String> _photoByteStrings = []; // Conversion en base64 pour stockage

  @override
  void initState() {
    super.initState();
    _photoPaths = List.from(widget.initialPhotoPaths);
    // TODO: Reconvertir les bytes depuis base64 si nécessaire
  }

  Future<void> _pickImage() async {
    if (_photoPaths.length + _photoBytes.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxPhotos photos autorisées'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (kIsWeb) {
      await _pickImageWeb();
    } else {
      await _pickImageMobile();
    }
  }

  Future<void> _pickImageWeb() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.multiple = true;
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      for (final file in files) {
        if (_photoBytes.length >= maxPhotos) break;

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          final bytes = reader.result as Uint8List;
          setState(() {
            _photoBytes.add(bytes);
          });
          _updateParent();
        });
      }
    });
  }

  Future<void> _pickImageMobile() async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      if (source == ImageSource.gallery) {
        // Sélection d'une seule image à la fois pour la compatibilité
        final XFile? image = await _picker.pickImage(
          source: source,
          maxHeight: 1920,
          maxWidth: 1920,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _photoPaths.add(image.path);
          });
        }
      } else {
        // Une seule photo pour l'appareil photo
        final XFile? image = await _picker.pickImage(
          source: source,
          maxHeight: 1920,
          maxWidth: 1920,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _photoPaths.add(image.path);
          });
        }
      }

      _updateParent();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une source'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF2D5016),
                ),
              ),
              title: const Text('Galerie'),
              subtitle: const Text('Sélectionner plusieurs photos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF2D5016),
                ),
              ),
              title: const Text('Appareil photo'),
              subtitle: const Text('Prendre une nouvelle photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index, {bool isBytes = false}) {
    setState(() {
      if (isBytes) {
        _photoBytes.removeAt(index);
      } else {
        _photoPaths.removeAt(index);
      }
    });
    _updateParent();
  }

  void _reorderPhotos(int oldIndex, int newIndex, {bool isBytes = false}) {
    setState(() {
      if (isBytes) {
        if (newIndex > oldIndex) newIndex--;
        final item = _photoBytes.removeAt(oldIndex);
        _photoBytes.insert(newIndex, item);
      } else {
        if (newIndex > oldIndex) newIndex--;
        final item = _photoPaths.removeAt(oldIndex);
        _photoPaths.insert(newIndex, item);
      }
    });
    _updateParent();
  }

  void _updateParent() {
    // Convertir les bytes en base64 pour le stockage
    final bytesAsStrings = _photoBytes.map((bytes) {
      // Ici vous pourriez convertir en base64 si nécessaire
      return bytes.toString();
    }).toList();

    widget.onPhotosChanged(_photoPaths, bytesAsStrings);
  }

  @override
  Widget build(BuildContext context) {
    final totalPhotos = _photoPaths.length + _photoBytes.length;
    
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(totalPhotos),
            const SizedBox(height: 20),
            
            if (totalPhotos == 0) 
              _buildEmptyState()
            else
              _buildPhotoGrid(),
              
            const SizedBox(height: 20),
            _buildAddButton(),
            
            if (totalPhotos > 0) ...[
              const SizedBox(height: 16),
              _buildPhotoTips(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int totalPhotos) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photos du spot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ajoutez jusqu\'à $maxPhotos photos pour présenter votre spot',
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
            color: totalPhotos > 0 
                ? const Color(0xFF2D5016).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$totalPhotos/$maxPhotos',
            style: TextStyle(
              color: totalPhotos > 0 
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
      height: 200,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune photo ajoutée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Appuyez sur le bouton ci-dessous pour ajouter des photos',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final totalPhotos = _photoPaths.length + _photoBytes.length;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: totalPhotos,
      itemBuilder: (context, index) {
        if (index < _photoPaths.length) {
          return _buildPhotoItem(
            index: index,
            path: _photoPaths[index],
            isBytes: false,
          );
        } else {
          return _buildPhotoItem(
            index: index - _photoPaths.length,
            bytes: _photoBytes[index - _photoPaths.length],
            isBytes: true,
          );
        }
      },
    );
  }

  Widget _buildPhotoItem({
    required int index,
    String? path,
    Uint8List? bytes,
    required bool isBytes,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: kIsWeb && bytes != null
                  ? Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : path != null
                      ? Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
            ),
          ),
        ),
        
        // Badge de position
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: index == 0 
                  ? const Color(0xFF2D5016)
                  : Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        
        // Badge "Principale" pour la première photo
        if (index == 0)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Principale',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        
        // Bouton de suppression
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removePhoto(index, isBytes: isBytes),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        
        // Gestion du drag pour réorganiser
        Positioned.fill(
          child: LongPressDraggable<int>(
            data: index,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb && bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : path != null
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : Container(color: Colors.grey[300]),
                ),
              ),
            ),
            childWhenDragging: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
            child: DragTarget<int>(
              onAccept: (draggedIndex) {
                _reorderPhotos(draggedIndex, index, isBytes: isBytes);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: candidateData.isNotEmpty
                        ? Border.all(color: const Color(0xFF2D5016), width: 2)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    final canAddMore = (_photoPaths.length + _photoBytes.length) < maxPhotos;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: canAddMore ? _pickImage : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canAddMore 
              ? const Color(0xFF2D5016)
              : Colors.grey[300],
          foregroundColor: canAddMore 
              ? Colors.white
              : Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canAddMore ? 2 : 0,
        ),
        icon: Icon(
          canAddMore ? Icons.add_photo_alternate : Icons.block,
          size: 24,
        ),
        label: Text(
          canAddMore 
              ? 'Ajouter des photos'
              : 'Limite de $maxPhotos photos atteinte',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D5016).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Color(0xFF2D5016),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Conseils pour de belles photos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildTipsList(),
        ],
      ),
    );
  }

  List<Widget> _buildTipsList() {
    final tips = [
      'La première photo sera utilisée comme photo principale',
      'Maintenez appuyé pour réorganiser vos photos',
      'Variez les angles: vue d\'ensemble, détails, environnement',
      'Évitez les photos floues ou trop sombres',
    ];

    return tips.map((tip) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016).withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }
}