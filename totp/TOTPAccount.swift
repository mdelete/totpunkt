//
//  Account.swift
//  Totpunkt
//
//  Created by Marc Delling on 21.07.24.
//

import Foundation
import SwiftOTP

final class TOTPAccount: Codable, Identifiable, Equatable {
    
    static func == (lhs: TOTPAccount, rhs: TOTPAccount) -> Bool {
        lhs.issuer == rhs.issuer && lhs.name == rhs.name
    }
    
    var id: String {
        issuer + name
    }
    
    var description: String {
        "TOTPAccount: \(name), \(issuer), \(algorithm), \(digits), \(period)"
    }
    
    let name: String
    let issuer: String
    let algorithm: OTPAlgorithm
    let digits: Int
    let period: Int

    private let totp: TOTP!
    private var lastGeneration: Int64 = 0
    private var counter: Int!
    private(set) var otpString: String!
   
    private enum CodingKeys: String, CodingKey {
        case name, issuer, algorithm, digits, period
    }
    
    init(name: String, issuer: String, digits: Int, period: Int, algorithm: OTPAlgorithm, secret: Data) {
        self.name = name
        self.issuer = issuer
        self.digits = digits
        self.period = period
        self.algorithm = algorithm
        self.totp = TOTP(secret: secret, digits: digits, timeInterval: period, algorithm: algorithm)
        self.otpString = String(repeating: "-", count: digits)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.issuer = try container.decode(String.self, forKey: .issuer)
        self.digits = try container.decode(Int.self, forKey: .digits)
        self.period = try container.decode(Int.self, forKey: .period)
        self.algorithm = try container.decode(OTPAlgorithm.self, forKey: .algorithm)
        let secret = try KeychainHelper.readSecret(service: issuer, account: name)
        self.totp = TOTP(secret: secret, digits: digits, timeInterval: period, algorithm: algorithm)
        self.otpString = String(repeating: "-", count: digits)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(issuer, forKey: .issuer)
        try container.encode(digits, forKey: .digits)
        try container.encode(period, forKey: .period)
        try container.encode(algorithm, forKey: .algorithm)
        do {
            try KeychainHelper.save(secret: totp.secret, service: issuer, account: name)
        } catch KeychainHelper.KeychainError.duplicateItem {
            try KeychainHelper.update(secret: totp.secret, service: issuer, account: name)
        }
    }
    
    func deleteSecret() {
        do {
            try KeychainHelper.deleteSecret(service: issuer, account: name)
        } catch let err {
            print(err.localizedDescription)
        }
    }
    
    func remainingTime(from date: Date) -> String {
        let currentGeneration = Int64(floor(Double(Int64(floor(date.timeIntervalSince1970))) / Double(period)))
        if currentGeneration > lastGeneration {
            counter = period
            otpString = totp.generate(time: date) ?? String(repeating: "-", count: digits)
            if lastGeneration == 0 {
                counter -= Int(Int64(floor(date.timeIntervalSince1970)) % Int64(period)) - 1
                //counter -= Int(floor(Double(Int64(floor(date.timeIntervalSince1970))).truncatingRemainder(dividingBy: Double(period)))) - 1
            }
            lastGeneration = currentGeneration
        } else {
            counter -= 1
        }
        return String(counter)
    }
}
