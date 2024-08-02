//
//  ContentView.swift
//  Totpunkt
//
//  Created by Marc Delling on 21.07.24.
//

import SwiftUI
import Observation

@Observable
final class AccountsViewModel {
    
    private(set) var accounts: [TOTPAccount] = []
    
    func filter(matching: String) async {
        // FIXME: filter account with search field string
        accounts = FileHelper.load()
    }
    
    func add(_ addedAccounts: [TOTPAccount]) {
        addedAccounts.forEach { newAccount in
            if accounts.firstIndex(where: {$0.id == newAccount.id}) == nil {
                accounts.append(newAccount)
                FileHelper.store(accounts: accounts)
            }
        }
    }
    
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        self.accounts.move(fromOffsets: source, toOffset: destination)
        FileHelper.store(accounts: accounts)
    }
    
    func remove(atOffsets indexSet: IndexSet) {
        indexSet.forEach {
            self.accounts[$0].deleteSecret()
        }
        self.accounts.remove(atOffsets: indexSet)
        FileHelper.store(accounts: accounts)
    }
    
    fileprivate func mock() -> AccountsViewModel {
        
        let account1 = try! URL(string:"otpauth://totp/The%20Issuer:my%40email.com?secret=ABCDEFGHIJKLMNOP")!.decodeOTP()
        add([account1])
        
        let account2 = try! URL(string:"otpauth://totp/The%20Other%20Issuer:my%40email.com?secret=QRSDEFGHIJKLMNOP&digits=8&period=15")!.decodeOTP()
        add([account2])
        
        return self
    }
}

struct ContentView: View {
    
    let viewModel : AccountsViewModel
    let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    
    @State private var editMode : EditMode = .inactive
    @State private var isEditing = false
    
    @State private var filter = ""
    @State private var now = Date()
    @State private var showScanner: Bool = false
    @State private var importedAccounts = [TOTPAccount]()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.accounts) { item in
                    VStack(alignment: .leading) {
                        Text(item.friendlyIssuer)
                            .font(.headline)
                        Text(item.friendlyName)
                            .foregroundColor(.secondary)
                        HStack(alignment: .center) {
                            Text(item.remainingTime(from: now))
                                .font(.caption)
                                .padding(0.2)
                                .onReceive(timer) { _ in
                                    now = Date()
                                }
                            Spacer()
                            Text(item.otpString)
                                .padding(0.2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .swipeActions {
                        if !isEditing {
                            Button (action: {
                                UIPasteboard.general.setItemProviders([NSItemProvider(object: item.otpString as NSString)], localOnly: false, expirationDate: now + TimeInterval(item.period))
                            }) {
                                Label("Copy", systemImage: "arrow.up.doc.on.clipboard")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .onMove { indexSet, offset in
                    viewModel.move(fromOffsets: indexSet, toOffset: offset)
                }
                .onDelete { indexSet in
                    viewModel.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("Totpunkt")
            .environment(\.editMode, $editMode)
            .onChange(of: isEditing, { _, isEditing in
                editMode = isEditing ? .active : .inactive
            })
            .animation(.default, value: editMode)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        if isEditing {
                            Text("Done")
                        } else {
                            Text("Edit")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showScanner.toggle()
                    }) {
                        Label("Scanner", systemImage: "qrcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showScanner, onDismiss: {
                viewModel.add(importedAccounts)
            }, content: {
                ScannerView(accounts: $importedAccounts)
            })
            .onChange(of: filter, { oldValue, newValue in
                Task {
                    await viewModel.filter(matching: filter)
                }
            })
        }
        .onAppear {
            Task {
                await viewModel.filter(matching: filter)
            }
        }
    }
}

#Preview {
    ContentView(viewModel: AccountsViewModel().mock()).preferredColorScheme(.dark)
}
