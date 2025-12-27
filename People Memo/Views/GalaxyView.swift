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
    let people: [Person]
    
    @State private var layoutResult: LayoutResult?
    @State private var hoveredPersonId: UUID?
    @State private var dragLocation: CGPoint?
    @State private var starPositions: [(CGPoint, CGFloat)] = []
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
            let maxRadius = min(geometry.size.width, geometry.size.height) / 2 - 40
            
            ZStack {
                // 背景
                backgroundLayer(maxRadius: maxRadius)
                
                // 計算中インジケーター
                if isCalculating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.gray)
                }
                
                // Canvasで描画
                if let layoutResult = layoutResult {
                    Canvas { context, size in
                        // 星の装飾
                        drawStars(context: &context, size: size)
                        
                        // 同心円の軌道線
                        drawOrbitLines(context: &context, center: center, maxRadius: maxRadius)
                        
                        // セクター線
                        drawSectorLines(
                            context: &context,
                            center: center,
                            maxRadius: maxRadius,
                            allTags: layoutResult.allTags
                        )
                        
                        // 中心の太陽
                        drawSun(context: &context, center: center)
                        
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
    
    private func drawStars(context: inout GraphicsContext, size: CGSize) {
        // 星を描画（ダークモード用：白い点）
        for (position, starSize) in starPositions {
            context.fill(
                Path(ellipseIn: CGRect(
                    x: position.x - starSize/2,
                    y: position.y - starSize/2,
                    width: starSize,
                    height: starSize
                )),
                with: .color(.white.opacity(0.3))
            )
        }
    }
    
    private func drawOrbitLines(context: inout GraphicsContext, center: CGPoint, maxRadius: CGFloat) {
        for index in 0..<4 {
            let radius = (maxRadius / 4) * CGFloat(index + 1)
            var path = Path()
            path.addEllipse(in: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            
            context.stroke(
                path,
                with: .color(.white.opacity(0.15)),
                lineWidth: 0.5
            )
        }
    }
    
    private func drawSectorLines(
        context: inout GraphicsContext,
        center: CGPoint,
        maxRadius: CGFloat,
        allTags: [String]
    ) {
        for (index, tag) in allTags.enumerated() {
            let angle = (Double(index) / Double(allTags.count)) * 2 * .pi - .pi / 2
            let endPoint = CGPoint(
                x: center.x + CGFloat(cos(angle)) * maxRadius,
                y: center.y + CGFloat(sin(angle)) * maxRadius
            )
            
            var path = Path()
            path.move(to: center)
            path.addLine(to: endPoint)
            
            context.stroke(
                path,
                with: .color(colorForTag(tag).opacity(0.3)),
                lineWidth: 0.5
            )
        }
    }
    
    private func drawSun(context: inout GraphicsContext, center: CGPoint) {
        // 太陽（ライトモード用：薄い黄色の円）
        let sunRadius: CGFloat = 12
        var sunPath = Path()
        sunPath.addEllipse(in: CGRect(
            x: center.x - sunRadius,
            y: center.y - sunRadius,
            width: sunRadius * 2,
            height: sunRadius * 2
        ))
        
        context.fill(
            sunPath,
            with: .color(Color.auroraYellow.opacity(0.6))
        )
        
        context.stroke(
            sunPath,
            with: .color(Color.auroraYellow),
            lineWidth: 1.5
        )
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
    
    private func backgroundLayer(maxRadius: CGFloat) -> some View {
        // ダーク背景（親の背景を使用）
        Color.clear
            .ignoresSafeArea()
    }
    
    /// 非同期でレイアウトを計算
    private func calculateLayout(size: CGSize) async {
        guard size.width > 0 && size.height > 0 else { return }
        
        isCalculating = true
        
        // バックグラウンドで計算
        let result = await LayoutEngine.calculateGalaxyLayout(
            people: people,
            size: size
        )
        
        // 星の位置を生成
        let stars = generateStarPositions(size: size, count: 30)
        
        // メインスレッドで更新
        await MainActor.run {
            self.layoutResult = result
            self.starPositions = stars
            self.isCalculating = false
        }
    }
    
    private func generateStarPositions(size: CGSize, count: Int) -> [(CGPoint, CGFloat)] {
        var positions: [(CGPoint, CGFloat)] = []
        for _ in 0..<count {
            positions.append((
                CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                CGFloat.random(in: 1...2)
            ))
        }
        return positions
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
    GalaxyView(people: [
        Person(name: "山田太郎", tags: ["Work"]),
        Person(name: "佐藤花子", tags: ["Hobby"]),
        Person(name: "鈴木一郎", tags: ["Family"])
    ])
    .frame(height: 600)
}
