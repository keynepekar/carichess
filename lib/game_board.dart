import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'components/square.dart';
import 'helper/helper_methods.dart';
import 'components/piece.dart';
import 'package:carichess/values/colors.dart';

class GameBoard extends StatefulWidget{
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // Initialisation directe d'une grille 8x8 remplie de null
  List<List<ChessPiece?>> newBoard = List.generate(8, (_) => List.generate(8, (_) => null));

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  // Initialiser le board avec quelques pièces
  void _initializeBoard() {
    // Placer les pawns (pions)
    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: false,
        imagePath: "lib/assets/pawn.png",
      );
      newBoard[6][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: false,
        imagePath: "lib/assets/pawn.png",
      );
    }
    // Vous pouvez ajouter d'autres pièces ici...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: GridView.builder(
        itemCount: 8 * 8,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemBuilder: (context, index) {
          int row = index ~/ 8;
          int col = index % 8;
          return Square(
            isWhite: isWhite(index),
            piece: newBoard[row][col],
          );
        },
      ),
    );
  }
}
