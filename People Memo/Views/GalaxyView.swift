//
//  GalaxyView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData
import UIKit

struct GalaxyView: View {
    @Query(sort: \Person.createdAt, order: .reverse) private var people: [Person]
    @Environment(\.colorScheme) var colorScheme
    
    @State private var layoutResult: LayoutResult?
    @State private var hoveredPersonId: UUID?
    @State private var dragLocation: CGPoint?
    @State private var isCalculating = false
    
    // ズームとパン用の状態
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // ブランドカラー（Electric Indigo）
    private let brandIndigo = Color(hex: "5856D6")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // アダプティブ背景
                Color.appBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                // 計算中インジケーター
                if isCalculating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(brandIndigo)
                }
                
                // Canvasで描画
                if let layoutResult = layoutResult {
                    Canvas { context, size in
                        // 接続線（極めて細く、透明度高め）
                        drawConnections(
                            context: &context,
                            nodes: layoutResult.nodes
                        )
                        
                        // ノード（星）を描画
                        drawNodes(
                            context: &context,
                            nodes: layoutResult.nodes,
                            hoveredPersonId: hoveredPersonId
                        )
                    }
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            // ズームジェスチャー
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    // ズーム範囲を制限（0.5x - 3.0x）
                                    if scale < 0.5 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            scale = 0.5
                                            lastScale = 0.5
                                        }
                                    } else if scale > 3.0 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            scale = 3.0
                                            lastScale = 3.0
                                        }
                                    }
                                },
                            // パンジェスチャー
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .simultaneousGesture(
                        // タップでホバー検知
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // スケールとオフセットを考慮した座標変換
                                let transformedLocation = CGPoint(
                                    x: (value.location.x - offset.width) / scale,
                                    y: (value.location.y - offset.height) / scale
                                )
                                dragLocation = value.location
                                updateHoveredPerson(at: transformedLocation, nodes: layoutResult.nodes)
                            }
                            .onEnded { _ in
                                dragLocation = nil
                                hoveredPersonId = nil
                            }
                    )
                    
                    // ツールチップ
                    if let hoveredId = hoveredPersonId,
                       let node = layoutResult.nodes.first(where: { $0.id == hoveredId }),
                       let dragLocation = dragLocation {
                        TooltipView(
                            personName: node.name,
                            initials: node.initials,
                            tag: node.tag,
                            tagColor: node.color,
                            iconImageData: node.iconImageData
                        )
                        .position(
                            x: dragLocation.x,
                            y: dragLocation.y - 50
                        )
                    }
                }
            }
            .task(id: geometry.size) {
                await calculateLayout(size: geometry.size)
            }
            .task(id: people.count) {
                await calculateLayout(size: geometry.size)
            }
            .onTapGesture(count: 2) {
                // ダブルタップでリセット
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    lastScale = 1.0
                    offset = .zero
                    lastOffset = .zero
                }
            }
        }
    }
    
    // MARK: - Drawing Functions
    
    /// 接続線を描画（極めて細く、透明度高め）
    private func drawConnections(
        context: inout GraphicsContext,
        nodes: [RenderNode]
    ) {
        // タグが同じノード同士を接続
        var connections: [(CGPoint, CGPoint)] = []
        
        for (index, node1) in nodes.enumerated() {
            for node2 in nodes[(index + 1)...] where node1.tag == node2.tag {
                connections.append((node1.position, node2.position))
            }
        }
        
        // 接続線を描画
        for (start, end) in connections {
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            
            context.stroke(
                path,
                with: .color(brandIndigo.opacity(0.2)),
                lineWidth: 0.5
            )
        }
    }
    
    /// ノード（星）を描画
    private func drawNodes(
        context: inout GraphicsContext,
        nodes: [RenderNode],
        hoveredPersonId: UUID?
    ) {
        for node in nodes {
            let isHovered = node.id == hoveredPersonId
            let nodeSize = isHovered ? max(node.size * 1.5, 4) : max(node.size, 2)
            
            // ノード本体（Electric Indigo、シャープに）
            var nodePath = Path()
            nodePath.addEllipse(in: CGRect(
                x: node.position.x - nodeSize / 2,
                y: node.position.y - nodeSize / 2,
                width: nodeSize,
                height: nodeSize
            ))
            
            // ノードを描画（ブランドカラー）
            context.fill(nodePath, with: .color(brandIndigo))
            
            // ホバー時は発光エフェクト
            if isHovered {
                context.stroke(
                    nodePath,
                    with: .color(brandIndigo.opacity(0.8)),
                    lineWidth: 1.0
                )
                
                // 発光エフェクト（シャドウ）
                var glowPath = Path()
                glowPath.addEllipse(in: CGRect(
                    x: node.position.x - nodeSize / 2 - 2,
                    y: node.position.y - nodeSize / 2 - 2,
                    width: nodeSize + 4,
                    height: nodeSize + 4
                ))
                
                context.stroke(
                    glowPath,
                    with: .color(brandIndigo.opacity(0.3)),
                    lineWidth: 2.0
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// 非同期でレイアウトを計算
    private func calculateLayout(size: CGSize) async {
        guard size.width > 0 && size.height > 0 else { return }
        
        isCalculating = true
        
        // バックグラウンドで計算
        let result = await LayoutEngine.calculateGalaxyLayout(
            people: people,
            size: size
        )
        
        // メインスレッドで更新
        await MainActor.run {
            self.layoutResult = result
            self.isCalculating = false
        }
    }
    
    private func updateHoveredPerson(at location: CGPoint, nodes: [RenderNode]) {
        let threshold: CGFloat = 30 // 検知範囲
        
        var closestPersonId: UUID?
        var closestDistance: CGFloat = CGFloat.infinity
        
        for node in nodes {
            let distance = sqrt(
                pow(location.x - node.position.x, 2) +
                pow(location.y - node.position.y, 2)
            )
            
            if distance < threshold && distance < closestDistance {
                closestDistance = distance
                closestPersonId = node.id
            }
        }
        
        if closestPersonId != hoveredPersonId {
            hoveredPersonId = closestPersonId
            
            // Haptic Feedback
            if closestPersonId != nil {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
}

// MARK: - Compact Version (for TokyoView)

struct CompactGalaxyView: View {
    @Query(sort: \Person.createdAt, order: .reverse) private var people: [Person]
    @Environment(\.colorScheme) var colorScheme
    
    @State private var layoutResult: LayoutResult?
    @State private var hoveredPersonId: UUID?
    @State private var dragLocation: CGPoint?
    @State private var isCalculating = false
    
    // ズームとパン用の状態
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // ブランドカラー（Electric Indigo）
    private let brandIndigo = Color(hex: "5856D6")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景は透明（親の背景を使用）
                Color.clear
                
                // 計算中インジケーター
                if isCalculating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(brandIndigo)
                }
                
                // Canvasで描画
                if let layoutResult = layoutResult {
                    Canvas { context, size in
                        // 接続線（極めて細く、透明度高め）
                        drawConnections(
                            context: &context,
                            nodes: layoutResult.nodes
                        )
                        
                        // ノード（星）を描画
                        drawNodes(
                            context: &context,
                            nodes: layoutResult.nodes,
                            hoveredPersonId: hoveredPersonId
                        )
                    }
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            // ズームジェスチャー
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    // ズーム範囲を制限（0.5x - 3.0x）
                                    if scale < 0.5 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            scale = 0.5
                                            lastScale = 0.5
                                        }
                                    } else if scale > 3.0 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            scale = 3.0
                                            lastScale = 3.0
                                        }
                                    }
                                },
                            // パンジェスチャー
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .simultaneousGesture(
                        // タップでホバー検知
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // スケールとオフセットを考慮した座標変換
                                let transformedLocation = CGPoint(
                                    x: (value.location.x - offset.width) / scale,
                                    y: (value.location.y - offset.height) / scale
                                )
                                dragLocation = value.location
                                updateHoveredPerson(at: transformedLocation, nodes: layoutResult.nodes)
                            }
                            .onEnded { _ in
                                dragLocation = nil
                                hoveredPersonId = nil
                            }
                    )
                    
                    // ツールチップ
                    if let hoveredId = hoveredPersonId,
                       let node = layoutResult.nodes.first(where: { $0.id == hoveredId }),
                       let dragLocation = dragLocation {
                        TooltipView(
                            personName: node.name,
                            initials: node.initials,
                            tag: node.tag,
                            tagColor: node.color,
                            iconImageData: node.iconImageData
                        )
                        .position(
                            x: dragLocation.x,
                            y: dragLocation.y - 50
                        )
                    }
                }
            }
            .task(id: geometry.size) {
                await calculateLayout(size: geometry.size)
            }
            .task(id: people.count) {
                await calculateLayout(size: geometry.size)
            }
            .onTapGesture(count: 2) {
                // ダブルタップでリセット
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    lastScale = 1.0
                    offset = .zero
                    lastOffset = .zero
                }
            }
        }
    }
    
    // MARK: - Drawing Functions
    
    /// 接続線を描画（極めて細く、透明度高め）
    private func drawConnections(
        context: inout GraphicsContext,
        nodes: [RenderNode]
    ) {
        // タグが同じノード同士を接続
        var connections: [(CGPoint, CGPoint)] = []
        
        for (index, node1) in nodes.enumerated() {
            for node2 in nodes[(index + 1)...] where node1.tag == node2.tag {
                connections.append((node1.position, node2.position))
            }
        }
        
        // 接続線を描画
        for (start, end) in connections {
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            
            context.stroke(
                path,
                with: .color(brandIndigo.opacity(0.2)),
                lineWidth: 0.5
            )
        }
    }
    
    /// ノード（星）を描画
    private func drawNodes(
        context: inout GraphicsContext,
        nodes: [RenderNode],
        hoveredPersonId: UUID?
    ) {
        for node in nodes {
            let isHovered = node.id == hoveredPersonId
            let nodeSize = isHovered ? max(node.size * 1.5, 4) : max(node.size, 2)
            
            // ノード本体（Electric Indigo、シャープに）
            var nodePath = Path()
            nodePath.addEllipse(in: CGRect(
                x: node.position.x - nodeSize / 2,
                y: node.position.y - nodeSize / 2,
                width: nodeSize,
                height: nodeSize
            ))
            
            // ノードを描画（ブランドカラー）
            context.fill(nodePath, with: .color(brandIndigo))
            
            // ホバー時は発光エフェクト
            if isHovered {
                context.stroke(
                    nodePath,
                    with: .color(brandIndigo.opacity(0.8)),
                    lineWidth: 1.0
                )
                
                // 発光エフェクト（シャドウ）
                var glowPath = Path()
                glowPath.addEllipse(in: CGRect(
                    x: node.position.x - nodeSize / 2 - 2,
                    y: node.position.y - nodeSize / 2 - 2,
                    width: nodeSize + 4,
                    height: nodeSize + 4
                ))
                
                context.stroke(
                    glowPath,
                    with: .color(brandIndigo.opacity(0.3)),
                    lineWidth: 2.0
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// 非同期でレイアウトを計算
    private func calculateLayout(size: CGSize) async {
        guard size.width > 0 && size.height > 0 else { return }
        
        isCalculating = true
        
        // バックグラウンドで計算
        let result = await LayoutEngine.calculateGalaxyLayout(
            people: people,
            size: size
        )
        
        // メインスレッドで更新
        await MainActor.run {
            self.layoutResult = result
            self.isCalculating = false
        }
    }
    
    private func updateHoveredPerson(at location: CGPoint, nodes: [RenderNode]) {
        let threshold: CGFloat = 30 // 検知範囲
        
        var closestPersonId: UUID?
        var closestDistance: CGFloat = CGFloat.infinity
        
        for node in nodes {
            let distance = sqrt(
                pow(location.x - node.position.x, 2) +
                pow(location.y - node.position.y, 2)
            )
            
            if distance < threshold && distance < closestDistance {
                closestDistance = distance
                closestPersonId = node.id
            }
        }
        
        if closestPersonId != hoveredPersonId {
            hoveredPersonId = closestPersonId
            
            // Haptic Feedback
            if closestPersonId != nil {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
}

#Preview {
    GalaxyView()
        .modelContainer(for: [Person.self, Meeting.self, Note.self, TranscriptBlock.self, AgendaItem.self], inMemory: true)
}
