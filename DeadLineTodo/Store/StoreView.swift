//
//  StoreView.swift
//  DeadLineTodo
//
//  Created by Andy on 2024/3/27.
//

import SwiftUI
import StoreKit
import SwiftData

struct StoreView: View {

    @Binding var isStorePresent: Bool
    @State var showThanks: Bool = false
    @State var emptyProduct: Bool = false
    
    @Query var userSetting: [UserSetting]
    
    @EnvironmentObject var store: StoreKitManager
    
    var body: some View {
        VStack{
            HStack{
                Text("高级功能")
                    .font(.system(size: 30))
                    .bold()
                    .padding(20)
                    .foregroundStyle(Color.myBlack)
                Spacer()
            }
            ScrollView{
                if store.storeProducts.count != 0{
                    if store.hasPurchased{
                         HStack{
                            Text("已获得DeadLineTodo高级功能")
                                .bold()
                                .foregroundStyle(Color.myBlack)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
//                        HStack{
//                            Text("永久享受数据可视化统计、提醒事项同步和重复任务功能")
//                                .font(.system(size: 10))
//                                .foregroundStyle(Color.blackGray)
//                                .multilineTextAlignment(.leading)
//                            Spacer()
//                        }
//                        .padding(.horizontal, 20)
//                        .padding(.top, -3)
                    }else{
                        VStack{
                            ForEach(store.storeProducts) { prodcut in
                                Button (action:{
                                    if store.storeProducts.isEmpty {
                                        emptyProduct = true
                                    } else {
                                        Task{
                                            do {
                                                try await store.purchase(prodcut)
                                            } catch {
                                                print("购买产品时出现错误：\(error)")
                                            }
                                        }
                                    }
                                }){
                                    VStack{
                                        ZStack{
                                            HStack{
                                                Text(prodcut.displayName)
                                                    .bold()
                                                    .foregroundStyle(Color.blackBlue1)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                                Text(prodcut.displayPrice)
                                                    .bold()
                                                    .foregroundStyle(Color.myBlack)
                                                    .padding(.horizontal, 10)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 10)
    //                                    HStack{
    //                                        Text("即可永久解锁数据可视化统计、提醒事项同步和重复任务功能")
    //                                            .font(.system(size: 10))
    //                                            .foregroundStyle(Color.blackGray)
    //                                            .multilineTextAlignment(.leading)
    //                                        Spacer()
    //                                    }
    //                                    .padding(.horizontal, 20)
    //                                    .padding(.top, -3)
                                    }
                                }
                            }
    //                        .task {
    //                            Task{
    //                                do {
    //                                    print("load")
    //                                    try await store.retrieveProducts()
    //                                } catch {
    //                                    print(error)
    //                                }
    //                            }
    //                        }
                        }
                    }
                }else{
                    ProgressView()
                       .progressViewStyle(CircularProgressViewStyle())
                       .padding()
                }
                HStack{
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.green)
                        .padding(.leading, 20)
                        .padding(.top)
                    Text("提醒事项同步")
                        .bold()
                        .foregroundStyle(Color.myBlack)
                        .padding(.top)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                HStack{
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.green)
                        .padding(.leading, 20)
                        .padding(.top)
                    Text("日历同步")
                        .bold()
                        .foregroundStyle(Color.myBlack)
                        .padding(.top)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                HStack{
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.green)
                        .padding(.leading, 20)
                        .padding(.top)
                    Text("效率可视化统计")
                        .bold()
                        .foregroundStyle(Color.myBlack)
                        .padding(.top)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                HStack{
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.green)
                        .padding(.leading, 20)
                        .padding(.top)
                        .multilineTextAlignment(.leading)
                    Text("重复任务")
                        .bold()
                        .foregroundStyle(Color.myBlack)
                        .padding(.top)
                    Spacer()
                }
                HStack{
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.green)
                        .padding(.leading, 20)
                        .padding(.top)
                        .multilineTextAlignment(.leading)
                    Text("享受后续所有更新功能")
                        .bold()
                        .foregroundStyle(Color.myBlack)
                        .padding(.top)
                    Spacer()
                }
                Button(action:{
                    Task {
                        do {
                            try? await AppStore.sync()
                        } catch {
                            print(error)
                        }
                    }
                }){
                    Text("恢复购买")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.blackBlue2)
                }
                .padding()
                Link("EULA", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                .foregroundStyle(Color.blackBlue2)
                                .font(.system(size: 10))
                Link("隐私政策", destination: URL(string: "https://privacy.1ts.fun/product/240215ZQ15RbX8mfZIgP")!)
                                .foregroundStyle(Color.blackBlue2)
                                .font(.system(size: 10))
                                .padding(.top)
            }
            Spacer()
            HStack{
                ZStack{
                    Button(action: {
                        isStorePresent = false
                    }){
                        ZStack{
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.creamBlue)
                                .frame(width: 80, height: 50)
                            Text("取消")
                                .bold()
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.vertical)
                }
                .frame(maxWidth: .infinity)
                ZStack{
                    Button(action: {
//                        if store.storeProducts.isEmpty {
//                            emptyProduct = true
//                        } else {
//                            Task{
//                                do {
//                                    try await store.purchase(store.storeProducts[0])
//                                } catch {
//                                    print("购买产品时出现错误：\(error)")
//                                }
//                            }
//                        }
                        isStorePresent = false
//
//                        Task{
//                            try await store.purchase(store.storeProducts[0])
//                            isStorePresent = false
//                        }
                    }){
                        ZStack{
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.blackBlue2)
                                .frame(width: 80, height: 50)
                            Text("确定")
                                .bold()
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.vertical)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.grayWhite1)
        .alert(isPresented: $emptyProduct) {
            Alert(title: Text("提醒"), message: Text("商品未加载"), dismissButton: .default(Text("确定")){
                emptyProduct = false
            })
        }
    }
}
//
//struct Product {
//    var name: String
//    var price: String
//}
