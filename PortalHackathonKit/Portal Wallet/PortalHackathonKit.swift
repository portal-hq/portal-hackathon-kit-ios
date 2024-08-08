//
//  PortalHackathonKit.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 06/08/2024.
//

import SwiftUI

struct PortalHackathonKit: View {

    @ObservedObject private var portalWalletViewModel = PortalWalletViewModel()

    @State private var recipientAddress: String = ""
    @State private var amount: String = ""

    var body: some View {
        VStack {
            switch portalWalletViewModel.state {
            case .loading:
                ProgressView()
                    .scaleEffect(2)
                    .tint(.blue)
            case .portalInitialized:
                PortalButton(title: "Generate") {
                    portalWalletViewModel.generateWallet()
                }
                .frame(width: 200, height: 45)
            case let .generated(address, solBalance, pyUSDBalance, transactionHash):

                PortalSolanaWalletView(solanaAddress: address, solanaBalance: solBalance, pyUsdBalance: pyUSDBalance, onCopyAddressClick:  {
                    portalWalletViewModel.copyAddress()
                }) {
                    portalWalletViewModel.getBalance()
                }

                PortalSendPyUSDFormView(recipientAddress: $recipientAddress, amount: $amount) {
                    portalWalletViewModel.transferPYUSD(recipient: recipientAddress, amount: amount)
                }

                if let transactionHash {
                    PortalTransactionHashView(transactionHash: transactionHash) {
                        portalWalletViewModel.copyTransactionHash()
                    }
                }
                Spacer()
            case .error(let errorMessage):
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

#Preview {
    PortalHackathonKit()
}
