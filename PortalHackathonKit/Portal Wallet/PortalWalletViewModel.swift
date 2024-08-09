//
//  PortalWalletViewModel.swift
//  PortalHackathonKit
//
//  Created by Ahmed Ragab on 08/08/2024.
//

import UIKit
import PortalSwift

/// ``PortalWalletViewModel`` handles all the Portal Logic
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
    /// refresh the UI displaying the ``solanaAddress``, ``solanaBalance``, ``pyusdBalance`` and ``transactionHash``
    func refreshWalletUI() {
        if let solanaAddress {
            setState(
                .generated(address: solanaAddress, solBalance: solanaBalance ?? "0", pyUSDBalance: pyusdBalance ?? "0", transactionHash: transactionHash)
            )
        }
    }

    /// set the ``state`` property on the ``MainThread`` to change it safely from any ``Async`` context.
    func setState(_ state: walletUIState) {
        Task { @MainActor in
            self.state = state
        }
    }
}

// MARK: - Copy helpers
extension PortalWalletViewModel {
    /// Copy the wallet address to the clip board
    func copyAddress() {
        UIPasteboard.general.string = solanaAddress
    }

    /// Copy the recent transaction hash to the clip board
    func copyTransactionHash() {
        UIPasteboard.general.string = transactionHash
    }
}

// MARK: - Create a client API Key
private extension PortalWalletViewModel {
    /// Given the ``portalAPIKey`` create ``ClientAPIKey`` for that client.
    /// Important Note: In real life product this call should be in the Backend, just as an example we keep it here.
    func createClientAPIKey(portalAPIKey: String) async throws -> String {
        
        struct Response: Decodable {
            var clientApiKey: String
        }
        
        do {
            // API call to generate the ClientAPIKey for that client.
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
                // get ClientAPIKey given the portalAPIKey.
                clientAPIKey = try await createClientAPIKey(portalAPIKey: Constants.PORTAL_API_KEY)

                guard let clientAPIKey else {
                    setState(.error(errorMessage: "Client API Key cannot be found"))
                    print("❌ Client API Key cannot be found")
                    return
                }

                // Initialize Portal SDK
                portal = try Portal(
                    clientAPIKey,
                    withRpcConfig: [
                        "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp" : "https://api.mainnet-beta.solana.com",
                        "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1": "https://api.devnet.solana.com"
                    ],
                    autoApprove: true // keep it ``true`` to auto approve all the signing requests if needed.
                )

                // Update the UI that Portal Initialized
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
    /// Generate wallet to the user
    func generateWallet() {
        // early return if the portal is not initialized.
        guard let portal else {
            setState(.error(errorMessage: "❌ Portal not initialized, please call \"initializePortal()\" first."))
            print("❌ Portal not initialized, please call \"initializePortal()\" first.")
            return
        }

        // Update the UI show loader
        setState(.loading)

        Task {
            do {
                // create a the wallet
                let wallets = try await portal.createWallet()
                print("✅ wallet created successfully - Solana address: \(wallets.solana ?? "")")
                solanaAddress = wallets.solana

                // get the balance for the wallet
                getBalance()
            } catch {
                print("❌ Error generating wallet:", error.localizedDescription)
            }
        }
    }
}

// MARK: - Get Balance
extension PortalWalletViewModel {
    /// Get the wallet balance and update the UI with the new fetched balances.
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

    /// Get the assets for the user to get all the balances
    private func getAssets() async throws -> (solanaBalance: String?, pyusdBalance: String?) {

        // early return if the client API Key not found.
        guard let clientAPIKey else {
            print("❌ Client API Key cannot be found")
            return (nil, nil)
        }
        
        do {
            // API call to get the assets for the user.
            if let url = URL(string: "https://api.portalhq.io/api/v3/clients/me/chains/solana-devnet/assets") {
                let requests = PortalRequests()
                let data = try await requests.get(url, withBearerToken: clientAPIKey)
                let decoder = JSONDecoder()
                let response = try decoder.decode(Assets.self, from: data)
                // return Solana native balance, and PyUSD balance.
                return (response.nativeBalance.balance, response.tokenBalances.getBalance(for: "PYUSD"))
            }
            
            throw URLError(.badURL)
        } catch {
            print("❌ Unable to get assets with error: \(error)")
            throw error
        }
    }
}

/// Codable model for decoding the Assets API response.
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

// helper extension to the Array where the Element is TokenBalance to get the Balance for given symbol token.
extension Array where Element == TokenBalance {
    /// Get the Balance for given symbol token.
    func getBalance(for symbol: String) -> String? {
        if let token = self.first(where: { $0.symbol == symbol }) {
            return token.balance
        } else {
            return nil
        }
    }
}

// MARK: - Transfer PyUSD to another wallet
extension PortalWalletViewModel {
    /// Transfere PyUSD ``amount`` to ``recipient`` from the user wallet.
    func transferPyUSD(recipient: String, amount: String) {
        Task {
            // validate the recipient address is not empty and the amount is a valid double number.
            if !recipient.isEmpty, let amountDouble = Double(amount) {
                // Update the UI show loader
                setState(.loading)
                // build the transaction
                if let transaction = await buildTransaction(recipient: recipient, token: "PYUSD", amount: amountDouble) {
                    // submit the transaction
                    await submitTransaction(base64Transaction: transaction)
                }
            } else {
                // print error message if the input is not valid.
                print("❌ please enter valid address and amount in order to continue.")
            }
        }
    }

    /// Build a transaction given ``recipient`` address, ``token`` and ``amount``
    private func buildTransaction(recipient: String, token: String, amount: Double) async -> String? {

        /// Codable model for decoding the ``build-transaction`` API response.
        struct BuildTransactionResponse: Codable {
            // Note: we only need the ``transaction`` that's why we only decode it here.
            let transaction: String
        }

        // early return if the client API Key not found.
        guard let clientAPIKey else {
            // refresh the UI to display the wallet data instead of the loader
            refreshWalletUI()
            print("❌ Client API Key cannot be found")
            return nil
        }
        
        do {
            // API call to build the transaction.
            if let url = URL(string: "https://api.portalhq.io/api/v3/clients/me/chains/solana-devnet/assets/send/build-transaction") {
                // prepare the payload for the request.
                let payload = ["to" : recipient, "token" : token, "amount" : "\(amount)"]
                let requests = PortalRequests()
                let data = try await requests.post(url, withBearerToken: clientAPIKey, andPayload: payload)
                let decoder = JSONDecoder()
                let response = try decoder.decode(BuildTransactionResponse.self, from: data)
                print(response)
                // return the transaction string.
                return response.transaction
            }
        } catch {
            // refresh the UI to display the wallet data instead of the loader
            refreshWalletUI()
            print("❌ Unable to build transaction with error: \(error)")
        }
        
        return nil
    }

    /// Submit the transaction given the ``base64Transaction`` String.
    private func submitTransaction(base64Transaction: String) async {
        do {
            // sign and send the transaction given the ``chainId``.
            let result = try await portal?.request("solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1", withMethod: "sol_signAndSendTransaction", andParams: [base64Transaction])
            if let hash = result?.result as? String {
                // display the hash to the user
                transactionHash = hash
                refreshWalletUI()
                print("✅ Transaction Hash: \(hash)")
            }
        } catch {
            // refresh the UI to display the wallet data instead of the loader
            refreshWalletUI()
            print("❌ Unable to sign and send transaction with error: \(error)")
        }
    }
}
