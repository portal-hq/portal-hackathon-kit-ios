//
//  PortalWalletViewModel.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 08/08/2024.
//

import UIKit
import PortalSwift

public final class PortalWalletViewModel: ObservableObject {

    enum walletUIState {
        case loading
        case portalInitialized
        case generated(address: String, solBalance: String, pyUSDBalance: String, transactionHash: String?)
        case error(errorMessage: String)
    }

    // MARK: - Properties
    private var portal: Portal?
    private var clientAPIKey: String?
    private var solanaAddress: String?
    private var solanaBalance: String?
    private var pyusdBalance: String?
    private var transactionHash: String?

    // MARK: - UI Properties
    @Published private(set) var state: walletUIState = .loading

    init() {
        initializePortal()
    }

}

// MARK: - Presentation Helpers
private extension PortalWalletViewModel {
    func refreshWalletUI() {
        if let solanaAddress {
            setState(
                .generated(address: solanaAddress, solBalance: solanaBalance ?? "0", pyUSDBalance: pyusdBalance ?? "0", transactionHash: transactionHash)
            )
        }
    }

    func setState(_ state: walletUIState) {
        Task { @MainActor in
            self.state = state
        }
    }
}

// MARK: - Copy helpers
extension PortalWalletViewModel {
    func copyAddress() {
        UIPasteboard.general.string = solanaAddress
    }

    func copyTransactionHash() {
        UIPasteboard.general.string = transactionHash
    }
}

// MARK: - Create a client API Key
private extension PortalWalletViewModel {
    func createClientAPIKey(portalAPIKey: String) async throws -> String {

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
            print("❌ Unable to get client API Key!.")
          throw error
        }
    }
}

// MARK: - Initialize Portal
private extension PortalWalletViewModel {
    func initializePortal() {
        Task {
            do {
                
                clientAPIKey = try await createClientAPIKey(portalAPIKey: "959498a9-88ba-40dd-bfa6-2528ce0a26e5")
                guard let clientAPIKey else {
                    setState(.error(errorMessage: "Client API Key cannot be found"))
                    print("❌ Client API Key cannot be found")
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
                setState(.portalInitialized)
                print("✅ Portal initialized.")
            } catch {
                setState(.error(errorMessage: "❌ Error initializing portal: \(error.localizedDescription)"))
                print("❌ Error initializing portal:", error.localizedDescription)
            }
        }
    }
}

// MARK: - Generate wallet
extension PortalWalletViewModel {
    func generateWallet() {
        guard let portal else {
            setState(.error(errorMessage: "❌ Portal not initialized, please call \"initializePortal()\" first."))
            print("❌ Portal not initialized, please call \"initializePortal()\" first.")
            return
        }

        setState(.loading)

        Task {
            do {
                let wallets = try await portal.createWallet()
                print("✅ wallet created successfully - Solana address: \(wallets.solana ?? "")")
                solanaAddress = wallets.solana

                getBalance()
            } catch {
                print("❌ Error generating wallet:", error.localizedDescription)
            }
        }
    }
}

// MARK: - Get Balance
extension PortalWalletViewModel {
    func getBalance() {
        Task {
            if let balances = try? await getAssets() {
                solanaBalance = balances.solanaBalance
                pyusdBalance = balances.pyusdBalance
                refreshWalletUI()
            } else {
                refreshWalletUI()
            }
        }
    }

    private func getAssets() async throws -> (solanaBalance: String?, pyusdBalance: String?) {

        guard let clientAPIKey else {
            print("❌ Client API Key cannot be found")
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
            print("❌ Unable to get assets with error: \(error)")
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

// MARK: - Transfer PYUSD to another wallet
extension PortalWalletViewModel {
    func transferPYUSD(recipient: String, amount: String) {
        Task {
            if !recipient.isEmpty, let amountDouble = Double(amount) {
                setState(.loading)
                if let transaction = await buildTransaction(recipient: recipient, token: "PYUSD", amount: amountDouble) {
                    await submitTransation(base64Transaction: transaction)
                }
            } else {
                print("❌ please enter valid address and amount in order to continue.")
            }
        }
    }

    private func buildTransaction(recipient: String, token: String, amount: Double) async -> String? {

        struct BuildTransactionResponse: Codable {
            let transaction: String
        }

        guard let clientAPIKey else {
            refreshWalletUI()
            print("❌ Client API Key cannot be found")
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
              return response.transaction
          }
        } catch {
            refreshWalletUI()
            print("❌ Unable to build transaction with error: \(error)")
        }

        return nil
    }

    private func submitTransation(base64Transaction: String) async {
        do {
            let result = try await portal?.request("solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1", withMethod: "sol_signAndSendTransaction", andParams: [base64Transaction])
            if let hash = result?.result as? String {
                transactionHash = hash
                refreshWalletUI()
                print("✅ Transaction Hash: \(hash)")
            }
        } catch {
            refreshWalletUI()
            print("❌ Unable to sign and send transaction with error: \(error)")
        }
    }
}
