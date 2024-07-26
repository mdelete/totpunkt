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
    
    var accounts: [TOTPAccount] = []
    
    func filter(matching: String) async {
        // FIXME: filter account with search field string
        accounts = FileHelper.load()
    }
    
    func add(_ account: TOTPAccount?) {
        if let account = account, accounts.firstIndex(where: {$0.id == account.id}) == nil {
            accounts.append(account)
            save()
        }
    }
    
    func save() {
        FileHelper.store(accounts: accounts)
    }
    
    fileprivate func mock() -> AccountsViewModel {
        
        let account1 = try! URL(string:"otpauth://totp/The%20Issuer:my%40email.com?secret=ABCDEFGHIJKLMNOP")!.decodeOTP()
        add(account1)
        
        let account2 = try! URL(string:"otpauth://totp/The%20Other%20Issuer:my%40email.com?secret=QRSDEFGHIJKLMNOP&digits=8&period=15")!.decodeOTP()
        add(account2)
        
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
    @State private var account: TOTPAccount?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.accounts) { item in
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                        Text(item.issuer)
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
                            Button (action: { UIPasteboard.general.string = item.otpString }) {
                                Label("Copy", systemImage: "arrow.up.doc.on.clipboard")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .onMove { indexSet, offset in
                    viewModel.accounts.move(fromOffsets: indexSet, toOffset: offset)
                    viewModel.save()
                }
                .onDelete { indexSet in
                    viewModel.accounts.remove(atOffsets: indexSet)
                    viewModel.save()
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
            .sheet(isPresented: $showScanner, onDismiss: { viewModel.add(account) },
                   content: { ScannerView(account: $account) }
            )
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
