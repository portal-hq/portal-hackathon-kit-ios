//
//  PortalSolanaWalletView.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 08/08/2024.
//

import SwiftUI

/// Reusable Wallet View
struct PortalSolanaWalletView: View {
    let solanaAddress: String
    let solanaBalance: String?
    let pyUsdBalance: String?

    var onCopyAddressClick: (() -> Void)?
    var onRefreshBalanceClick: (() -> Void)?
    var onBackupWalletClick: ((_ password: String) -> Void)?
    
    @State private var showPasswordAlert = false
    @State private var backupPassword: String = ""

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text("Wallet")
                    .font(.title)
                    .bold()
                Spacer()
                PortalButton(title: "Backup Wallet", style: .secondary) {
                    showPasswordAlert.toggle()
                }
                .frame(width: 150, height: 30)
            }
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
                    
                    LeadingText("\(pyUsdBalance) PYUSD")
                        .font(.body)
                        .padding(.bottom, 10)
                }
            }
            .padding([.leading, .trailing], 20)
        }
        .alert("Enter Password", isPresented: $showPasswordAlert) {
            SecureField("PASSWORD", text: $backupPassword)
                .keyboardType(.numberPad)
                .textContentType(.password)
            
            Button("Submit") {
                onBackupWalletClick?(backupPassword)
            }
            Button("Cancel", role: .cancel, action: {})
        }
    }
}

#Preview {
    PortalSolanaWalletView(solanaAddress: "the address should be here...", solanaBalance: "5", pyUsdBalance: "100")
}
