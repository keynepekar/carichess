// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:carichess/components/piece.dart';

class Square extends StatelessWidget {
  final bool isWhite;
  final ChessPiece? piece;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isValidMove;
  const Square({
    Key? key,
    required this.isWhite,
    this.piece,
    required this.isSelected,
    required this.onTap,
    required this.isValidMove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    // if selected, square will be green
    if (isSelected) {
      backgroundColor = Colors.green;
    }
    // if is valid move, square will be green accent
    else if (isValidMove) {
      backgroundColor = Colors.greenAccent;
    }
    // otherwise, square will be white or black
    else {
      backgroundColor = (isWhite ? Colors.purple[100] : Colors.purple[300])!;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1), // Keep border consistent
          color: backgroundColor, // Use dynamic background color
        ),
        child: piece != null
            ? Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  piece!.img,
                  color: piece!.isWhite ? Colors.white : Colors.black,
                  filterQuality: FilterQuality.high,
                ),
              )
            : null,
      ),
    );
  }
}
