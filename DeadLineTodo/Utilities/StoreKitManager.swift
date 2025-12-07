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
    case productNotFound
}

@MainActor
final class StoreKitManager: ObservableObject {
    
    @Published var storeProducts: [Product] = []
    @Published var purchasedCourses: [Product] = []
    @Published var hasPurchased = false
    @Published var isLoading = false
    @Published var loadError: String?
    
    private var updateListenerTask: Task<Void, Error>?
    private let productIds: Set<String>
    
    // 所有有效的产品ID，用于直接验证购买状态
    private static let validProductIds: Set<String> = [
        "andy.deadlinetodo.premium",
        "andy.deadlinetodo.monthly.subscription",
        "andy.deadlinetodo.quarterly.subscription",
        "andy.deadlinetodo.annual.subscription"
    ]
    
    init() {
        // 加载产品列表
        if let plistPath = Bundle.main.path(forResource: "PropertyList", ofType: "plist"),
           let plist = FileManager.default.contents(atPath: plistPath),
           let dict = try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String] {
            productIds = Set(dict.values)
        } else {
            productIds = Self.validProductIds
        }
        
        updateListenerTask = listenForTransactions()
        
        // 初始化时先检查购买状态，再加载商品
        Task {
            await checkEntitlementsDirectly()
            await requestProducts()
        }
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
        guard !productIds.isEmpty else {
            loadError = "加载失败，请检查网络"
            return
        }
        
        isLoading = true
        loadError = nil
        
        do {
            let products = try await Product.products(for: productIds)
            
            if products.isEmpty {
                loadError = "加载失败，请检查网络"
            } else {
                // 按价格排序：永久购买优先，然后按价格升序
                storeProducts = products.sorted { p1, p2 in
                    if p1.type == .nonConsumable && p2.type != .nonConsumable {
                        return true
                    }
                    if p1.type != .nonConsumable && p2.type == .nonConsumable {
                        return false
                    }
                    return p1.price < p2.price
                }
                
                // 加载成功后，更新购买状态
                await updateCustomerProductStatus()
            }
        } catch {
            print("Failed to retrieve products: \(error)")
            loadError = "加载失败，请检查网络"
        }
        
        isLoading = false
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
    
    // MARK: - Check Entitlements Directly (不依赖商品列表)
    
    /// 直接检查用户是否有有效的购买权益，不依赖商品列表
    @MainActor
    func checkEntitlementsDirectly() async {
        var hasValidPurchase = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // 检查是否是我们的产品
                if Self.validProductIds.contains(transaction.productID) {
                    // 对于订阅，检查是否过期
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            hasValidPurchase = true
                            break
                        }
                    } else {
                        // 非消耗型购买（永久购买）
                        hasValidPurchase = true
                        break
                    }
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        hasPurchased = hasValidPurchase
    }
    
    // MARK: - Update Status
    
    @MainActor
    func updateCustomerProductStatus() async {
        var purchased: [Product] = []
        var hasValidPurchase = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // 检查是否是有效购买
                let isValid: Bool
                if let expirationDate = transaction.expirationDate {
                    isValid = expirationDate > Date()
                } else {
                    isValid = true // 永久购买
                }
                
                if isValid {
                    hasValidPurchase = true
                    
                    // 如果商品列表已加载，添加到已购买列表
                    if let product = storeProducts.first(where: { $0.id == transaction.productID }) {
                        purchased.append(product)
                    }
                }
            } catch {
                print("Transaction failed verification")
            }
        }
        
        purchasedCourses = purchased
        hasPurchased = hasValidPurchase
    }
    
    // MARK: - Restore Purchases
    
    /// 恢复购买 - 同步App Store并更新状态
    @MainActor
    func restorePurchases() async throws {
        isLoading = true
        loadError = nil
        
        do {
            // 同步App Store交易记录
            try await AppStore.sync()
            
            // 如果商品列表为空，尝试重新加载
            if storeProducts.isEmpty {
                await requestProducts()
            }
            
            // 更新购买状态
            await checkEntitlementsDirectly()
            await updateCustomerProductStatus()
            
        } catch {
            loadError = "恢复购买失败，请稍后重试"
            throw error
        }
        
        isLoading = false
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
        // 先检查已购买列表
        if purchasedCourses.contains(where: { $0.id == product.id }) {
            return true
        }
        
        // 直接查询交易记录
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == product.id {
                if let expirationDate = transaction.expirationDate {
                    return expirationDate > Date()
                }
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Retry Loading
    
    /// 重试加载商品
    @MainActor
    func retryLoadProducts() async {
        loadError = nil
        await requestProducts()
    }
}
