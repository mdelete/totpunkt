//
//  URL+DecodeOTP.swift
//  Totpunkt
//
//  Created by Marc Delling on 21.07.24.
//

import Foundation
import SwiftOTP

extension URL {
    
    enum DecodeError: Error {
        case invalidScheme
        case invalidType
        case invalidIssuerName
        case invalidIssuer
        case invalidName
        case invalidParams
        case invalidHash
        case invalidDigits
        case invalidSecret
        case invalidPeriod
        case notSupported
    }
    
    func decodeOTP() throws -> TOTPAccount {
        
        var digits = 6
        var period = 30
        var name : String!
        var issuer : String!
        var secret : Data!
        var algorithm = OTPAlgorithm.sha1
        
        guard self.scheme == "otpauth" else { throw DecodeError.invalidScheme }
        guard self.host == "totp" else { throw DecodeError.invalidType } // FIXME: hotp not supported yet
        
        let pathComponents = self.path.components(separatedBy: ":")
        if pathComponents.count != 2 {
            throw DecodeError.invalidIssuerName
        }
        
        issuer = String(pathComponents[0].dropFirst()) // remove leading '/'
        issuer = issuer.removingPercentEncoding ?? issuer
        
        if issuer.count < 1 {
            throw DecodeError.invalidIssuer
        }
        
        name = pathComponents[1]
        name = name.removingPercentEncoding ?? name
        
        if name.count < 1 {
            throw DecodeError.invalidName
        }
        
        if let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems {
            try queryItems.forEach { item in
                switch item.name {
                case "secret":
                    if let val = item.value, let val = base32DecodeToData(val) {
                        secret = val
                    } else {
                        throw DecodeError.invalidSecret
                    }
                case "digits":
                    switch item.value {
                        case "6": digits = 6
                        case "7": digits = 7
                        case "8": digits = 8
                        default: throw DecodeError.invalidDigits
                    }
                case "issuer":
                    if let val = item.value, val != issuer {
                        throw DecodeError.invalidIssuer
                    }
                case "algorithm":
                    switch item.value {
                        case "SHA1": algorithm = OTPAlgorithm.sha1
                        case "SHA256": algorithm = OTPAlgorithm.sha256
                        case "SHA512": algorithm = OTPAlgorithm.sha512
                        default: throw DecodeError.invalidHash
                    }
                case "period": // totp only
                    switch item.value {
                    case "15": period = 15
                    case "30": period = 30
                    case "60": period = 60
                    default: throw DecodeError.invalidPeriod
                    }
                case "counter": throw DecodeError.notSupported // htop only, parse Int from item.value
                default: throw DecodeError.invalidParams
                }
            }
        }
        
        if secret == nil {
            throw DecodeError.invalidSecret
        }

        return try TOTPAccount(name: name, issuer: issuer, digits: digits, period: period, algorithm: algorithm, secret: secret)
    }
    
}
