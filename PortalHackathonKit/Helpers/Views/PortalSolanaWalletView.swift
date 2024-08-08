//
//  PortalSolanaWalletView.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 08/08/2024.
//

import SwiftUI

struct PortalSolanaWalletView: View {
    let solanaAddress: String
    let solanaBalance: String?
    let pyUsdBalance: String?

    var onCopyAddressClick: (() -> Void)?
    var onRefreshBalanceClick: (() -> Void)?
    
    var body: some View {
        VStack {
            LeadingText("Wallet")
                .font(.title)
                .bold()
                .padding(.bottom, 10)

            VStack {
                HStack {
                    Text("ADDRESS:")
                        .font(.headline)
                        .bold()

                    Button {
                        onCopyAddressClick?()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    Spacer()
                }
                
                LeadingText(solanaAddress)
                    .font(.body)
                    .padding(.bottom, 10)
                
                if let solanaBalance {
                    HStack {
                        Text("SOL BALANCE:")
                            .font(.headline)
                            .bold()

                        Button {
                            onRefreshBalanceClick?()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Spacer()
                    }
                    
                    LeadingText("\(solanaBalance) SOL")
                        .font(.body)
                        .padding(.bottom, 10)
                }
                
                if let pyUsdBalance {
                    HStack {
                        Text("PYUSD BALANCE:")
                            .font(.headline)
                            .bold()

                        Button {
                            onRefreshBalanceClick?()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Spacer()
                    }
                    
                    LeadingText("\(pyUsdBalance) PyUSD")
                        .font(.body)
                        .padding(.bottom, 10)
                }
            }
            .padding([.leading, .trailing], 20)
        }
    }
}

#Preview {
    PortalSolanaWalletView(solanaAddress: "the address should be here...", solanaBalance: "5", pyUsdBalance: "100")
}
