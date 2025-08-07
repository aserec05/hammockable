import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const UserAvatar({
    Key? key,
    required this.avatarUrl,
    this.radius = 30.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si l'URL est nulle ou vide, on affiche un avatar par défaut
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: const Icon(Icons.person),
      );
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        child: const CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        child: const Icon(Icons.person),
      ),
    );
  }
}
