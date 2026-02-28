// CompassImageGenerator.swift
// 罗盘图片生成器
// 见 PHASE_V0_SPEC.md 2.1节

import UIKit
import CoreGraphics

/// 罗盘图片生成器
class CompassImageGenerator {

    /// 生成罗盘图片
    /// - Parameter size: 图片尺寸（默认1000x1000）
    /// - Returns: 罗盘UIImage
    static func generateCompassImage(size: CGFloat = 1000) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        return renderer.image { context in
            let ctx = context.cgContext
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2

            // 背景透明
            ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))

            // 绘制外圆
            ctx.setStrokeColor(UIColor.black.cgColor)
            ctx.setLineWidth(4)
            ctx.addArc(center: center, radius: radius - 10, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            ctx.strokePath()

            // 绘制24山刻度
            for i in 0..<24 {
                let angle = Double(i) * 15.0 * .pi / 180.0 - .pi / 2  // 从正北开始
                let startRadius = radius - 30
                let endRadius = radius - 10

                let startX = center.x + CGFloat(cos(angle)) * startRadius
                let startY = center.y + CGFloat(sin(angle)) * startRadius
                let endX = center.x + CGFloat(cos(angle)) * endRadius
                let endY = center.y + CGFloat(sin(angle)) * endRadius

                ctx.move(to: CGPoint(x: startX, y: startY))
                ctx.addLine(to: CGPoint(x: endX, y: endY))
                ctx.strokePath()

                // 绘制24山文字
                let mountain = Mountain.allMountains[i]
                let textRadius = radius - 60
                let textX = center.x + CGFloat(cos(angle)) * textRadius
                let textY = center.y + CGFloat(sin(angle)) * textRadius

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.black
                ]

                let text = mountain.chineseName as NSString
                let textSize = text.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: textX - textSize.width / 2,
                    y: textY - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                text.draw(in: textRect, withAttributes: attributes)
            }

            // 绘制中心圆
            ctx.setFillColor(UIColor.red.cgColor)
            ctx.addArc(center: center, radius: 10, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            ctx.fillPath()

            // 绘制正北指示（红色三角形）
            ctx.setFillColor(UIColor.red.cgColor)
            let northTriangle = UIBezierPath()
            northTriangle.move(to: CGPoint(x: center.x, y: 20))
            northTriangle.addLine(to: CGPoint(x: center.x - 15, y: 50))
            northTriangle.addLine(to: CGPoint(x: center.x + 15, y: 50))
            northTriangle.close()
            northTriangle.fill()
        }
    }
}
