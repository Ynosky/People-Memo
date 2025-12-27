//
//  NeuralNetworkView.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import SwiftData
import UIKit

struct NeuralNetworkView: View {
    let people: [Person]
    
    @State private var layoutResult: LayoutResult?
    @State private var hoveredPersonId: UUID?
    @State private var dragLocation: CGPoint?
    @State private var isCalculating = false
    
    // タグごとの色（ライトモード用：彩度の高い色）
    private func colorForTag(_ tag: String) -> Color {
        switch tag {
        case "Work":
            return Color(red: 0.0, green: 0.7, blue: 0.9) // 濃いCyan
        case "Hobby":
            return Color(red: 1.0, green: 0.5, blue: 0.0) // 濃いOrange
        case "School":
            return Color(red: 0.6, green: 0.2, blue: 0.8) // 濃いPurple
        case "Family":
            return Color(red: 1.0, green: 0.3, blue: 0.6) // 濃いPink
        case "Drinking Buddy":
            return Color(red: 1.0, green: 0.8, blue: 0.0) // 濃いYellow
        default:
            return Color.gray
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // 背景
                backgroundLayer()
                
                // 計算中インジケーター
                if isCalculating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.gray)
                }
                
                // Canvasで描画
                if let layoutResult = layoutResult {
                    Canvas { context, size in
                        // ネットワークの線を描画
                        drawNetworkLinks(
                            context: &context,
                            nodes: layoutResult.nodes,
                            clusterCenters: layoutResult.clusterCenters,
                            center: center,
                            allTags: layoutResult.allTags
                        )
                        
                        // ドットを描画
                        drawDots(
                            context: &context,
                            nodes: layoutResult.nodes,
                            hoveredPersonId: hoveredPersonId
                        )
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                dragLocation = value.location
                                updateHoveredPerson(at: value.location, nodes: layoutResult.nodes)
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
        }
    }
    
    // MARK: - Drawing Functions
    
    private func drawNetworkLinks(
        context: inout GraphicsContext,
        nodes: [RenderNode],
        clusterCenters: [String: CGPoint],
        center: CGPoint,
        allTags: [String]
    ) {
        // 同じタグを持つノード同士を結ぶ（ライトモード用：非常に薄いグレー）
        for tag in allTags {
            let nodesWithTag = nodes.filter { $0.tag == tag }
            
            for (index, node) in nodesWithTag.enumerated() {
                // クラスター中心への線
                if let clusterCenter = clusterCenters[tag] {
                    var path = Path()
                    path.move(to: clusterCenter)
                    path.addLine(to: node.position)
                    
                    context.stroke(
                        path,
                        with: .color(.black.opacity(0.2)),
                        lineWidth: 0.5
                    )
                }
                
                // 同じタグのノード同士を結ぶ（一番近い1人だけ）
                if index < nodesWithTag.count - 1 {
                    let nextNode = nodesWithTag[index + 1]
                    var path = Path()
                    path.move(to: node.position)
                    path.addLine(to: nextNode.position)
                    
                    let distance = sqrt(
                        pow(nextNode.position.x - node.position.x, 2) +
                        pow(nextNode.position.y - node.position.y, 2)
                    )
                    
                    // 距離に応じて透明度を調整（ダーク背景用に白に変更）
                    if distance < 80 {
                        context.stroke(
                            path,
                            with: .color(.white.opacity(0.2)),
                            lineWidth: 0.5
                        )
                    } else if distance < 120 {
                        context.stroke(
                            path,
                            with: .color(.white.opacity(0.15)),
                            lineWidth: 0.5
                        )
                    }
                }
            }
        }
        
        // 中心（自分）から各クラスターへの線（極細）
        for (_, clusterCenter) in clusterCenters {
            var path = Path()
            path.move(to: center)
            path.addLine(to: clusterCenter)
            
            context.stroke(
                path,
                with: .color(.white.opacity(0.15)),
                lineWidth: 0.5
            )
        }
    }
    
    private func drawDots(
        context: inout GraphicsContext,
        nodes: [RenderNode],
        hoveredPersonId: UUID?
    ) {
        for node in nodes {
            let isHovered = node.id == hoveredPersonId
            let dotSize = isHovered ? node.size * 1.5 : node.size
            
            // ドット本体（ソリッドカラー、エフェクト削除で軽量化）
            var dotPath = Path()
            dotPath.addEllipse(in: CGRect(
                x: node.position.x - dotSize / 2,
                y: node.position.y - dotSize / 2,
                width: dotSize,
                height: dotSize
            ))
            
            // ドット本体（高彩度の色）
            context.fill(dotPath, with: .color(node.color))
            
            // ネオンボーダー（輪郭を明確に）
            context.stroke(
                dotPath,
                with: .color(node.color.opacity(0.8)),
                lineWidth: 1.0
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func backgroundLayer() -> some View {
        // ダーク背景（親の背景を使用）
        Color.clear
            .ignoresSafeArea()
    }
    
    /// 非同期でレイアウトを計算
    private func calculateLayout(size: CGSize) async {
        guard size.width > 0 && size.height > 0 else { return }
        
        isCalculating = true
        
        // バックグラウンドで計算
        let result = await LayoutEngine.calculateNeuralNetworkLayout(
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
    NeuralNetworkView(people: [
        Person(name: "山田太郎", tags: ["Work"]),
        Person(name: "佐藤花子", tags: ["Hobby"]),
        Person(name: "鈴木一郎", tags: ["Family"])
    ])
    .frame(height: 600)
}
