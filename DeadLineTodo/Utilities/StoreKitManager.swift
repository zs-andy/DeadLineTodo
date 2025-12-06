//
//  StoreKitManager.swift
//  DeadLineTodo
//
//  Handles in-app purchases
//

import Foundation
import StoreKit

public enum StoreError: Error {
    case failedVerification
}

@MainActor
final class StoreKitManager: ObservableObject {
    
    @Published var storeProducts: [Product] = []
    @Published var purchasedCourses: [Product] = []
    @Published var hasPurchased = false
    
    private var updateListenerTask: Task<Void, Error>?
    private let productDict: [String: String]
    
    init() {
        // 加载产品列表
        if let plistPath = Bundle.main.path(forResource: "PropertyList", ofType: "plist"),
           let plist = FileManager.default.contents(atPath: plistPath) {
            productDict = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String]) ?? [:]
        } else {
            productDict = [:]
        }
        
        // 初始化
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
        
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    // MARK: - Request Products
    
    @MainActor
    func requestProducts() async {
        do {
            storeProducts = try await Product.products(for: productDict.values)
        } catch {
            print("Failed to retrieve products: \(error)")
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }
    
    // MARK: - Update Status
    
    @MainActor
    func updateCustomerProductStatus() async {
        var purchased: [Product] = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if let product = storeProducts.first(where: { $0.id == transaction.productID }) {
                    purchased.append(product)
                }
            } catch {
                print("Transaction failed verification")
            }
        }
        
        purchasedCourses = purchased
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            await updateCustomerProductStatus()
            await transaction.finish()
        case .pending:
            print("Purchase pending")
        case .userCancelled:
            print("User cancelled")
        @unknown default:
            break
        }
    }
    
    // MARK: - Check Purchase
    
    func isPurchased(_ product: Product) async throws -> Bool {
        purchasedCourses.contains(product)
    }
}
