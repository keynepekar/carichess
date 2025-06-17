import 'dart:async';
import 'package:carichess/components/dead_pieces.dart';
import 'package:carichess/components/piece.dart';
import 'package:carichess/components/square.dart';
import 'package:carichess/res/constant/app_colors.dart';
import 'package:carichess/res/helper/helper.dart';
import 'package:carichess/res/helper/score_manager.dart';
import 'package:carichess/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // --- NOUVEAU ---
  String player1Name = '';
  String player2Name = '';
  int wins1 = 0;
  int wins2 = 0;
  int initialSeconds = 0;
  int whiteRemaining = 0;
  int blackRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    _loadGameOptions(); // charge noms, victoires et timer
  }

  Future<void> _loadGameOptions() async {
    final prefs = await SharedPreferences.getInstance();
    player1Name = prefs.getString('player1') ?? 'Joueur 1';
    player2Name = prefs.getString('player2') ?? 'Joueur 2';
    wins1 = prefs.getInt(player1Name) ?? 0;
    wins2 = prefs.getInt(player2Name) ?? 0;
    final timerVal = prefs.getInt('timer') ?? 5;
    initialSeconds = timerVal * 60;
    whiteRemaining = blackRemaining = initialSeconds;
    setState(() {});
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      setState(() {
        if (isWhiteTurn) {
          if (whiteRemaining > 0) whiteRemaining--;
        } else {
          if (blackRemaining > 0) blackRemaining--;
        }
      });

      // Quand le temps blanc est écoulé -> victoire noir
      if (whiteRemaining == 0) {
        _timer?.cancel();
        await incrementScore(player2Name);
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => AlertDialog(
                title: Text(
                  "$player2Name remporte la partie par manque de temps !",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MenuScreen()),
                      );
                    },
                    child: const Text("Menu"),
                  ),
                ],
              ),
        );
      }
      // Quand le temps noir est écoulé -> victoire blanc
      else if (blackRemaining == 0) {
        _timer?.cancel();
        await incrementScore(player1Name);
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => AlertDialog(
                title: Text(
                  "$player1Name remporte la partie par manque de temps !",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MenuScreen()),
                      );
                    },
                    child: const Text("Menu"),
                  ),
                ],
              ),
        );
      }
    });
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
  // --- FIN NOUVEAU ---

  // INITIALIZE BOARD
  void _initializeBoard() {
    List<List<ChessPiece?>> newBoard = List.generate(
      8,
      (index) => List.generate(8, (index) => null),
    );

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

    // Place pawns
    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: false,
        img: 'assets/images/pieces/pawn_b.png',
      );
      newBoard[6][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: true,
        img: 'assets/images/pieces/pawn_w.png',
      );
    }

    // Place rooks
    newBoard[0][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      img: 'assets/images/pieces/rook_b.png',
    );
    newBoard[0][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      img: 'assets/images/pieces/rook_b.png',
    );
    newBoard[7][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      img: 'assets/images/pieces/rook_w.png',
    );
    newBoard[7][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      img: 'assets/images/pieces/rook_w.png',
    );

    // Place knights
    newBoard[0][1] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: false,
      img: 'assets/images/pieces/knight_b.png',
    );
    newBoard[0][6] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: false,
      img: 'assets/images/pieces/knight_b.png',
    );
    newBoard[7][1] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: true,
      img: 'assets/images/pieces/knight_w.png',
    );
    newBoard[7][6] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: true,
      img: 'assets/images/pieces/knight_w.png',
    );

    // Place bishops
    newBoard[0][2] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: false,
      img: 'assets/images/pieces/bishop_b.png',
    );
    newBoard[0][5] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: false,
      img: 'assets/images/pieces/bishop_b.png',
    );
    newBoard[7][2] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: true,
      img: 'assets/images/pieces/bishop_w.png',
    );
    newBoard[7][5] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: true,
      img: 'assets/images/pieces/bishop_w.png',
    );

    // Place queen
    newBoard[0][3] = ChessPiece(
      type: ChessPieceType.queen,
      isWhite: false,
      img: 'assets/images/pieces/queen_b.png',
    );
    newBoard[7][3] = ChessPiece(
      type: ChessPieceType.queen,
      isWhite: true,
      img: 'assets/images/pieces/queen_w.png',
    );

    // Place king
    newBoard[0][4] = ChessPiece(
      type: ChessPieceType.king,
      isWhite: false,
      img: 'assets/images/pieces/king_b.png',
    );
    newBoard[7][4] = ChessPiece(
      type: ChessPieceType.king,
      isWhite: true,
      img: 'assets/images/pieces/king_w.png',
    );

    board = newBoard;
  }

  // USER SELECTED A PIECE
  void selectPiece(int row, int col) {
    setState(() {
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
          validMoves.any((element) => element[0] == row && element[1] == col)) {
        movePiece(row, col);
      }

      // if the piece is selected then calculate the valid moves
      validMoves = calculateRealValidMoves(
        selectedRow,
        selectedCol,
        selectedPiece,
        true,
      );
    });
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
    int row,
    int col,
    ChessPiece? piece,
    bool checkSimulation,
  ) {
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
  Future<void> movePiece(int newRow, int newCol) async {
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

    if (selectedPiece!.type == ChessPieceType.pawn &&
        ((selectedPiece!.isWhite && newRow == 0) ||
            (!selectedPiece!.isWhite && newRow == 7))) {
      // Promotion en dame automatiquement
      selectedPiece = ChessPiece(
        type: ChessPieceType.queen,
        isWhite: selectedPiece!.isWhite,
        img:
            selectedPiece!.isWhite
                ? 'assets/images/pieces/queen_w.png'
                : 'assets/images/pieces/queen_b.png',
      );
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

    // check if it's check mate and handle victory
    if (isCheckMate(!isWhiteTurn)) {
      final winner = isWhiteTurn ? player1Name : player2Name;
      await incrementScore(winner); // met à jour le scoreboard
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AlertDialog(
              title: Text("Bravo ! $winner a remporté la partie."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MenuScreen()),
                    );
                  },
                  child: const Text("Menu"),
                ),
              ],
            ),
      );
      return;
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

        List<List<int>> pieceValidMoves = calculateRealValidMoves(
          i,
          j,
          board[i][j],
          false,
        );
        // check if the king's position is in this peice's valid moves
        if (pieceValidMoves.any(
          (move) => move[0] == kingPosition[0] && move[1] == kingPosition[1],
        )) {
          return true;
        }
      }
    }
    return false;
  }

  // SIMULATED A FUTURE MOVE TO SEE IF IT'S SAFE
  bool simulateMoveIsSafe(
    ChessPiece piece,
    int startRow,
    int startCol,
    int endRow,
    int endCol,
  ) {
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

        List<List<int>> pieceValidMoves = calculateRealValidMoves(
          i,
          j,
          board[i][j],
          true,
        );
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

  /// Construit la FEN de la position actuelle du plateau
  String _buildFenFromBoard() {
    final sb = StringBuffer();
    // 1) Parcours des rangs 8 → 1 (index 7 → 0)
    for (int rank = 7; rank >= 0; rank--) {
      int emptyCount = 0;
      for (int file = 0; file < 8; file++) {
        final piece = board[rank][file];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            sb.write(emptyCount);
            emptyCount = 0;
          }
          // lettre FEN selon la pièce
          String symbol;
          switch (piece.type) {
            case ChessPieceType.pawn:
              symbol = piece.isWhite ? 'P' : 'p';
              break;
            case ChessPieceType.knight:
              symbol = piece.isWhite ? 'N' : 'n';
              break;
            case ChessPieceType.bishop:
              symbol = piece.isWhite ? 'B' : 'b';
              break;
            case ChessPieceType.rook:
              symbol = piece.isWhite ? 'R' : 'r';
              break;
            case ChessPieceType.queen:
              symbol = piece.isWhite ? 'Q' : 'q';
              break;
            case ChessPieceType.king:
              symbol = piece.isWhite ? 'K' : 'k';
              break;
          }
          sb.write(symbol);
        }
      }
      if (emptyCount > 0) sb.write(emptyCount);
      if (rank > 0) sb.write('/');
    }

    // 2) Couleur au trait
    sb.write(isWhiteTurn ? ' w ' : ' b ');

    // 3) Droits de roque (non gérés → '-')
    sb.write('- ');

    // 4) Case en passant (non gérée → '-')
    sb.write('- ');

    // 5) Demi-coups et numéro de coup (par défaut 0 et 1)
    sb.write('0 1');

    return sb.toString();
  }

  /// Applique un coup UCI sur le plateau,
  /// en sélectionnant la pièce et en la déplaçant.
  void _applyBestMove(String uci) {
    // De UCI on extrait file/rank
    int fromFile = uci.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int fromRank = int.parse(uci[1]) - 1;
    int toFile = uci.codeUnitAt(2) - 'a'.codeUnitAt(0);
    int toRank = int.parse(uci[3]) - 1;

    // Positionne la sélection
    selectedRow = fromRank;
    selectedCol = fromFile;
    selectedPiece = board[fromRank][fromFile];

    // Effectue le déplacement
    movePiece(toRank, toFile);
  }

  Future<void> showBestMoveHint() async {
    final String fen = _buildFenFromBoard(); // Convertir l'état actuel en FEN.
    // Optionnel: afficher un dialogue de chargement pendant l'appel réseau.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          ),
    );

    String? sanMove;
    String? comment;
    String? uciMove;
    String errorMessage = '';

    try {
      final response = await http.post(
        Uri.parse('https://chess-api.com/v1'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"fen": fen}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        sanMove = data['san']; // Meilleur coup en notation SAN.
        uciMove = data['move'];
        String text =
            data['text']; // Texte avec évaluation, ex: "Black is winning."
        // Extraire le commentaire court (après "]. "):
        int idx = text.indexOf(']. ');
        if (idx != -1) {
          comment = text.substring(idx + 3); // ex: "Black is winning."
        } else {
          comment = text;
        }
        // Traduire le commentaire en français si besoin:
        if (comment != null) {
          comment = comment
              .replaceAll('White is winning', 'Les Blancs ont l\'avantage')
              .replaceAll('Black is winning', 'Les Noirs ont l\'avantage');
        }
      } else {
        errorMessage =
            "Erreur ${response.statusCode} : échec de l'analyse du coup.";
      }
    } catch (e) {
      errorMessage =
          "Impossible d'obtenir le coup conseillé. Vérifiez la connexion.";
    } finally {
      // Fermer le dialogue de chargement
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }

    if (!mounted) return; // Si le widget a été démonté pendant l'attente.

    // Préparer le contenu du popup en fonction du succès ou de l'erreur
    Widget dialogContent;
    String dialogTitle;
    if (sanMove != null && comment != null) {
      dialogTitle = "Coup recommandé";
      dialogContent = Text(
        "Meilleur coup : $sanMove\nCommentaire : $comment",
        style: TextStyle(fontSize: 16),
      );
    } else {
      dialogTitle = "Triche indisponible";
      dialogContent = Text(
        errorMessage.isNotEmpty
            ? errorMessage
            : "Le service de triche est indisponible pour le moment.",
        style: TextStyle(fontSize: 16),
      );
    }

    // Afficher le résultat dans un AlertDialog
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(dialogTitle),
            content: dialogContent,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
              if (uciMove != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // ferme le dialogue
                    _applyBestMove(uciMove!); // exécute le coup
                  },
                  child: const Text("Effectuer le coup"),
                ),
            ],
          ),
    );
  }

  // Ajout des handlers pour les nouveaux boutons
  Future<void> _offerDraw() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Match nul!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuScreen()),
                  );
                },
                child: const Text('Menu'),
              ),
            ],
          ),
    );
  }

  Future<void> _resign() async {
    final loser = isWhiteTurn ? player1Name : player2Name;
    final winner = isWhiteTurn ? player2Name : player1Name;
    await incrementScore(winner);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text('$loser abandonne. $winner remporte donc la partie !'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuScreen()),
                  );
                },
                child: const Text('Menu'),
              ),
            ],
          ),
    );
  }

  Future<void> _cheat() async {
    await showBestMoveHint();
  }

  @override
  Widget build(BuildContext context) {
    const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 8,
    );
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5122A3), Color(0xFF7C4BD1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // STATUT DE CHECK
              //Text(checkStatus ? "CHECK!" : ""),

              // --- NOUVEAU : INFO JOUEURS & TIMER ---
              Padding(
                // plus de marge à gauche/droite, moins de hauteur
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Joueur 1
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/player1.png',
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          player1Name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$wins1 victoire${wins1 > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Timer
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/timer.png',
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(
                            isWhiteTurn ? whiteRemaining : blackRemaining,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7D56BF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Au tour de\n${isWhiteTurn ? player1Name : player2Name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Joueur 2
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/player2.png',
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          player2Name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$wins2 victoire${wins2 > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // --- FIN NOUVEAU ---

              // WHITE PIECES TAKEN (just above the board)
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

              // CHESS BOARD
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          itemCount: 8 * 8,
                          gridDelegate: gridDelegate,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            // get the row and col position of this square
                            int row = index ~/ 8;
                            int col = index % 8;

                            // check if the square is selected
                            bool isSelected =
                                row == selectedRow && col == selectedCol;

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
                    ),
                  ),
                ),
              ),

              // BLACK PIECES TAKEN (just below the board)
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

              // <-- NOUVEAU : boutons en bas -->
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _offerDraw,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/draw.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nulle',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _resign,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/abandon.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Abandon',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _cheat,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/triche.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Triche',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
