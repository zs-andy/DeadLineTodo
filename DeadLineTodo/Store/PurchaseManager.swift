//
//  PurchaseManager.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/3/28.
//

//@MainActor
//class PurchaseManager: ObservableObject {
//    
//    @Published private(set) var products: [Product] = []
//    private(set) var purchasedProductIDs = Set<String>()
//    private var productsLoaded = false
//    private var updates: Task<Void, Never>? = nil
//
//    init() {
//        updates = observeTransactionUpdates()
//    }
//    
//    deinit {
//        updates?.cancel()
//    }
//    
//    var hasUnlockedPro: Bool {
//        return !self.purchasedProductIDs.isEmpty
//    }
//    
//    private func observeTransactionUpdates() -> Task<Void, Never> {
//        Task(priority: .background) { [unowned self] in
//            for await verificationResult in Transaction.updates {
//                // Using verificationResult directly would be better
//                // but this way works for this tutorial
//                await self.updatePurchasedProducts()
//            }
//        }
//    }
//    
//    func updatePurchasedProducts() async {
//        for await result in Transaction.currentEntitlements {
//            guard case .verified(let transaction) = result else {
//                continue
//            }
//
//            if transaction.revocationDate == nil {
//                self.purchasedProductIDs.insert(transaction.productID)
//            } else {
//                self.purchasedProductIDs.remove(transaction.productID)
//            }
//        }
//    }
//
//    func loadProducts() async throws {
//        let productIds = ["andy.deadlinetodo.premium"]
//        guard !self.productsLoaded else { return }
//        self.products = try await Product.products(for: productIds)
//        self.productsLoaded = true
//    }
//
//    func purchase(_ product: Product) async throws {
//        let result = try await product.purchase()
//
//        switch result {
//        case let .success(.verified(transaction)):
//            // Successful purhcase
//            await transaction.finish()
//            await self.updatePurchasedProducts()
//        case let .success(.unverified(_, error)):
//            // Successful purchase but transaction/receipt can't be verified
//            // Could be a jailbroken phone
//            break
//        case .pending:
//            // Transaction waiting on SCA (Strong Customer Authentication) or
//            // approval from Ask to Buy
//            break
//        case .userCancelled:
//            // ^^^
//            break
//        @unknown default:
//            break
//        }
//    }
//}

//typealias PurchaseResult = Product.PurchaseResult
//typealias TransactionListener = Task<Void, Error>
//
//@MainActor
//final class DeadLineTodoStore: ObservableObject{
//    @Published private(set) var items = [Product]()
//    @Published private(set) var action: ProductAction? {
//        didSet {
//            switch action {
//            case .failed:
//                hasError = true
//            default:
//                hasError = false
//            }
//        }
//    }
//    
//    @Published var hasError = false
//    
//    var error: ProductError? {
//        switch action {
//        case .failed(let err):
//            return err
//        default:
//            return nil
//        }
//    }
//    
//    private var transactionListener: TransactionListener?
//    
//    init(){
//        
//        transactionListener = configureTransactionListener()
//        
//        Task { [weak self] in
//            await self?.retrieveProducts()
//        }
//    }
//    
//    deinit {
//        transactionListener?.cancel()
//    }
//    
//    func purchase(_ item: Product) async {
//        do {
//            let result = try await item.purchase()
//            try await handlePurchase(from: result)
//        } catch {
//            action = .failed(.system(error))
//            print(error)
//        }
//    }
//    
//    func reset(){
//        action = nil
//    }
//}
//
//private extension DeadLineTodoStore {
//    
//    func configureTransactionListener() -> TransactionListener {
//        Task.detached(priority: .background) { @MainActor [weak self] in
//            do {
//                for await result in Transaction.updates {
//                    let transaction = try self?.checkVerified(result)
//                    self?.action = .successful
//                    
//                    await transaction?.finish()
//                }
//            } catch {
//                self?.action = .failed(.system(error))
//                print(error)
//            }
//        }
//    }
//    
//    func retrieveProducts() async {
//        do {
//            let products = try await Product.products(for: ["andy.deadlinetodo.premium"])
//            items = products
//        } catch {
//            action = .failed(.system(error))
//            print(error)
//        }
//    }
//    
//    func handlePurchase(from result: PurchaseResult) async throws {
//        switch result {
//            
//        case .success(let verification):
//            print("success")
//            let transaction = try checkVerified(verification)
//            action = .successful   
//            await transaction.finish()
//        case .pending:
//            print("need more action")
//            
//        case .userCancelled:
//            print("user cancelled")
//            
//        default:
//            break
//
//        }
//    }
//    
//    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
//        switch result {
//        case .unverified:
//            print("Verification failed")
//            throw ProductError.failedVerification
//            
//        case .verified(let safe):
//            return safe
//        }
//    }
//}
//
//enum ProductError: LocalizedError {
//    case failedVerification
//    case system(Error)
//    
//    var errorDescription: String? {
//        switch self{
//        case .failedVerification:
//            return "User transaction verification failed"
//        case .system(let err):
//            return err.localizedDescription
//        }
//    }
//}
//
//enum ProductAction {
//    case successful
//    case failed(ProductError)
//    
//    static func == (lhs: ProductAction, rhs: ProductAction) -> Bool {
//        switch (lhs, rhs) {
//        case (.successful, .successful):
//            return true
//        case (let .failed(lhsErr), let .failed(rhsErr)):
//            return lhsErr.localizedDescription == rhsErr.localizedDescription
//        default:
//            return false
//        }
//    }
//}


import Foundation
import StoreKit

public enum StoreError: Error {
    case failedVerification
}

@MainActor
class StoreKitManager: ObservableObject {
    // if there are multiple product types - create multiple variable for each .consumable, .nonconsumable, .autoRenewable, .nonRenewable.
    @Published var storeProducts: [Product] = []
    @Published var purchasedCourses : [Product] = []
    @Published var hasPurchased: Bool = false
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    //maintain a plist of products
    private let productDict: [String : String]
    init() {
        //check the path for the plist
        if let plistPath = Bundle.main.path(forResource: "PropertyList", ofType: "plist"),
           //get the list of products
           let plist = FileManager.default.contents(atPath: plistPath) {
            productDict = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String : String]) ?? [:]
        } else {
            productDict = [:]
        }
        
        //create async operation
        Task {
            await requestProducts()
            
            //deliver the products that the customer purchased
            await updateCustomerProductStatus()
        }
        
        //Start a transaction listener as close to the app launch as possible so you don't miss any transaction
        updateListenerTask = listenForTransactions()

    }
    
    //denit transaction listener on exit or app close
    deinit {
        updateListenerTask?.cancel()
    }
    
    //listen for transactions - start this early in the app
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //iterate through any transactions that don't come from a direct call to 'purchase()'
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    //the transaction is verified, deliver the content to the user
                    await self.updateCustomerProductStatus()
                    
                    //Always finish a transaction
                    await transaction.finish()
                } catch {
                    //storekit has a transaction that fails verification, don't delvier content to the user
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    // request the products in the background
    @MainActor
    func requestProducts() async {
        do {
            //using the Product static method products to retrieve the list of products
            storeProducts = try await Product.products(for: productDict.values)
            // iterate the "type" if there are multiple product types.
        } catch {
            print("Failed - error retrieving products \(error)")
        }
    }
    
    
    //Generics - check the verificationResults
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //check if JWS passes the StoreKit verification
        switch result {
        case .unverified:
            //failed verificaiton
            throw StoreError.failedVerification
        case .verified(let signedType):
            //the result is verified, return the unwrapped value
            return signedType
        }
    }
    
    // update the customers products
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedCourses: [Product] = []
        
        //iterate through all the user's purchased products
        for await result in Transaction.currentEntitlements {
            do {
                //again check if transaction is verified
                let transaction = try checkVerified(result)
                // since we only have one type of producttype - .nonconsumables -- check if any storeProducts matches the transaction.productID then add to the purchasedCourses
                if let course = storeProducts.first(where: { $0.id == transaction.productID}) {
                    purchasedCourses.append(course)
                }
                
            } catch {
                //storekit has a transaction that fails verification, don't delvier content to the user
                print("Transaction failed verification")
            }
            
            //finally assign the purchased products
            self.purchasedCourses = purchasedCourses
        }
    }
    
    // call the product purchase and returns an optional transaction
    func purchase(_ product: Product) async throws {
        //make a purchase request - optional parameters available
        let result = try await product.purchase()
        // check the results
        switch result {
        case .success(let verificationResult):
            //Transaction will be verified for automatically using JWT(jwsRepresentation) - we can check the result
            let transaction = try checkVerified(verificationResult)
            //the transaction is verified, deliver the content to the user
            await updateCustomerProductStatus()
            //always finish a transaction - performance
            await transaction.finish()
        case .pending:
            print("need more action")
        case .userCancelled:
            print("user cancelled")
        default:
            break

        }
    }
    
    //    func handlePurchase(from result: PurchaseResult) async throws {
    //        switch result {
    //
    //        case .success(let verification):
    //            print("success")
    //            let transaction = try checkVerified(verification)
    //            action = .successful
    //            await transaction.finish()
    //        case .pending:
    //            print("need more action")
    //
    //        case .userCancelled:
    //            print("user cancelled")
    //
    //        default:
    //            break
    //
    //        }
    //    }
    
    //check if product has already been purchased
    func isPurchased(_ product: Product) async throws -> Bool {
        //as we only have one product type grouping .nonconsumable - we check if it belongs to the purchasedCourses which ran init()
        return purchasedCourses.contains(product)
    }
    
    
}
