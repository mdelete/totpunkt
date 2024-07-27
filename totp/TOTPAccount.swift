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
    
    enum DecoderError: Error {
        case failedTOTP
    }
    
    let name: String
    let issuer: String
    let algorithm: OTPAlgorithm
    let digits: Int
    let period: Int

    private let totp: TOTP
    private var lastGeneration: Int64 = 0
    private(set) var otpString: String
   
    private enum CodingKeys: String, CodingKey {
        case name, issuer, algorithm, digits, period
    }
    
    init(name: String, issuer: String, digits: Int, period: Int, algorithm: OTPAlgorithm, secret: Data) throws {
        self.name = name
        self.issuer = issuer
        self.digits = digits
        self.period = period
        self.algorithm = algorithm
        guard let totp = TOTP(secret: secret, digits: digits, timeInterval: period, algorithm: algorithm) else { throw DecoderError.failedTOTP }
        self.totp = totp
        self.otpString = String(repeating: "-", count: digits)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.issuer = try container.decode(String.self, forKey: .issuer)
        self.digits = try container.decode(Int.self, forKey: .digits)
        self.period = try container.decode(Int.self, forKey: .period)
        self.algorithm = try container.decode(OTPAlgorithm.self, forKey: .algorithm)
        let secret = try KeychainHelper.instance.readSecret(service: issuer, account: name)
        guard let totp = TOTP(secret: secret, digits: digits, timeInterval: period, algorithm: algorithm) else { throw DecoderError.failedTOTP }
        self.totp = totp
        self.otpString = String(repeating: "-", count: digits)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(issuer, forKey: .issuer)
        try container.encode(digits, forKey: .digits)
        try container.encode(period, forKey: .period)
        try container.encode(algorithm, forKey: .algorithm)
        try KeychainHelper.instance.add(secret: totp.secret, service: issuer, account: name)
    }
    
    func deleteSecret() {
        do {
            try KeychainHelper.instance.deleteSecret(service: issuer, account: name)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func remainingTime(from date: Date) -> String {

        let currentGeneration = Int64(floor(Double(Int64(floor(date.timeIntervalSince1970))) / Double(period)))
        let currentGenerationRemainder = Int(floor(Double(Int64(floor(date.timeIntervalSince1970))).truncatingRemainder(dividingBy: Double(period))))

        if currentGeneration > lastGeneration {
            otpString = totp.generate(time: date) ?? String(repeating: "-", count: digits)
            lastGeneration = currentGeneration
        }

        return String((period - currentGenerationRemainder))
    }
}
