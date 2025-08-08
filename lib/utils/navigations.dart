import 'package:flutter/material.dart';
import 'package:hammockable/screens/login_screen.dart';



// Fonction générique pour naviguer vers n'importe quel widget
void goToScreen(BuildContext context, Widget screen, {
  Duration duration = const Duration(milliseconds: 300),
  Offset beginOffset = const Offset(1.0, 0.0),
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
      transitionDuration: duration,
    ),
  );
}

// Fonction avec animation depuis la gauche
void goToScreenFromLeft(BuildContext context, Widget screen) {
  goToScreen(
    context, 
    screen, 
    beginOffset: const Offset(-1.0, 0.0),
  );
}

void goToLoginScreen(BuildContext context) {
  goToScreen(context, const LoginScreen());
}

// Fonction avec animation depuis le bas
void goToScreenFromBottom(BuildContext context, Widget screen) {
  goToScreen(
    context, 
    screen, 
    beginOffset: const Offset(0.0, 1.0),
  );
}

// Fonction avec fade transition
void goToScreenWithFade(BuildContext context, Widget screen, {
  Duration duration = const Duration(milliseconds: 300),
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: duration,
    ),
  );
}

// Fonction avec scale transition
void goToScreenWithScale(BuildContext context, Widget screen, {
  Duration duration = const Duration(milliseconds: 300),
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          )),
          child: child,
        );
      },
      transitionDuration: duration,
    ),
  );
}

// Fonction de remplacement (remplace l'écran actuel)
void replaceWithScreen(BuildContext context, Widget screen, {
  Duration duration = const Duration(milliseconds: 300),
}) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
      transitionDuration: duration,
    ),
  );
}

// Fonction pour naviguer et vider la pile
void goToScreenAndClearStack(BuildContext context, Widget screen) {
  Navigator.pushAndRemoveUntil(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
    (Route<dynamic> route) => false,
  );
}

// Enum pour les types d'animations
enum TransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  fade,
  scale,
}

// Fonction ultime avec choix d'animation
void navigateToScreen(
  BuildContext context, 
  Widget screen, {
  TransitionType transition = TransitionType.slideFromRight,
  Duration duration = const Duration(milliseconds: 300),
  bool replace = false,
  bool clearStack = false,
}) {
  late PageRouteBuilder route;

  // Définir l'offset selon le type de transition
  Offset getOffset() {
    switch (transition) {
      case TransitionType.slideFromRight:
        return const Offset(1.0, 0.0);
      case TransitionType.slideFromLeft:
        return const Offset(-1.0, 0.0);
      case TransitionType.slideFromBottom:
        return const Offset(0.0, 1.0);
      case TransitionType.slideFromTop:
        return const Offset(0.0, -1.0);
      default:
        return const Offset(1.0, 0.0);
    }
  }

  // Créer la route selon le type d'animation
  route = PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      switch (transition) {
        case TransitionType.fade:
          return FadeTransition(
            opacity: curvedAnimation,
            child: child,
          );
        case TransitionType.scale:
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          );
        default:
          return SlideTransition(
            position: Tween<Offset>(
              begin: getOffset(),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
      }
    },
    transitionDuration: duration,
  );

  // Choisir le type de navigation
  if (clearStack) {
    Navigator.pushAndRemoveUntil(context, route, (route) => false);
  } else if (replace) {
    Navigator.pushReplacement(context, route);
  } else {
    Navigator.push(context, route);
  }
}