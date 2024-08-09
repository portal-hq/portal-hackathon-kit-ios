//
//  PortalSendPyUSDFormView.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 08/08/2024.
//

import SwiftUI

/// Reusable Send PyUSD Form View.
struct PortalSendPyUSDFormView: View {
    @Binding var recipientAddress: String
    @Binding var amount: String
    var onSendPress: (() -> Void)?

    var body: some View {
        VStack {
            LeadingText("Send PyUSD")
                .font(.title)
                .bold()
                .padding(.bottom, 10)

            VStack {
                LeadingText("RECIPIENT")
                    .font(.subheadline)
             
                TextField("Recipient Address", text: $recipientAddress)
                    .frame(height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray, lineWidth: 1))
                    .padding(.bottom)

                LeadingText("AMOUNT")
                    .font(.subheadline)
             
                TextField("Ammount", text: $amount)
                    .keyboardType(.numberPad)
                    .frame(height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray, lineWidth: 1))

                PortalButton(title: "Send PyUSD") {
                    onSendPress?()
                }
                .frame(height: 45)
                .padding(.top)
            }
            .padding([.leading, .trailing], 20)
        }
    }
}

#Preview {
    PortalSendPyUSDFormView(recipientAddress: .constant(""), amount: .constant(""))
}
