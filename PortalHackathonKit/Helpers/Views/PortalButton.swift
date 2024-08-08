//
//  PortalButton.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 08/08/2024.
//

import SwiftUI

enum ButtonStyle {
    case primary
    case secondary
}

struct PortalButton: View {
    var title: String?
    var style: ButtonStyle = .primary
    var onPress: (() -> Void)?
    var cornerRadius: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            getButton(for: geometry, style: style)
        }
    }

    @ViewBuilder func getButton(for geometry: GeometryProxy, style: ButtonStyle) -> some View {
        Button {
            onPress?()
        } label: {
            Text(title ?? "")
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                .background(getBackgroundColor(for: style))
                .foregroundColor(getForegroundColor(for: style))
                .font(.headline)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        .background(getBackgroundColor(for: style))
        .foregroundColor(getForegroundColor(for: style))
        .font(.headline)
        .cornerRadius(cornerRadius)
        .clipped()
    }

    func getBackgroundColor(for style: ButtonStyle) -> Color? {
        switch(style){
        case .primary:
            return .black
        case .secondary:
            return .gray
        }
    }

    func getForegroundColor(for style: ButtonStyle) -> Color? {
        switch(style){
        case .primary:
            return .white
        case .secondary:
            return .black
        }
    }
}

#Preview {
    PortalButton()
        .previewLayout(.fixed(width: 200, height: 80))
}
