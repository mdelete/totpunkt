//
//  FileHelper.swift
//  Totpunkt
//
//  Created by Marc Delling on 21.07.24.
//

import Foundation

class FileHelper {
    
    private static let accountFile = "accounts.json"
    
    static func load() -> [TOTPAccount] {

        var accounts = [TOTPAccount]()
        
        let docsBaseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let accountPlistURL = docsBaseURL.appendingPathComponent(FileHelper.accountFile)
        let jsonDecoder = JSONDecoder()
        
        do {
            let data = try Data(contentsOf: accountPlistURL)
            accounts = try jsonDecoder.decode([TOTPAccount].self, from: data)
        } catch let error {
            print(error.localizedDescription) // FIXME: handle in UI
        }
        
        return accounts
    }
    
    static func store(accounts: [TOTPAccount]) {

        let docsBaseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let accountPlistURL = docsBaseURL.appendingPathComponent(FileHelper.accountFile)
        let jsonEncoder = JSONEncoder()

        do  {
            let data = try jsonEncoder.encode(accounts)
            try data.write(to: accountPlistURL, options: .atomic)
        } catch let error {
            print(error.localizedDescription) // FIXME: handle in UI
        }
    }
    
}
