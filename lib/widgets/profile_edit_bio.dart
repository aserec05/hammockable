import 'package:flutter/material.dart';

class ProfileEditBioDialog extends StatelessWidget {
  final String initialBio;

  const ProfileEditBioDialog({super.key, required this.initialBio});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialBio);

    return AlertDialog(
      title: const Text("Modifier ma bio"),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: "Parle de ton style d’aventure...",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D5016),
            foregroundColor: Colors.white,
          ),
          child: const Text("Sauvegarder"),
        ),
      ],
    );
  }
}
