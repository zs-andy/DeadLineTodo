//
//  StoreView.swift
//  DeadLineTodo
//
//  In-app purchase store view
//

import SwiftUI
import StoreKit
import SwiftData

struct StoreView: View {
    
    @Binding var isPresented: Bool
    @Query private var userSettings: [UserSetting]
    @EnvironmentObject private var store: StoreKitManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showThanks = false
    @State private var emptyProduct = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 关闭按钮
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.blackGray.opacity(0.3))
                }
                .padding(.top, 12)
                .padding(.trailing, 16)
            }
            
            VStack(spacing: 16) {
                // 标题和副标题
                headerSection
                
                // 产品卡片
                productCard
                
                // 功能列表
                featureList
                
                Spacer()
                
                // 恢复购买和链接
                footerLinks
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.grayWhite1)
        .onChange(of: store.purchasedCourses) { _, _ in
            Task { await checkPurchaseStatus() }
        }
        .alert(Text(LocalizedStringKey("提醒")), isPresented: $emptyProduct) {
            Button(LocalizedStringKey("确定")) { emptyProduct = false }
        } message: {
            Text(LocalizedStringKey("商品未加载"))
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.creamPink)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey("高级功能"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.myBlack)
                
                Text(LocalizedStringKey("解锁所有高级特性"))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.blackGray)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Product Card
    
    private var productCard: some View {
        VStack(spacing: 16) {
            if store.storeProducts.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(40)
            } else if store.hasPurchased {
                purchasedCard
            } else {
                ForEach(store.storeProducts) { product in
                    purchaseButton(product: product)
                }
            }
        }
    }
    
    private var purchasedCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.green2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey("已获得DeadLineTodo高级功能"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.myBlack)
                
                Text(LocalizedStringKey("永久享受所有高级功能"))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.blackGray)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.grayWhite2.opacity(0.6))
        )
    }
    
    private func purchaseButton(product: Product) -> some View {
        Button {
            Task {
                do {
                    try await store.purchase(product)
                } catch {
                    print("购买产品时出现错误：\(error)")
                }
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(product.displayName))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.myBlack)
                        .multilineTextAlignment(.leading)
                    
                    Text(productDescription(for: product))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.blackGray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.creamPink)
                    )
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.grayWhite2.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.creamPink.opacity(0.3), lineWidth: 2)
            )
        }
    }
    
    /// 根据产品类型返回描述文字
    private func productDescription(for product: Product) -> LocalizedStringKey {
        switch product.type {
        case .nonConsumable:
            return LocalizedStringKey("一次购买，永久使用")
        case .autoRenewable:
            if let subscription = product.subscription {
                let unit = subscription.subscriptionPeriod.unit
                switch unit {
                case .day:
                    return LocalizedStringKey("每日订阅，自动续费")
                case .week:
                    return LocalizedStringKey("每周订阅，自动续费")
                case .month:
                    return LocalizedStringKey("每月订阅，自动续费")
                case .year:
                    return LocalizedStringKey("每年订阅，自动续费")
                default:
                    return LocalizedStringKey("订阅，自动续费")
                }
            }
            return LocalizedStringKey("订阅，自动续费")
        case .consumable:
            return LocalizedStringKey("消耗型购买")
        case .nonRenewable:
            return LocalizedStringKey("非续订订阅")
        default:
            return LocalizedStringKey("购买")
        }
    }

    // MARK: - Feature List
    
    private var featureList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("包含功能"))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.myBlack)
            
            featureRow(icon: "bell.badge.fill", text: LocalizedStringKey("提醒事项同步"))
            featureRow(icon: "calendar.badge.clock", text: LocalizedStringKey("日历同步"))
            featureRow(icon: "chart.bar.fill", text: LocalizedStringKey("效率可视化统计"))
            featureRow(icon: "repeat.circle.fill", text: LocalizedStringKey("重复任务"))
            featureRow(icon: "sparkles", text: LocalizedStringKey("享受后续所有更新功能"))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.grayWhite2.opacity(0.6))
        )
    }
    
    private func featureRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.blackBlue2)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.myBlack)
            
            Spacer()
        }
    }
    
    // MARK: - Footer Links
    
    private var footerLinks: some View {
        VStack(spacing: 12) {
            Button {
                Task { try? await AppStore.sync() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 12))
                    Text(LocalizedStringKey("恢复购买"))
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.blackBlue2)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.grayWhite2.opacity(0.6))
                )
            }
            
            HStack(spacing: 16) {
                Link("EULA", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .foregroundStyle(Color.blackGray)
                    .font(.system(size: 10))
                
                Text("•")
                    .foregroundStyle(Color.blackGray)
                    .font(.system(size: 10))
                
                Link(LocalizedStringKey("隐私政策"), destination: URL(string: "https://privacy.1ts.fun/product/240215ZQ15RbX8mfZIgP")!)
                    .foregroundStyle(Color.blackGray)
                    .font(.system(size: 10))
            }
        }
    }
    
    // MARK: - Helper
    
    private func checkPurchaseStatus() async {
        var hasPurchase = false
        
        for (index, product) in store.storeProducts.enumerated() where index < 4 {
            if (try? await store.isPurchased(product)) == true {
                hasPurchase = true
                break
            }
        }
        
        store.hasPurchased = hasPurchase
        
        guard !userSettings.isEmpty else { return }
        
        if store.hasPurchased {
            userSettings[0].hasPurchased = true
        } else {
            userSettings[0].reminder = false
            userSettings[0].calendar = false
            userSettings[0].hasPurchased = false
        }
    }
}
