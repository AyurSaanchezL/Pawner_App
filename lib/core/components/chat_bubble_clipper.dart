import 'package:flutter/material.dart';

class ChatBubbleClipper extends CustomClipper<Path> {
  final bool isRight;

  ChatBubbleClipper({required this.isRight});

  @override
  Path getClip(Size size) {
    var path = Path();
    double radius = 25;
    double tailWidth = 20;
    double tailHeight = 15;

    if (isRight) {
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius));
      path.lineTo(size.width, size.height - tailHeight - radius);
      path.arcToPoint(Offset(size.width - radius, size.height - tailHeight), radius: Radius.circular(radius));
      
      // Tail on the right
      path.lineTo(size.width - radius - 5, size.height - tailHeight);
      path.lineTo(size.width - radius + 5, size.height);
      path.lineTo(size.width - radius - 20, size.height - tailHeight);
      
      path.lineTo(radius, size.height - tailHeight);
      path.arcToPoint(Offset(0, size.height - tailHeight - radius), radius: Radius.circular(radius));
      path.lineTo(0, radius);
      path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    } else {
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius));
      path.lineTo(size.width, size.height - tailHeight - radius);
      path.arcToPoint(Offset(size.width - radius, size.height - tailHeight), radius: Radius.circular(radius));
      path.lineTo(radius + tailWidth, size.height - tailHeight);
      
      // Tail on the left
      path.lineTo(radius + 15, size.height - tailHeight);
      path.lineTo(radius - 5, size.height);
      path.lineTo(radius + 5, size.height - tailHeight);
      
      path.lineTo(radius, size.height - tailHeight);
      path.arcToPoint(Offset(0, size.height - tailHeight - radius), radius: Radius.circular(radius));
      path.lineTo(0, radius);
      path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SimpleChatBubbleClipper extends CustomClipper<Path> {
  final bool isRight;

  SimpleChatBubbleClipper({required this.isRight});

  @override
  Path getClip(Size size) {
    var path = Path();
    double radius = 25;
    double tailHeight = 12;

    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius));
    path.lineTo(size.width, size.height - tailHeight - radius);
    path.arcToPoint(Offset(size.width - radius, size.height - tailHeight), radius: Radius.circular(radius));
    
    if (isRight) {
      path.lineTo(size.width * 0.8, size.height - tailHeight);
      path.lineTo(size.width * 0.85, size.height);
      path.lineTo(size.width * 0.7, size.height - tailHeight);
    } else {
      path.lineTo(size.width * 0.3, size.height - tailHeight);
      path.lineTo(size.width * 0.15, size.height);
      path.lineTo(size.width * 0.2, size.height - tailHeight);
    }

    path.lineTo(radius, size.height - tailHeight);
    path.arcToPoint(Offset(0, size.height - tailHeight - radius), radius: Radius.circular(radius));
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
