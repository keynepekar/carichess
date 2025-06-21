import 'package:flutter/material.dart';

class DeadPieces extends StatelessWidget {
  final String imgPath;
  final bool isWhite;
  const DeadPieces({super.key, required this.imgPath, required this.isWhite});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(
        imgPath,
        color: Colors.grey.withAlpha((0.5 * 255).toInt()),
        colorBlendMode: BlendMode.srcATop,
        width: 50,
        height: 50,
      ),
    );
  }
}
