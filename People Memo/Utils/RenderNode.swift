//
//  RenderNode.swift
//  People Memo
//
//  Created by ryunosuke sato on 2025/12/26.
//

import SwiftUI
import Foundation

/// 描画専用の軽量DTO（SwiftData非依存）
struct RenderNode: Identifiable, Equatable {
    let id: UUID
    let name: String
    let initials: String
    let color: Color
    var position: CGPoint // 計算済みの座標
    let size: CGFloat
    let glowIntensity: Double // 0.0-1.0
    let tag: String // タグ名（表示用）
    let iconImageData: Data? // アイコン画像データ（オプション）
    let daysSinceLastMeeting: Int? // 最後に会ってからの経過日数（衛星インジケータ用）
    
    // Equatable実装（位置が変更された場合のみ更新）
    // ColorはEquatableではないため、色の比較は除外
    static func == (lhs: RenderNode, rhs: RenderNode) -> Bool {
        lhs.id == rhs.id &&
        lhs.position == rhs.position &&
        lhs.size == rhs.size &&
        lhs.glowIntensity == rhs.glowIntensity &&
        lhs.tag == rhs.tag
    }
}

/// レイアウト計算結果（DTO）
struct LayoutResult {
    let nodes: [RenderNode]
    let clusterCenters: [String: CGPoint] // Neural Network用
    let allTags: [String]
}

/// レイアウトエンジン：非同期計算対応
enum LayoutEngine {
    // 描画ノード数の上限（パフォーマンス保護）
    static let maxRenderNodes = 500
    
    /// 銀河ビュー用のレイアウト計算（非同期）
    static func calculateGalaxyLayout(
        people: [Person],
        size: CGSize
    ) async -> LayoutResult {
        // 上限チェック
        let limitedPeople = Array(people.prefix(maxRenderNodes))
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = min(size.width, size.height) / 2 - 40
        
        // すべてのタグを取得
        let allTags = Array(Set(limitedPeople.flatMap { $0.tags })).sorted()
        guard !allTags.isEmpty else {
            return LayoutResult(nodes: [], clusterCenters: [:], allTags: [])
        }
        
        var nodes: [RenderNode] = []
        var usedPositions: [CGPoint] = []
        
        for person in limitedPeople {
            guard let firstTag = person.tags.first,
                  let tagIndex = allTags.firstIndex(of: firstTag) else {
                continue
            }
            
            // タグの色を決定
            let tagColor = colorForTag(firstTag)
            
            // 座標を計算
            let position = calculateDotPosition(
                person: person,
                center: center,
                maxRadius: maxRadius,
                allTags: allTags,
                tagIndex: tagIndex,
                usedPositions: &usedPositions,
                people: limitedPeople
            )
            
            let glowIntensity = 1.0 - person.orbitProgress
            let dotSize = 8 + CGFloat(person.orbitProgress) * 4
            
            // DTOに変換（Personオブジェクトは保持しない）
            nodes.append(RenderNode(
                id: person.id,
                name: person.name,
                initials: person.initials,
                color: tagColor,
                position: position,
                size: dotSize,
                glowIntensity: glowIntensity,
                tag: firstTag,
                iconImageData: person.iconImageData,
                daysSinceLastMeeting: person.daysSinceLastMeeting
            ))
        }
        
        return LayoutResult(nodes: nodes, clusterCenters: [:], allTags: allTags)
    }
    
    /// ニューラルネットワークビュー用のレイアウト計算（非同期）
    static func calculateNeuralNetworkLayout(
        people: [Person],
        size: CGSize
    ) async -> LayoutResult {
        // 上限チェック
        let limitedPeople = Array(people.prefix(maxRenderNodes))
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // すべてのタグを取得
        let allTags = Array(Set(limitedPeople.flatMap { $0.tags })).sorted()
        guard !allTags.isEmpty else {
            return LayoutResult(nodes: [], clusterCenters: [:], allTags: [])
        }
        
        // クラスター中心を計算
        let clusterCenters = calculateClusterCenters(
            tags: allTags,
            center: center,
            size: size
        )
        
        // 反発力シミュレーションで位置を計算
        var positions: [UUID: CGPoint] = [:]
        let repulsionForce: CGFloat = 30
        let iterations = 50
        
        // 初期位置を設定
        for person in limitedPeople {
            if let firstTag = person.tags.first,
               let clusterCenter = clusterCenters[firstTag] {
                let baseDistance: CGFloat = 40
                let maxDistance: CGFloat = 100
                let distance = baseDistance + CGFloat(person.orbitProgress) * (maxDistance - baseDistance)
                let angle = Double.random(in: 0...(2 * .pi))
                
                positions[person.id] = CGPoint(
                    x: clusterCenter.x + CGFloat(cos(angle)) * distance,
                    y: clusterCenter.y + CGFloat(sin(angle)) * distance
                )
            }
        }
        
        // 反発力シミュレーション（反復）
        for _ in 0..<iterations {
            var newPositions = positions
            
            for (id1, pos1) in positions {
                var totalForce = CGSize.zero
                
                // 他のすべてのドットからの反発力を計算
                for (id2, pos2) in positions where id1 != id2 {
                    let dx = pos1.x - pos2.x
                    let dy = pos1.y - pos2.y
                    let distance = sqrt(dx * dx + dy * dy)
                    
                    if distance > 0 && distance < 50 {
                        let force = repulsionForce / (distance * distance)
                        totalForce.width += (dx / distance) * force
                        totalForce.height += (dy / distance) * force
                    }
                }
                
                // クラスター中心への引力
                if let person = limitedPeople.first(where: { $0.id == id1 }),
                   let firstTag = person.tags.first,
                   let clusterCenter = clusterCenters[firstTag] {
                    let dx = clusterCenter.x - pos1.x
                    let dy = clusterCenter.y - pos1.y
                    let distance = sqrt(dx * dx + dy * dy)
                    
                    if distance > 0 {
                        let attraction: CGFloat = 0.5
                        totalForce.width += (dx / distance) * attraction
                        totalForce.height += (dy / distance) * attraction
                    }
                }
                
                // 位置を更新
                let newX = pos1.x + totalForce.width * 0.1
                let newY = pos1.y + totalForce.height * 0.1
                
                // 画面内に制限
                newPositions[id1] = CGPoint(
                    x: max(20, min(size.width - 20, newX)),
                    y: max(20, min(size.height - 20, newY))
                )
            }
            
            positions = newPositions
        }
        
        // RenderNodeに変換（DTO）
        var nodes: [RenderNode] = []
        for person in limitedPeople {
            if let position = positions[person.id],
               let firstTag = person.tags.first {
                let tagColor = colorForTag(firstTag)
                let glowIntensity = 1.0 - person.orbitProgress
                let dotSize = 8 + CGFloat(person.orbitProgress) * 4
                
                nodes.append(RenderNode(
                    id: person.id,
                    name: person.name,
                    initials: person.initials,
                    color: tagColor,
                    position: position,
                    size: dotSize,
                    glowIntensity: glowIntensity,
                    tag: firstTag,
                    iconImageData: person.iconImageData,
                    daysSinceLastMeeting: person.daysSinceLastMeeting
                ))
            }
        }
        
        return LayoutResult(nodes: nodes, clusterCenters: clusterCenters, allTags: allTags)
    }
    
    // MARK: - Private Helpers
    
    private static func calculateDotPosition(
        person: Person,
        center: CGPoint,
        maxRadius: CGFloat,
        allTags: [String],
        tagIndex: Int,
        usedPositions: inout [CGPoint],
        people: [Person]
    ) -> CGPoint {
        guard let firstTag = person.tags.first else {
            return center
        }
        
        // セクターの基本角度
        let sectorAngle = (2 * .pi) / Double(allTags.count)
        let baseAngle = Double(tagIndex) * sectorAngle - .pi / 2
        
        // 同じタグの人物を取得
        let sameTagPeople = people.filter { $0.tags.contains(firstTag) }
        guard let personIndex = sameTagPeople.firstIndex(where: { $0.id == person.id }) else {
            return center
        }
        
        // 半径をorbitProgressに基づいて決定
        let baseRadius: CGFloat = 50
        let maxRadiusForTag: CGFloat = maxRadius - 20
        let radius = baseRadius + CGFloat(person.orbitProgress) * (maxRadiusForTag - baseRadius)
        
        // 同じタグ内での配置（円形に整列）
        let peopleInTag = sameTagPeople.count
        let angleStep = sectorAngle / Double(max(peopleInTag, 1))
        let angleOffset = angleStep * Double(personIndex) - (sectorAngle / 2) + (angleStep / 2)
        let angle = baseAngle + angleOffset
        
        // 半径方向のオフセット（重ならないように）
        let radiusOffset = CGFloat(personIndex % 3) * 15 // 3層に分ける
        
        var position = CGPoint(
            x: center.x + CGFloat(cos(angle)) * (radius + radiusOffset),
            y: center.y + CGFloat(sin(angle)) * (radius + radiusOffset)
        )
        
        // 衝突回避：近すぎる位置を少しずらす
        position = avoidCollision(position: position, usedPositions: &usedPositions, minDistance: 20)
        
        return position
    }
    
    private static func avoidCollision(
        position: CGPoint,
        usedPositions: inout [CGPoint],
        minDistance: CGFloat
    ) -> CGPoint {
        var adjustedPosition = position
        var attempts = 0
        let maxAttempts = 10
        
        while attempts < maxAttempts {
            var hasCollision = false
            
            for usedPos in usedPositions {
                let distance = sqrt(
                    pow(adjustedPosition.x - usedPos.x, 2) +
                    pow(adjustedPosition.y - usedPos.y, 2)
                )
                
                if distance < minDistance {
                    hasCollision = true
                    // 少しずらす
                    let angle = Double.random(in: 0...(2 * .pi))
                    let offset: CGFloat = minDistance - distance + 5
                    adjustedPosition.x += CGFloat(cos(angle)) * offset
                    adjustedPosition.y += CGFloat(sin(angle)) * offset
                    break
                }
            }
            
            if !hasCollision {
                break
            }
            
            attempts += 1
        }
        
        usedPositions.append(adjustedPosition)
        return adjustedPosition
    }
    
    private static func calculateClusterCenters(
        tags: [String],
        center: CGPoint,
        size: CGSize
    ) -> [String: CGPoint] {
        var centers: [String: CGPoint] = [:]
        let radius: CGFloat = min(size.width, size.height) / 3
        
        for (index, tag) in tags.enumerated() {
            let angle = (Double(index) / Double(tags.count)) * 2 * .pi
            centers[tag] = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
        }
        
        return centers
    }
    
    private static func colorForTag(_ tag: String) -> Color {
        // ライトモード用：彩度の高い色
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
}

