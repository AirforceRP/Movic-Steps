//
//  SVGIconView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/20/25.
//

import SwiftUI

// MARK: - SVG Icon View
struct SVGIconView: View {
    let iconName: String
    let size: CGFloat
    let color: Color
    @Environment(\.colorBlindnessType) private var colorBlindnessType
    
    init(_ iconName: String, size: CGFloat = 24, color: Color = .primary) {
        self.iconName = iconName
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundColor(color.adjustedForColorBlindness(colorBlindnessType))
    }
}

// MARK: - Icon Names Enum
enum AppIcon: String, CaseIterable {
    case alertCircle = "alert-circle"
    case alertSquare = "alert-square"
    case bellRing = "bell-ring"
    case bullseye = "bullseye"
    case chartSpline = "chart-spline"
    case cog = "cog"
    case fireExtinguisher = "fire-extinguisher"
    case walking = "walking"
    
    var systemName: String {
        switch self {
        case .alertCircle:
            return "exclamationmark.circle"
        case .alertSquare:
            return "exclamationmark.square"
        case .bellRing:
            return "bell"
        case .bullseye:
            return "target"
        case .chartSpline:
            return "chart.line.uptrend.xyaxis"
        case .cog:
            return "gear"
        case .fireExtinguisher:
            return "flame"
        case .walking:
            return "figure.walk"
        }
    }
}

// MARK: - Convenience Extensions
extension View {
    func appIcon(_ icon: AppIcon, size: CGFloat = 24, color: Color = .primary) -> some View {
        SVGIconView(icon.rawValue, size: size, color: color)
    }
    
    func appIcon(_ iconName: String, size: CGFloat = 24, color: Color = .primary) -> some View {
        SVGIconView(iconName, size: size, color: color)
    }
}
