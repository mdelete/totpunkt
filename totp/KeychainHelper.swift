//
//  KeychainHelper.swift
//  Totpunkt
//
//  Created by Marc Delling on 06.11.22.
//

import Foundation
import LocalAuthentication

class KeychainHelper {

    static let instance = KeychainHelper()
    
    private let context : LAContext
    
    init() {
        context = LAContext()
        context.localizedReason = "Access your generators on the keychain"
    }
    
    struct KeychainError: Error {
        var status: OSStatus

        var localizedDescription: String {
            return SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error."
        }
    }
    
    // FIXME: URGENT - SECURITY - we need to invalidate the context when in background
    func invalidate() {
        context.invalidate()
    }
    
    func deleteSecret(service: String, account: String) throws {

        let query: [String: Any] = [
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecClass as String: kSecClassGenericPassword,
            //kSecAttrSynchronizable as String: true
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
    }
    
    func readSecret(service: String, account: String) throws -> Data {

        let query: [String: Any] = [
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecClass as String: kSecClassGenericPassword,
            //kSecAttrSynchronizable as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        
        var itemCopy: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)
        
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
        
        guard let secret = itemCopy as? Data else {
            throw KeychainError(status: errSecInvalidValue)
        }
        
        return secret
    }
    
    func add(secret: Data, service: String, account: String) throws {
        
        let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .userPresence, nil)
        
        let query: [String: Any] = [
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecClass as String: kSecClassGenericPassword,
            //kSecAttrSynchronizable as String: true,
            kSecValueData as String: secret,
            kSecAttrAccessControl as String: access as Any,
            kSecUseAuthenticationContext as String: context
        ]
        
        var status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // FIXME: handle duplicate items here by silently deleting an re-adding is a bit dirty
            status = SecItemDelete(query as CFDictionary)
            print("errSecDuplicateItem: delete: \(status == errSecSuccess) for \(service) - \(account)")
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
    }
    
}
