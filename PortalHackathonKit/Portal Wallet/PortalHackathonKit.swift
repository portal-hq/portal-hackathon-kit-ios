//
//  PortalHackathonKit.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 06/08/2024.
//

import SwiftUI

struct PortalHackathonKit: View {

    // PortalWalletViewModel handles all the Portal Logic
    @ObservedObject private var portalWalletViewModel = PortalWalletViewModel()

    // MARK: - properties
    @State private var recipientAddress: String = ""
    @State private var amount: String = ""

    var body: some View {
        VStack {
            switch portalWalletViewModel.state {
            case .loading:
                // Loader
                ProgressView()
                    .scaleEffect(2)
                    .tint(.blue)
                
            case let .portalInitialized(isRecoverAvailable):
                // Generate or Recover Wallet View
                PortalInitializedView(isRecoverAvailable: isRecoverAvailable, onGenerateWalletClicked: {
                    portalWalletViewModel.generateWallet()
                }) { password in
                    portalWalletViewModel.recoverWallet(with: password)
                }

            case let .generated(address, solBalance, pyUSDBalance, transactionHash):
                // Wallet Data View
                PortalSolanaWalletView(solanaAddress: address, solanaBalance: solBalance, pyUsdBalance: pyUSDBalance, onCopyAddressClick:  {
                    portalWalletViewModel.copyAddress()
                }, onRefreshBalanceClick:  {
                    portalWalletViewModel.getBalance()
                }) { password in
                    portalWalletViewModel.backupWallet(with: password)
                }

                // Send PYUSD Form View
                PortalSendPYUSDFormView(recipientAddress: $recipientAddress, amount: $amount) {
                    portalWalletViewModel.transferPYUSD(recipient: recipientAddress, amount: amount)
                }

                // The Sent transaction hash
                if let transactionHash {
                    PortalTransactionHashView(transactionHash: transactionHash) {
                        portalWalletViewModel.copyTransactionHash()
                    }
                }

                // Bottom space
                Spacer()
            case .error(let errorMessage):
                // Label to show the error
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
