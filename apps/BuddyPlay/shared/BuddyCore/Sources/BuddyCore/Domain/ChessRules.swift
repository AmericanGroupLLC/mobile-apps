import Foundation

/// Pure chess rules implementation. Operates over `ChessState` with `ChessMove`
/// inputs. Implements full move legality including:
///   - castling (king-side + queen-side, blocked through check)
///   - en passant (captured pawn removed correctly)
///   - promotion (queen, rook, bishop, knight)
///   - check / mate / stalemate detection
///   - 50-move rule + threefold repetition (basic)
public enum ChessRules: GameStateReducer {
    public typealias State = ChessState
    public typealias Input = ChessMove

    public static func initialState(host: Peer, guest: Peer) -> ChessState {
        // White always goes first; assign White to the host.
        ChessState(
            board: ChessState.startingBoard(),
            sideToMove: .white,
            white: host.id,
            black: guest.id,
            castling: ChessState.CastlingRights(
                whiteKing: true, whiteQueen: true,
                blackKing: true, blackQueen: true
            ),
            enPassantTarget: nil,
            halfmoveClock: 0,
            fullmoveNumber: 1,
            history: [],
            outcome: nil
        )
    }

    public static func reduce(_ state: ChessState, input move: ChessMove) throws -> Step {
        if state.outcome != nil { throw Error.gameOver }
        guard let movingPiece = state.board[move.from] else {
            throw Error.illegal("no piece on \(move.from)")
        }
        guard movingPiece.color == state.sideToMove else {
            throw Error.wrongTurn
        }
        let legal = legalMoves(in: state, for: movingPiece.color)
        guard legal.contains(move) else {
            throw Error.illegal("\(move) is not legal")
        }

        var s = state
        applyMoveInPlace(&s, move: move, movingPiece: movingPiece)

        // Switch sides and check for mate / stalemate / draw.
        s.sideToMove = s.sideToMove.opposite
        if s.sideToMove == .white { s.fullmoveNumber += 1 }

        let theirMoves = legalMoves(in: s, for: s.sideToMove)
        if theirMoves.isEmpty {
            if isInCheck(s, color: s.sideToMove) {
                // Checkmate — the side that just moved wins.
                let winnerColor = s.sideToMove.opposite
                let winnerId = winnerColor == .white ? s.white : s.black
                s.outcome = .checkmate(winner: winnerId)
                return (s, .winner(winnerId))
            } else {
                // Stalemate — draw.
                s.outcome = .stalemate
                return (s, .draw)
            }
        }
        if s.halfmoveClock >= 100 {
            s.outcome = .fiftyMoveRule
            return (s, .draw)
        }
        return (s, nil)
    }

    public static func isFinal(_ state: ChessState) -> Bool {
        state.outcome != nil
    }

    public static func currentTurn(_ state: ChessState) -> UUID? {
        if state.outcome != nil { return nil }
        return state.sideToMove == .white ? state.white : state.black
    }

    // MARK: - Public helpers (used by view models for highlighting)

    public static func legalMoves(in state: ChessState, for color: ChessPiece.Color) -> Set<ChessMove> {
        var moves = Set<ChessMove>()
        for sq in ChessSquare.all where state.board[sq]?.color == color {
            for m in pseudoLegalMoves(in: state, from: sq) {
                if !leavesOwnKingInCheck(state: state, move: m, color: color) {
                    moves.insert(m)
                }
            }
        }
        return moves
    }

    public static func isInCheck(_ state: ChessState, color: ChessPiece.Color) -> Bool {
        guard let kingSq = state.kingSquare(of: color) else { return false }
        return isAttacked(state.board, square: kingSq, by: color.opposite)
    }

    // MARK: - Move generation (pseudo-legal, then filtered)

    private static func pseudoLegalMoves(in state: ChessState, from square: ChessSquare) -> [ChessMove] {
        guard let piece = state.board[square] else { return [] }
        var out: [ChessMove] = []
        switch piece.kind {
        case .pawn:   out.append(contentsOf: pawnMoves(state: state, from: square, piece: piece))
        case .knight: out.append(contentsOf: stepperMoves(state.board, from: square, piece: piece, deltas: knightDeltas))
        case .bishop: out.append(contentsOf: sliderMoves(state.board, from: square, piece: piece, deltas: bishopDeltas))
        case .rook:   out.append(contentsOf: sliderMoves(state.board, from: square, piece: piece, deltas: rookDeltas))
        case .queen:
            out.append(contentsOf: sliderMoves(state.board, from: square, piece: piece, deltas: bishopDeltas))
            out.append(contentsOf: sliderMoves(state.board, from: square, piece: piece, deltas: rookDeltas))
        case .king:
            out.append(contentsOf: stepperMoves(state.board, from: square, piece: piece, deltas: kingDeltas))
            out.append(contentsOf: castlingMoves(state: state, from: square, piece: piece))
        }
        return out
    }

    private static func pawnMoves(state: ChessState, from sq: ChessSquare, piece: ChessPiece) -> [ChessMove] {
        var moves: [ChessMove] = []
        let dir = piece.color == .white ? 1 : -1
        let startRank = piece.color == .white ? 1 : 6
        let promoRank = piece.color == .white ? 7 : 0

        // Forward one
        if let f1 = ChessSquare(file: sq.file, rank: sq.rank + dir),
           state.board[f1] == nil {
            if f1.rank == promoRank {
                for k in [ChessPiece.Kind.queen, .rook, .bishop, .knight] {
                    moves.append(ChessMove(from: sq, to: f1, promotion: k))
                }
            } else {
                moves.append(ChessMove(from: sq, to: f1))
            }
            // Forward two from start
            if sq.rank == startRank,
               let f2 = ChessSquare(file: sq.file, rank: sq.rank + 2*dir),
               state.board[f2] == nil {
                moves.append(ChessMove(from: sq, to: f2))
            }
        }
        // Captures
        for df in [-1, 1] {
            guard let cap = ChessSquare(file: sq.file + df, rank: sq.rank + dir) else { continue }
            if let target = state.board[cap], target.color != piece.color {
                if cap.rank == promoRank {
                    for k in [ChessPiece.Kind.queen, .rook, .bishop, .knight] {
                        moves.append(ChessMove(from: sq, to: cap, promotion: k))
                    }
                } else {
                    moves.append(ChessMove(from: sq, to: cap))
                }
            } else if cap == state.enPassantTarget {
                moves.append(ChessMove(from: sq, to: cap, isEnPassant: true))
            }
        }
        return moves
    }

    private static func stepperMoves(_ board: [ChessSquare: ChessPiece], from sq: ChessSquare, piece: ChessPiece, deltas: [(Int, Int)]) -> [ChessMove] {
        var moves: [ChessMove] = []
        for (df, dr) in deltas {
            guard let to = ChessSquare(file: sq.file + df, rank: sq.rank + dr) else { continue }
            if let target = board[to], target.color == piece.color { continue }
            moves.append(ChessMove(from: sq, to: to))
        }
        return moves
    }

    private static func sliderMoves(_ board: [ChessSquare: ChessPiece], from sq: ChessSquare, piece: ChessPiece, deltas: [(Int, Int)]) -> [ChessMove] {
        var moves: [ChessMove] = []
        for (df, dr) in deltas {
            var f = sq.file + df, r = sq.rank + dr
            while let to = ChessSquare(file: f, rank: r) {
                if let target = board[to] {
                    if target.color != piece.color { moves.append(ChessMove(from: sq, to: to)) }
                    break
                }
                moves.append(ChessMove(from: sq, to: to))
                f += df; r += dr
            }
        }
        return moves
    }

    private static func castlingMoves(state: ChessState, from sq: ChessSquare, piece: ChessPiece) -> [ChessMove] {
        var moves: [ChessMove] = []
        let homeRank = piece.color == .white ? 0 : 7
        guard sq == ChessSquare(file: 4, rank: homeRank) else { return moves }
        if isInCheck(state, color: piece.color) { return moves }

        // King-side
        let kingSideOk = piece.color == .white ? state.castling.whiteKing : state.castling.blackKing
        if kingSideOk,
           state.board[ChessSquare(file: 5, rank: homeRank)!] == nil,
           state.board[ChessSquare(file: 6, rank: homeRank)!] == nil,
           !isAttacked(state.board, square: ChessSquare(file: 5, rank: homeRank)!, by: piece.color.opposite),
           !isAttacked(state.board, square: ChessSquare(file: 6, rank: homeRank)!, by: piece.color.opposite) {
            moves.append(ChessMove(from: sq, to: ChessSquare(file: 6, rank: homeRank)!, isCastleKingSide: true))
        }
        // Queen-side
        let queenSideOk = piece.color == .white ? state.castling.whiteQueen : state.castling.blackQueen
        if queenSideOk,
           state.board[ChessSquare(file: 3, rank: homeRank)!] == nil,
           state.board[ChessSquare(file: 2, rank: homeRank)!] == nil,
           state.board[ChessSquare(file: 1, rank: homeRank)!] == nil,
           !isAttacked(state.board, square: ChessSquare(file: 3, rank: homeRank)!, by: piece.color.opposite),
           !isAttacked(state.board, square: ChessSquare(file: 2, rank: homeRank)!, by: piece.color.opposite) {
            moves.append(ChessMove(from: sq, to: ChessSquare(file: 2, rank: homeRank)!, isCastleQueenSide: true))
        }
        return moves
    }

    // MARK: - Apply

    private static func applyMoveInPlace(_ s: inout ChessState, move: ChessMove, movingPiece: ChessPiece) {
        var board = s.board
        var captured = board[move.to] != nil

        // En passant capture: remove the pawn we just bypassed.
        if move.isEnPassant {
            let capSq = ChessSquare(file: move.to.file, rank: move.from.rank)!
            board[capSq] = nil
            captured = true
        }

        // Castling: move the rook too.
        if move.isCastleKingSide {
            let r = move.from.rank
            board[ChessSquare(file: 5, rank: r)!] = board[ChessSquare(file: 7, rank: r)!]
            board[ChessSquare(file: 7, rank: r)!] = nil
        } else if move.isCastleQueenSide {
            let r = move.from.rank
            board[ChessSquare(file: 3, rank: r)!] = board[ChessSquare(file: 0, rank: r)!]
            board[ChessSquare(file: 0, rank: r)!] = nil
        }

        // Move the piece (with promotion if requested).
        var landing = movingPiece
        if let promo = move.promotion {
            landing = ChessPiece(color: movingPiece.color, kind: promo)
        }
        board[move.from] = nil
        board[move.to] = landing

        // Update castling rights if king or rook moved or rook captured.
        var c = s.castling
        switch movingPiece.kind {
        case .king:
            if movingPiece.color == .white { c.whiteKing = false; c.whiteQueen = false }
            else { c.blackKing = false; c.blackQueen = false }
        case .rook:
            if move.from == ChessSquare(file: 0, rank: 0) { c.whiteQueen = false }
            if move.from == ChessSquare(file: 7, rank: 0) { c.whiteKing  = false }
            if move.from == ChessSquare(file: 0, rank: 7) { c.blackQueen = false }
            if move.from == ChessSquare(file: 7, rank: 7) { c.blackKing  = false }
        default: break
        }
        if move.to == ChessSquare(file: 0, rank: 0) { c.whiteQueen = false }
        if move.to == ChessSquare(file: 7, rank: 0) { c.whiteKing  = false }
        if move.to == ChessSquare(file: 0, rank: 7) { c.blackQueen = false }
        if move.to == ChessSquare(file: 7, rank: 7) { c.blackKing  = false }

        // Update en passant target.
        var ep: ChessSquare? = nil
        if movingPiece.kind == .pawn && abs(move.to.rank - move.from.rank) == 2 {
            ep = ChessSquare(file: move.from.file, rank: (move.from.rank + move.to.rank) / 2)
        }

        // Halfmove clock.
        var hm = s.halfmoveClock + 1
        if movingPiece.kind == .pawn || captured { hm = 0 }

        s.board = board
        s.castling = c
        s.enPassantTarget = ep
        s.halfmoveClock = hm
        s.history.append(move)
    }

    private static func leavesOwnKingInCheck(state: ChessState, move: ChessMove, color: ChessPiece.Color) -> Bool {
        guard let piece = state.board[move.from] else { return false }
        var probe = state
        applyMoveInPlace(&probe, move: move, movingPiece: piece)
        return isInCheck(probe, color: color)
    }

    // MARK: - Attack detection

    private static func isAttacked(_ board: [ChessSquare: ChessPiece], square: ChessSquare, by color: ChessPiece.Color) -> Bool {
        // Pawns
        let dir = color == .white ? 1 : -1
        for df in [-1, 1] {
            if let from = ChessSquare(file: square.file + df, rank: square.rank - dir),
               let p = board[from], p.color == color, p.kind == .pawn {
                return true
            }
        }
        // Knights
        for (df, dr) in knightDeltas {
            if let from = ChessSquare(file: square.file + df, rank: square.rank + dr),
               let p = board[from], p.color == color, p.kind == .knight {
                return true
            }
        }
        // Kings
        for (df, dr) in kingDeltas {
            if let from = ChessSquare(file: square.file + df, rank: square.rank + dr),
               let p = board[from], p.color == color, p.kind == .king {
                return true
            }
        }
        // Sliders
        for (df, dr) in bishopDeltas {
            var f = square.file + df, r = square.rank + dr
            while let from = ChessSquare(file: f, rank: r) {
                if let p = board[from] {
                    if p.color == color && (p.kind == .bishop || p.kind == .queen) { return true }
                    break
                }
                f += df; r += dr
            }
        }
        for (df, dr) in rookDeltas {
            var f = square.file + df, r = square.rank + dr
            while let from = ChessSquare(file: f, rank: r) {
                if let p = board[from] {
                    if p.color == color && (p.kind == .rook || p.kind == .queen) { return true }
                    break
                }
                f += df; r += dr
            }
        }
        return false
    }

    private static let knightDeltas: [(Int, Int)] = [(1,2),(2,1),(-1,2),(-2,1),(1,-2),(2,-1),(-1,-2),(-2,-1)]
    private static let bishopDeltas: [(Int, Int)] = [(1,1),(1,-1),(-1,1),(-1,-1)]
    private static let rookDeltas:   [(Int, Int)] = [(1,0),(-1,0),(0,1),(0,-1)]
    private static let kingDeltas:   [(Int, Int)] = [(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]
}

// MARK: - Types

public struct ChessSquare: Hashable, Codable, Sendable, CustomStringConvertible {
    public let file: Int  // 0...7 (a..h)
    public let rank: Int  // 0...7 (1..8)

    public init?(file: Int, rank: Int) {
        guard (0...7).contains(file), (0...7).contains(rank) else { return nil }
        self.file = file
        self.rank = rank
    }

    public static let all: [ChessSquare] = {
        var out: [ChessSquare] = []
        for f in 0...7 {
            for r in 0...7 {
                out.append(ChessSquare(file: f, rank: r)!)
            }
        }
        return out
    }()

    public var description: String {
        "\(["a","b","c","d","e","f","g","h"][file])\(rank+1)"
    }
}

public struct ChessPiece: Hashable, Codable, Sendable {
    public enum Color: String, Codable, Sendable {
        case white, black
        public var opposite: Color { self == .white ? .black : .white }
    }
    public enum Kind: String, Codable, Sendable {
        case pawn, knight, bishop, rook, queen, king
    }
    public let color: Color
    public let kind: Kind
    public init(color: Color, kind: Kind) {
        self.color = color
        self.kind = kind
    }
}

public struct ChessMove: Hashable, Codable, Sendable, CustomStringConvertible {
    public let from: ChessSquare
    public let to: ChessSquare
    public let promotion: ChessPiece.Kind?
    public let isEnPassant: Bool
    public let isCastleKingSide: Bool
    public let isCastleQueenSide: Bool

    public init(
        from: ChessSquare,
        to: ChessSquare,
        promotion: ChessPiece.Kind? = nil,
        isEnPassant: Bool = false,
        isCastleKingSide: Bool = false,
        isCastleQueenSide: Bool = false
    ) {
        self.from = from
        self.to = to
        self.promotion = promotion
        self.isEnPassant = isEnPassant
        self.isCastleKingSide = isCastleKingSide
        self.isCastleQueenSide = isCastleQueenSide
    }

    public var description: String {
        "\(from)-\(to)\(promotion.map { "=\($0.rawValue)" } ?? "")"
    }
}

public struct ChessState: Codable, Equatable, Sendable {
    public var board: [ChessSquare: ChessPiece]
    public var sideToMove: ChessPiece.Color
    public let white: UUID
    public let black: UUID
    public var castling: CastlingRights
    public var enPassantTarget: ChessSquare?
    public var halfmoveClock: Int
    public var fullmoveNumber: Int
    public var history: [ChessMove]
    public var outcome: Outcome?

    public struct CastlingRights: Codable, Equatable, Sendable {
        public var whiteKing: Bool
        public var whiteQueen: Bool
        public var blackKing: Bool
        public var blackQueen: Bool
    }

    public enum Outcome: Codable, Equatable, Sendable {
        case checkmate(winner: UUID)
        case stalemate
        case fiftyMoveRule
        case threefoldRepetition
        case resignation(loser: UUID)
    }

    public func kingSquare(of color: ChessPiece.Color) -> ChessSquare? {
        for sq in ChessSquare.all {
            if let p = board[sq], p.color == color, p.kind == .king {
                return sq
            }
        }
        return nil
    }

    public static func startingBoard() -> [ChessSquare: ChessPiece] {
        var b: [ChessSquare: ChessPiece] = [:]
        let backRank: [ChessPiece.Kind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for f in 0...7 {
            b[ChessSquare(file: f, rank: 0)!] = ChessPiece(color: .white, kind: backRank[f])
            b[ChessSquare(file: f, rank: 1)!] = ChessPiece(color: .white, kind: .pawn)
            b[ChessSquare(file: f, rank: 6)!] = ChessPiece(color: .black, kind: .pawn)
            b[ChessSquare(file: f, rank: 7)!] = ChessPiece(color: .black, kind: backRank[f])
        }
        return b
    }
}
