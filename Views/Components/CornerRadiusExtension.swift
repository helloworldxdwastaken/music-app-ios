//
//  CornerRadiusExtension.swift
//  Music Stream
//

import SwiftUI
import UIKit

extension View {
    func cornerRadius(_ radius: CGFloat, corners: [UIRectCorner]) -> some View {
        var cornerSet: UIRectCorner = []
        for corner in corners {
            cornerSet.formUnion(corner)
        }
        return clipShape(RoundedCorner(radius: radius, corners: cornerSet))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

