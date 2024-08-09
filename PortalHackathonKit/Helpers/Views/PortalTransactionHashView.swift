//
//  PortalTransactionHashView.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 09/08/2024.
//

import SwiftUI

/// Reusable Transaction Hash View
struct PortalTransactionHashView: View {

    let transactionHash: String
    var onCopyTransactionHashClick: (() -> Void)?

    var body: some View {
        VStack {
            HStack {
                Text("RECENT TRANSACTION HASH:")
                    .font(.headline)
                    .bold()

                Button {
                    onCopyTransactionHashClick?()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                Spacer()
            }
            LeadingText(transactionHash)
                .font(.body)
        }
        .padding([.leading, .trailing], 20)

    }
}

#Preview {
    PortalTransactionHashView(transactionHash: "Transaction hash...")
}
