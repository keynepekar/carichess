import 'package:flutter/material.dart';

import 'package:carichess/components/piece.dart';

class Square extends StatelessWidget {
  final bool isWhite;
  final ChessPiece? piece;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isValidMove;
  const Square({
    super.key,
    required this.isWhite,
    this.piece,
    required this.isSelected,
    required this.onTap,
    required this.isValidMove,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (isSelected) {
      backgroundColor = const Color(0xFF927CCC);
    } else if (isValidMove) {
      backgroundColor = const Color(0xFFB1A7FC);
    } else {
      backgroundColor =
          isWhite ? const Color(0xFFE8EDF9) : const Color(0xFFB7C0D8);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
          color: backgroundColor,
        ),
        child: piece != null
            ? Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  piece!.img,
                  filterQuality: FilterQuality.high,
                ),
              )
            : null,
      ),
    );
  }
}
