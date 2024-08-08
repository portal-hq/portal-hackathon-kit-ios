//
//  ContentView.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 06/08/2024.
//

import SwiftUI
import PortalSwift

var portal: Portal?
var clientAPIKey: String?

struct ContentView: View {

    @State var solanaAddress: String? = nil
    @State var solanaBalance: String? = nil
    @State var pyusdBalance: String? = nil

    @State private var recipientAddress: String = ""
    @State private var amount: String = ""

    var body: some View {
        VStack {
            Button {
                generateWallet()
            } label: {
                Text("Generate")
            }

            if let solanaAddress {
                Text("Solana Address: \(solanaAddress)")
                Button {
                    UIPasteboard.general.string = solanaAddress
                } label: {
                    Text("Copy")
                }
                
                Button {
                    getBalance()
                } label: {
                    Text("Refresh Balance")
                }
                
            }

            if let solanaBalance {
                Text("Solana Balance: \(solanaBalance)")
            }

            if let pyusdBalance {
                Text("PYUSD Balance: \(pyusdBalance)")
            }

            if let solanaAddress {
                // TODO: - address
                Text("Recipient Address:")
                TextField("Recipient Address", text: $recipientAddress)
                // TODO: - Amount
                Text("Amount:")
                TextField("Amount", text: $amount)
                Button {
                    if !recipientAddress.isEmpty, let amountDouble = Double(amount) {
                        transferPYUSD(recipient: recipientAddress, token: "PYUSD", amount: amountDouble)
                    }
                } label: {
                    Text("Transfer PYUSD")
                }
                
            }
        }
        .padding()
        .onAppear {
            initializePortal()
        }
        .onChange(of: solanaAddress) {
            print("changed")
            getBalance()
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Create a client API Key
private extension ContentView {
    func createClientAPIKey(portalAPIKey: String) async throws -> String {
        // https://docs.portalhq.io/reference/custodian-api/v3-endpoints#create-a-new-client
        // https://api.portalhq.io/api/v3/custodians/me/clients, using custodian API Key (959498a9-88ba-40dd-bfa6-2528ce0a26e5)

        struct Response: Decodable {
            var clientApiKey: String
        }

        do {
          if let url = URL(string: "https://api.portalhq.io/api/v3/custodians/me/clients") {

              let requests = PortalRequests()
              let data = try await requests.post(url, withBearerToken: portalAPIKey)
              let decoder = JSONDecoder()
              let response = try decoder.decode(Response.self, from: data)
              return response.clientApiKey
          }

          throw URLError(.badURL)
        } catch {
            print("Unable to get client API Key!.")
          throw error
        }
    }
}

// MARK: - Initialize Portal
private extension ContentView {
    func initializePortal() {
        Task {
            do {
                
                clientAPIKey = try await createClientAPIKey(portalAPIKey: "959498a9-88ba-40dd-bfa6-2528ce0a26e5")
                guard let clientAPIKey else {
                    print("Client API Key cannot be found")
                    return
                }
                portal = try Portal(
                    clientAPIKey,
                    withRpcConfig: [
                        "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp" : "https://api.mainnet-beta.solana.com",
                        "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1": "https://api.devnet.solana.com"
                    ],
                    autoApprove: true
                )
                print("Portal initialized.")
            } catch {
                print("❌ Error initializing portal:", error)
            }
        }
    }
}

// MARK: - Generate wallet
private extension ContentView {
    func generateWallet() {
        guard let portal else {
            print("Portal not initialized, please call \"initializePortal()\" first.")
            return
        }

        Task {
            do {
                let wallets = try await portal.createWallet()
                print("✅ wallet created successfully - Solana address: \(wallets.solana ?? "")")
                solanaAddress = wallets.solana
            } catch {
                print("❌ Error generating wallet:", error)
            }
        }
    }
}

// MARK: - Get Balance
private extension ContentView {
    func getBalance() {
        Task {
            if let balances = try? await getAssets() {
                solanaBalance = balances.solanaBalance
                pyusdBalance = balances.pyusdBalance
            }
        }
    }

    func getAssets() async throws -> (solanaBalance: String?, pyusdBalance: String?) {

        guard let clientAPIKey else {
            print("Client API Key cannot be found")
            return (nil, nil)
        }

        do {
          if let url = URL(string: "https://api.portalhq.io/api/v3/clients/me/chains/solana-devnet/assets") {

              let requests = PortalRequests()
              let data = try await requests.get(url, withBearerToken: clientAPIKey)
              let decoder = JSONDecoder()
              let response = try decoder.decode(Assets.self, from: data)
              return (response.nativeBalance.balance, response.tokenBalances.getBalance(for: "PYUSD"))
          }

          throw URLError(.badURL)
        } catch {
            print("Unable to get assets with error: \(error)")
            throw error
        }
    }
}

struct Assets: Codable {
    let nativeBalance: NativeBalance
    let tokenBalances: [TokenBalance]
}

struct NativeBalance: Codable {
    let balance: String
    let decimals: Int
    let name, rawBalance, symbol: String
}

struct TokenBalance: Codable {
    let balance: String
    let decimals: Int
    let name, rawBalance, symbol: String
    let metadata: TokenBalanceMetadata
}

struct TokenBalanceMetadata: Codable {
    let tokenAccountAddress, tokenMintAddress: String
}

extension Array where Element == TokenBalance {
    func getBalance(for symbol: String) -> String? {
        if let token = self.first(where: { $0.symbol == symbol }) {
            return token.balance
        } else {
            return nil
        }
    }
}

// MARK: - Transfer PYUSD to another account
private extension ContentView {
    func buildTransaction(recipient: String, token: String, amount: Double) async -> BuildTransactionResponse? {
        guard let clientAPIKey else {
            print("Client API Key cannot be found")
            return nil
        }

        do {
          if let url = URL(string: "https://api.portalhq.io/api/v3/clients/me/chains/solana-devnet/assets/send/build-transaction") {

              let payload = ["to" : recipient, "token" : token, "amount" : "\(amount)"]
              let requests = PortalRequests()
              let data = try await requests.post(url, withBearerToken: clientAPIKey, andPayload: payload)
              let decoder = JSONDecoder()
              let response = try decoder.decode(BuildTransactionResponse.self, from: data)
              print(response)
              return response
          }
        } catch {
            print("Unable to build transaction with error: \(error)")
        }

        return nil
    }

    func submitTransation(base64Transaction: String) async {
        do {
            let result = try await portal?.request("solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1", withMethod: "sol_signAndSendTransaction", andParams: [base64Transaction])
            print("Transaction Hash: \(result)")
        } catch {
            print("Unable to sign and send transaction with error: \(error)")
        }
    }

    func transferPYUSD(recipient: String, token: String, amount: Double) {
        Task {
            if let transaction = await buildTransaction(recipient: recipient, token: "PYUSD", amount: amount) {
                await submitTransation(base64Transaction: transaction.transaction)
            }
        }
    }
}

struct BuildTransactionResponse: Codable {
    let transaction: String
}
