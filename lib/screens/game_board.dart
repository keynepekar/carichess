import 'package:carichess/components/dead_pieces.dart';
import 'package:carichess/components/piece.dart';
import 'package:carichess/components/square.dart';
import 'package:carichess/res/constant/app_colors.dart';
import 'package:carichess/res/helper/helper.dart';
import 'package:flutter/material.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // A 2-dimesional list represeting the chessboard,
  // with each position possibly containe a chess piece,
  late List<List<ChessPiece?>> board;

  // The currently selected piece on the chess board,
  // If no piece is selecte, this is null.
  ChessPiece? selectedPiece;

  // The row index of the selected piece
  // Default value of -1 indicated no piece is currently selected.
  int selectedRow = -1;

  // The col index of the selected piece
  // Default value of -1 indicated no piece is currently selected.
  int selectedCol = -1;

  // A list of valid moves for the currently selected pieces
  // each moves is represented as a list with 2 elements : row and col
  List<List<int>> validMoves = [];

  // A list of white pieces that have been taken by black pieces
  List<ChessPiece?> whiteKilledPieces = [];

  // A list of black pieces that have been taken by white pieces
  List<ChessPiece?> blackKilledPieces = [];

  // A boolen to indicate whose turn it is
  bool isWhiteTurn = true;

  // inital position of kings ( keep track of it to make it easier later to see if king is in check )
  List<int> whiteKingPosition = [7, 4];
  List<int> blackKingPosition = [0, 4];
  bool checkStatus = false;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

// INITIALIZE BOARD
  void _initializeBoard() {
    List<List<ChessPiece?>> newBoard =
        List.generate(8, (index) => List.generate(8, (index) => null));

// output of above code
// [
//   [null, null, null, null, null, null, null, null],
//   [null, null, null, null, null, null, null, null],
//   [null, null, null, null, null, null, null, null],
//   [null, null, null, null, null, null, null, null],
//   [null, null, null, null, null, null, null, null],
//   [null, null, null, null, null, null, null, null],
//   [null, null, null, null, null, null, null, null],
//   [null, null, null, null, null, null, null, null]
// ]

    const String pawnImg = "assets/images/pawn.png";
    const String rookImg = "assets/images/rook.png";
    const String knightImg = "assets/images/knight.png";
    const String bishopImg = "assets/images/bishop.png";
    const String queenImg = "assets/images/queen.png";
    const String kingImg = "assets/images/king.png";

    // Place pawns
    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: false,
        img: pawnImg,
      );
      newBoard[6][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: true,
        img: pawnImg,
      );
    }

    // Place rooks
    newBoard[0][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      img: rookImg,
    );
    newBoard[0][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      img: rookImg,
    );
    newBoard[7][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      img: rookImg,
    );
    newBoard[7][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      img: rookImg,
    );

    // Place knights
    newBoard[0][1] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: false,
      img: knightImg,
    );
    newBoard[0][6] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: false,
      img: knightImg,
    );
    newBoard[7][1] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: true,
      img: knightImg,
    );
    newBoard[7][6] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: true,
      img: knightImg,
    );

    // Place bishops
    newBoard[0][2] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: false,
      img: bishopImg,
    );
    newBoard[0][5] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: false,
      img: bishopImg,
    );
    newBoard[7][2] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: true,
      img: bishopImg,
    );
    newBoard[7][5] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: true,
      img: bishopImg,
    );

    // Place queen
    newBoard[0][3] = ChessPiece(
      type: ChessPieceType.queen,
      isWhite: false,
      img: queenImg,
    );
    newBoard[7][3] = ChessPiece(
      type: ChessPieceType.queen,
      isWhite: true,
      img: queenImg,
    );

    // Place king
    newBoard[0][4] = ChessPiece(
      type: ChessPieceType.king,
      isWhite: false,
      img: kingImg,
    );
    newBoard[7][4] = ChessPiece(
      type: ChessPieceType.king,
      isWhite: true,
      img: kingImg,
    );

    board = newBoard;
  }

// USER SELECTED A PIECE
  void selectPiece(int row, int col) {
    setState(
      () {
        // no piece has been selected yet, this is the first selection
        if (selectedPiece == null && board[row][col] != null) {
          if (board[row][col]!.isWhite == isWhiteTurn) {
            selectedPiece = board[row][col];
            selectedRow = row;
            selectedCol = col;
          }
        }

        // There is a piece already selected, but user can select another one of their piece
        else if (board[row][col] != null &&
            board[row][col]!.isWhite == selectedPiece!.isWhite) {
          selectedPiece = board[row][col];
          selectedRow = row;
          selectedCol = col;
        }

        // if there is a piece selected and user taps on a square that is a valid move, move there
        else if (selectedPiece != null &&
            validMoves
                .any((element) => element[0] == row && element[1] == col)) {
          movePiece(row, col);
        }

        // if the piece is selected then calculate the valid moves
        validMoves = calculateRealValidMoves(
          selectedRow,
          selectedCol,
          selectedPiece,
          true,
        );
      },
    );
  }

// CALCULATE RAW VALID MOVES
  List<List<int>> calculateRawValidMoves(int row, int col, ChessPiece? piece) {
    List<List<int>> candidateMoves = [];
    if (piece == null) {
      return [];
    }
    // different directions based on their color
    int direction = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPieceType.pawn:
        // pawns can move forward if the square is not occupied
        if (Helper.isInBoard(row + direction, col) &&
            board[row + direction][col] == null) {
          candidateMoves.add([row + direction, col]);
        }

        // pawns can move 2 square forward if they are at their  initial position
        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)) {
          if (Helper.isInBoard(row + 2 * direction, col) &&
              board[row + 2 * direction][col] == null &&
              board[row + direction][col] == null) {
            candidateMoves.add([row + 2 * direction, col]);
          }
        }

        // pawn can capture diagonally
        if (Helper.isInBoard(row + direction, col - 1) &&
            board[row + direction][col - 1] != null &&
            board[row + direction][col - 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + direction, col - 1]);
        }

        if (Helper.isInBoard(row + direction, col + 1) &&
            board[row + direction][col + 1] != null &&
            board[row + direction][col + 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + direction, col + 1]);
        }
        break;

      case ChessPieceType.rook:
        // horizontal and vertical direction
        var directions = [
          [-1, 0], // up
          [1, 0], // down
          [0, -1], // left
          [0, 1], //right
        ];

        for (var direction in directions) {
          int i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!Helper.isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); // kill
              }
              break; // blocked
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPieceType.knight:
        // all eight possible L shapes the knights can move
        var knightMoves = [
          [-2, -1], // up 2 left 1
          [-2, 1], // up 2 right 1
          [-1, -2], // up 1 left 2
          [-1, 2], // up 1 right 2
          [1, -2], // down 1 left 2
          [1, 2], // down 1 right 2
          [2, -1], // down 2 left 1
          [2, 1], // down 2 right 1
        ];

        for (var move in knightMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];
          if (!Helper.isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]); // kill
            }
            continue; // blocked
          }
          candidateMoves.add([newRow, newCol]);
        }
        break;

      case ChessPieceType.bishop:
        // diagonal direction
        var directions = [
          [-1, -1], // up left
          [-1, 1], // up right
          [1, 1], // down right
          [1, -1], // down left
        ];

        for (var direction in directions) {
          int i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!Helper.isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); // kill
              }
              break; // blocked
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPieceType.queen:
        // all eight directions: up, down, left, right, and 4 diagonal.
        var directions = [
          [-1, 0], // up
          [1, 0], // down
          [0, -1], // left
          [0, 1], //right
          [-1, -1], // up left
          [-1, 1], // up right
          [1, 1], // down right
          [1, -1], // down left
        ];

        for (var direction in directions) {
          int i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!Helper.isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); // kill
              }
              break; // blocked
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;
      case ChessPieceType.king:
        // all eight directions: up, down, left, right, and 4 diagonal.
        var directions = [
          [-1, 0], // up
          [1, 0], // down
          [0, -1], // left
          [0, 1], //right
          [-1, -1], // up left
          [-1, 1], // up right
          [1, 1], // down right
          [1, -1], // down left
        ];

        for (var direction in directions) {
          var newRow = row + direction[0];
          var newCol = col + direction[1];
          if (!Helper.isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]); // kill
            }
            continue; // blocked
          }
          candidateMoves.add([newRow, newCol]);
        }
        break;
      default:
    }
    return candidateMoves;
  }

// CALCULATE REAL VALID MOVES
  List<List<int>> calculateRealValidMoves(
      int row, int col, ChessPiece? piece, bool checkSimulation) {
    List<List<int>> realValidMoves = [];
    List<List<int>> candiateMoves = calculateRawValidMoves(row, col, piece);

    // after generating all candiate moves, filter out any that would result in check
    if (checkSimulation) {
      for (var move in candiateMoves) {
        int endRow = move[0];
        int endCol = move[1];

        // this will simulate the future move to see if it's safe
        if (simulateMoveIsSafe(piece!, row, col, endRow, endCol)) {
          realValidMoves.add(move);
        }
      }
    } else {
      realValidMoves = candiateMoves;
    }
    return realValidMoves;
  }

// MOVE PIECE
  void movePiece(int newRow, int newCol) {
    // if the new spot has an ennemy piece
    if (board[newRow][newCol] != null) {
      // add the captured piece to the approriate list
      var capturedPiece = board[newRow][newCol];
      if (capturedPiece!.isWhite) {
        whiteKilledPieces.add(capturedPiece);
      } else {
        blackKilledPieces.add(capturedPiece);
      }
    }

    // check if the piece being moved is a king
    if (selectedPiece!.type == ChessPieceType.king) {
      // update the appropriate king position
      if (selectedPiece!.isWhite) {
        whiteKingPosition = [newRow, newCol];
      } else {
        blackKingPosition = [newRow, newCol];
      }
    }

    // move the piece and clear the old spot
    board[newRow][newCol] = selectedPiece;
    board[selectedRow][selectedCol] = null;

    // see if any kings are under attack
    if (isKingInCheck(!isWhiteTurn)) {
      checkStatus = true;
    } else {
      checkStatus = false;
    }

    // clear selection
    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
    });

    // check if it's check mate
    if (isCheckMate(!isWhiteTurn)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("CHECK MATE!"),
            actions: [
              TextButton(
                onPressed: resetGame,
                child: const Text("Play again"),
              )
            ],
          );
        },
      );
    }

    // change turn
    isWhiteTurn = !isWhiteTurn;
  }

// IS KING IN CHECK?
  bool isKingInCheck(bool isWhiteKing) {
    // get the postion of the king
    List<int> kingPosition =
        isWhiteKing ? whiteKingPosition : blackKingPosition;

    // check if any emeny piece can attack the king
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // skip the empty square and pieces of the same color as the king
        if (board[i][j] == null || board[i][j]!.isWhite == isWhiteKing) {
          continue;
        }

        List<List<int>> pieceValidMoves =
            calculateRealValidMoves(i, j, board[i][j], false);
        // check if the king's position is in this peice's valid moves
        if (pieceValidMoves.any((move) =>
            move[0] == kingPosition[0] && move[1] == kingPosition[1])) {
          return true;
        }
      }
    }
    return false;
  }

// SIMULATED A FUTURE MOVE TO SEE IF IT'S SAFE
  bool simulateMoveIsSafe(
      ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
    // save the cuurent board state
    ChessPiece? originalDestinationPiece = board[endRow][endCol];

    // if the piece is the king, save it's current postion and update to the new one
    List<int>? originalKingPosition;
    if (piece.type == ChessPieceType.king) {
      originalKingPosition =
          piece.isWhite ? whiteKingPosition : blackKingPosition;
      // update the king position
      if (piece.isWhite) {
        whiteKingPosition = [endRow, endCol];
      } else {
        blackKingPosition = [endRow, endCol];
      }
    }

    // simulate the move
    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    // check if our own king is under attack
    bool kingInCheck = isKingInCheck(piece.isWhite);

    // restore board to original state
    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    // if the piece was the king, restore it original position
    if (piece.type == ChessPieceType.king) {
      if (piece.isWhite) {
        whiteKingPosition = originalKingPosition!;
      } else {
        blackKingPosition = originalKingPosition!;
      }
    }

    // if king is in check = true; means it's not a safe move. safe move = false
    return !kingInCheck;
  }

// IS CHECK MATE?
  bool isCheckMate(bool isWhiteKing) {
    // if the king is not in check, then it's not checkmate
    if (!isKingInCheck(isWhiteKing)) {
      return false;
    }

    // if there is atleast one legal move for any of the player pieces, then it's not checkmate
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // skip the empty square and pieces of the same color as the king
        if (board[i][j] == null || board[i][j]!.isWhite != isWhiteKing) {
          continue;
        }

        List<List<int>> pieceValidMoves =
            calculateRealValidMoves(i, j, board[i][j], true);
        // check if the king's position is in this peice's valid moves
        if (pieceValidMoves.isNotEmpty) {
          return false;
        }
      }
    }

    // if none of the above condition are met, then there is not legal move left to make
    // its check mate
    return true;
  }

// RESET FOR NEW GAME4
  void resetGame() {
    Navigator.pop(context);
    _initializeBoard();
    checkStatus = false;
    whiteKilledPieces.clear();
    blackKilledPieces.clear();
    whiteKingPosition = [7, 4];
    blackKingPosition = [0, 4];
    isWhiteTurn = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const gridDelegate =
        SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8);
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // WHITE PIECES TAKEN
            Expanded(
              child: GridView.builder(
                itemCount: whiteKilledPieces.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  return DeadPieces(
                    imgPath: whiteKilledPieces[index]!.img,
                    isWhite: true,
                  );
                },
              ),
            ),
            // GAME STATUS
            Text(checkStatus ? "CHECK!" : ""),
            // CHESS BOARD
            Expanded(
              flex: 3,
              child: GridView.builder(
                itemCount: 8 * 8,
                gridDelegate: gridDelegate,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  // get the row and col position of this square
                  int row = index ~/ 8;
                  int col = index % 8;

                  // check if the square is selected
                  bool isSelected = row == selectedRow && col == selectedCol;

                  // check if this square is a valid move
                  bool isValidMove = false;
                  for (var position in validMoves) {
                    // compare row and col
                    if (position[0] == row && position[1] == col) {
                      isValidMove = true;
                    }
                  }
                  return Square(
                    isWhite: Helper.isWhite(index),
                    piece: board[row][col],
                    isSelected: isSelected,
                    isValidMove: isValidMove,
                    onTap: () => selectPiece(row, col),
                  );
                },
              ),
            ),
            // BLACK PIECES TAKEN
            Expanded(
              child: GridView.builder(
                itemCount: blackKilledPieces.length,
                gridDelegate: gridDelegate,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return DeadPieces(
                    imgPath: blackKilledPieces[index]!.img,
                    isWhite: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
# Steps to create chess
 1. Desgin game borad 
 2. Place chess pieces
 3. Select piece
 4. Define logic of each pieces
 5. Dead piece
 6. Is kind is Checked?

*/
