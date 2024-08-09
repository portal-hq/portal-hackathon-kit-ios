//
//  LeadingText.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 08/08/2024.
//

import SwiftUI

/// Reusable Leading Text View
struct LeadingText: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
            Spacer()
        }
    }

    init(_ text: String) {
        self.text = text
    }
}

#Preview {
    LeadingText("Wallet")
}
