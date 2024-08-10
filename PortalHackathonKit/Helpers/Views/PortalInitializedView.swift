//
//  PortalInitializedView.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 10/08/2024.
//

import SwiftUI

struct PortalInitializedView: View {

    let isRecoverAvailable: Bool
    var onGenerateWalletClicked: (() -> Void)?
    var onRecoverWalletClicked: ((_ password: String) -> Void)?
    
    @State private var showPasswordAlert = false
    @State private var recoverPassword: String = ""

    var body: some View {
        VStack {
            if isRecoverAvailable {
                Text("Wallet is available on the device. Recover it to continue!")
                    .multilineTextAlignment(.center)
            } else {
                Text("No wallet is available on the device. Let's create one!")
                    .multilineTextAlignment(.center)
            }

            PortalButton(title: "Generate") {
                onGenerateWalletClicked?()
            }
            .frame(width: 200, height: 45)
            
            if isRecoverAvailable {
                PortalButton(title: "Recover Wallet", style: .secondary) {
                    showPasswordAlert.toggle()
                }
                .frame(width: 200, height: 45)
            }
        }
        .alert("Enter Password", isPresented: $showPasswordAlert) {
            SecureField("PASSWORD", text: $recoverPassword)
                .keyboardType(.numberPad)
                .textContentType(.password)
            
            Button("Submit") {
                onRecoverWalletClicked?(recoverPassword)
            }
            Button("Cancel", role: .cancel, action: {})
        }
    }
}

#Preview {
    PortalInitializedView(isRecoverAvailable: false)
}
