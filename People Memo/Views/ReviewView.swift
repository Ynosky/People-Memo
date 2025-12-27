//
//  ReviewView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData

// MARK: - Card State

enum CardState {
    case idle
    case dragging
    case editing
}

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: \Meeting.date, order: .reverse) private var meetings: [Meeting]
    @State private var viewModel = ReviewViewModel()
    
    // すべてのMeetingからハイライトされたTranscriptBlockを取得
    private var allHighlightedBlocks: [TranscriptBlock] {
        meetings.flatMap { $0.highlightedBlocks }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack {
                    if allHighlightedBlocks.isEmpty {
                        VStack(spacing: 20) {
                            Text("✨")
                                .font(.system(size: 64))
                            
                            Text("振り返り用のブロックがありません")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(.primary)
                            
                            Text("ハイライトしたブロックが表示されます")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.blocksToReview.isEmpty {
                        VStack(spacing: 24) {
                            Text("本日の振り返りを開始しますか？")
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    viewModel.loadReviewBlocks(blocks: allHighlightedBlocks)
                                }
                            }) {
                                Text("開始する")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.brandPrimary)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let currentBlock = viewModel.currentBlock {
                        TriDirectionalCardView(
                            block: currentBlock,
                            viewModel: viewModel
                        )
                    } else {
                        VStack(spacing: 24) {
                            Text("✅")
                                .font(.system(size: 64))
                            
                            Text("本日の振り返りが完了しました！")
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    viewModel.loadReviewBlocks(blocks: allHighlightedBlocks)
                                }
                            }) {
                                Text("もう一度")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.brandPrimary)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("振り返り")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !allHighlightedBlocks.isEmpty && viewModel.blocksToReview.isEmpty {
                    viewModel.loadReviewBlocks(blocks: allHighlightedBlocks)
                }
            }
        }
    }
}

// MARK: - Tri-Directional Card View

struct TriDirectionalCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    let block: TranscriptBlock
    @Bindable var viewModel: ReviewViewModel
    
    @State private var cardState: CardState = .idle
    @State private var isFlipped: Bool = false
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var contextNote: String = ""
    @State private var dragStartLocation: CGPoint = .zero
    @State private var hasDragged: Bool = false
    @State private var showInputField: Bool = false
    @FocusState private var isInputFocused: Bool
    
    private var personColor: Color {
        if let meeting = block.meeting, let person = meeting.person {
            return Color.personColor(for: person.id)
        }
        return Color.primaryMint
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // カードを中央に配置
                VStack(spacing: 20) {
                    // コンパクトな入力欄（カード上部）
                    if showInputField {
                        CompactInputField(
                            contextNote: $contextNote,
                            isInputFocused: $isInputFocused,
                            onSave: {
                                block.userContextNote = contextNote.isEmpty ? nil : contextNote
                                hideInputField()
                            },
                            onCancel: {
                                hideInputField()
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    cardStackView
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
                
                // 進捗表示
                if !viewModel.blocksToReview.isEmpty && !showInputField {
                    Text("\(viewModel.currentBlockIndex + 1) / \(viewModel.blocksToReview.count)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(Color(uiColor: .secondarySystemBackground))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .padding(.bottom, 30)
                }
            }
        }
    }
    
    private var cardStackView: some View {
        ZStack {
            // メインカード
            ZStack {
                // 表面
                CardFrontView(block: block, personColor: personColor)
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                
                // 裏面
                CardBackView(
                    block: block,
                    personColor: personColor,
                    contextNote: $contextNote,
                    isEditing: false
                )
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
            .frame(width: 340, height: 450)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
                    )
                    .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            .rotationEffect(.degrees(cardRotation))
            .offset(cardOffset)
                    .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if showInputField {
                            // 入力欄表示中は下スワイプで閉じる判定のみ
                            return
                        }
                        
                        hasDragged = true
                        let width = value.translation.width
                        let height = value.translation.height
                        
                        // 左右スワイプ判定
                        if abs(width) > abs(height) {
                            cardState = .dragging
                            cardOffset = CGSize(width: width, height: 0)
                            cardRotation = Double(width / 10)
                        }
                        // 上スワイプ判定（入力欄を表示）
                        else if abs(height) > abs(width) && height < 0 {
                            // カードは動かさず、視覚的フィードバックのみ
                            let rawHeight = height
                            let dampingFactor: CGFloat = 0.6
                            let dampedHeight = rawHeight * dampingFactor
                            
                            // カードの軽微なオフセットでフィードバック
                            cardOffset = CGSize(width: 0, height: max(dampedHeight, -50))
                        }
                    }
                    .onEnded { value in
                        if showInputField {
                            // 入力欄表示中は下スワイプで閉じる
                            if value.translation.height > 50 {
                                hideInputField()
                            }
                            return
                        } else if cardState == .dragging {
                            // 左右スワイプ判定
                            let width = value.translation.width
                            if abs(width) > 100 {
                                // カードを画面外に飛ばす
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    cardOffset = CGSize(width: width > 0 ? 500 : -500, height: 0)
                                    cardRotation = width > 0 ? 30 : -30
                                }
                                
                                // 次のカードへ
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.moveToNext()
                                    resetCard()
                                }
                            } else {
                                // 元に戻る
                                resetCard()
                            }
                        } else {
                            // 上スワイプ終了時の判定
                            let height = value.translation.height
                            let threshold: CGFloat = -80 // 閾値
                            
                            if height < threshold {
                                // 入力欄を表示
                                contextNote = block.userContextNote ?? ""
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showInputField = true
                                    cardOffset = .zero
                                }
                                
                                // フォーカスを入力欄に
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isInputFocused = true
                                }
                            } else {
                                // 元に戻る
                                resetCard()
                            }
                        }
                        
                        hasDragged = false
                    }
            )
            .simultaneousGesture(
                // タップジェスチャー（ドラッグが検出されなかった場合のみ）
                TapGesture()
                    .onEnded { _ in
                        if !hasDragged && cardState == .idle {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isFlipped.toggle()
                            }
                            
                            // Haptic Feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                    }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private enum SwipeDirection {
        case left, right
    }
    
    private func swipeCard(direction: SwipeDirection) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            cardOffset = CGSize(width: direction == .right ? 500 : -500, height: 0)
            cardRotation = direction == .right ? 30 : -30
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.moveToNext()
            resetCard()
        }
    }
    
    private func resetCard() {
        cardState = .idle
        cardOffset = .zero
        cardRotation = 0
        isFlipped = false
    }
    
    private func hideInputField() {
        // キーボードを閉じる
        isInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showInputField = false
            cardOffset = .zero
            contextNote = ""
        }
    }
}

// MARK: - Card Front View

struct CardFrontView: View {
    @Environment(\.colorScheme) var colorScheme
    let block: TranscriptBlock
    let personColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let meeting = block.meeting, let person = meeting.person {
                HStack(spacing: 12) {
                    PersonBubble(person: person, size: 50, borderWidth: 2)
                    
                    Text(person.name)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(Color.primaryText(for: colorScheme))
                    
                    Spacer()
                }
            }
            
            Text(block.text)
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundColor(Color.primaryText(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(10)
                .padding(.vertical, 20)
            
            Spacer()
            
            Text("タップしてメモを見る")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(32)
    }
}

// MARK: - Card Back View

struct CardBackView: View {
    @Environment(\.colorScheme) var colorScheme
    let block: TranscriptBlock
    let personColor: Color
    @Binding var contextNote: String
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("メモ・コンテキスト")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(Color.primaryText(for: colorScheme))
            
            if let existingNote = block.userContextNote, !existingNote.isEmpty {
                Text(existingNote)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Color.primaryText(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cardBackground(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
                            )
                    )
            } else {
                Text("まだメモがありません")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cardBackground(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cardBorder(for: colorScheme), lineWidth: 1)
                            )
                    )
            }
            
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Compact Input Field

struct CompactInputField: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var contextNote: String
    @FocusState.Binding var isInputFocused: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("メモを入力...", text: $contextNote, axis: .vertical)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color.primaryText(for: colorScheme))
                .lineLimit(2)
                .focused($isInputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cardBackground(for: colorScheme))
                        .overlay(
                            // アンダーライン
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.cardBorder(for: colorScheme))
                                .offset(y: 20) // 下部に配置
                        )
                )
                .submitLabel(.done)
                .onSubmit {
                    onSave()
                }
            
            Button(action: onSave) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color.brandPrimary)
            }
            .disabled(contextNote.isEmpty)
            .opacity(contextNote.isEmpty ? 0.3 : 1.0)
        }
        .frame(width: 340)
        .padding(.horizontal, 8)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }
}

#Preview {
    ReviewView()
        .modelContainer(for: [Person.self, Meeting.self, Note.self, TranscriptBlock.self], inMemory: true)
}
