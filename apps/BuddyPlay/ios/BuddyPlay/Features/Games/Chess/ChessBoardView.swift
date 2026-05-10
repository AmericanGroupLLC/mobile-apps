import SwiftUI
import BuddyCore

struct ChessBoardView: View {
    @ObservedObject var vm: ChessViewModel

    private let lightSquare = Color(red: 0.93, green: 0.85, blue: 0.71)
    private let darkSquare  = Color(red: 0.55, green: 0.36, blue: 0.20)

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 8
            ZStack(alignment: .topLeading) {
                ForEach(0..<8, id: \.self) { rank in
                    ForEach(0..<8, id: \.self) { file in
                        let square = ChessSquare(file: file, rank: 7 - rank)!
                        let isLight = (file + rank) % 2 == 0
                        let isSelected = vm.selected == square
                        let isLegalTarget = vm.legalDestinations.contains(square)

                        ZStack {
                            Rectangle().fill(isLight ? lightSquare : darkSquare)
                            if isSelected {
                                Rectangle().fill(Color.accentColor.opacity(0.45))
                            } else if isLegalTarget {
                                Circle().fill(Color.accentColor.opacity(0.55))
                                    .padding(cell * 0.30)
                            }
                            if let piece = vm.state.board[square] {
                                Text(symbol(for: piece))
                                    .font(.system(size: cell * 0.7))
                                    .foregroundStyle(piece.color == .white ? .white : .black)
                                    .shadow(radius: 1)
                            }
                        }
                        .frame(width: cell, height: cell)
                        .offset(x: CGFloat(file) * cell, y: CGFloat(rank) * cell)
                        .onTapGesture { vm.tap(square) }
                    }
                }
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func symbol(for piece: ChessPiece) -> String {
        switch (piece.color, piece.kind) {
        case (.white, .king):   return "♚"
        case (.white, .queen):  return "♛"
        case (.white, .rook):   return "♜"
        case (.white, .bishop): return "♝"
        case (.white, .knight): return "♞"
        case (.white, .pawn):   return "♟"
        case (.black, .king):   return "♚"
        case (.black, .queen):  return "♛"
        case (.black, .rook):   return "♜"
        case (.black, .bishop): return "♝"
        case (.black, .knight): return "♞"
        case (.black, .pawn):   return "♟"
        }
    }
}
