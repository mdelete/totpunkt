//
//  ScannerView.swift
//  Totpunkt
//
//  Created by Marc Delling on 21.07.24.
//

import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {

    @Binding var accounts: [TOTPAccount]
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        
        @Binding var accounts: [TOTPAccount]

        init(accounts: Binding<[TOTPAccount]>) {
            _accounts = accounts
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = allItems.first else { return }
            accounts.removeAll()
            switch item {
            case .barcode(let recognizedCode):
                if let str = recognizedCode.payloadStringValue {
                    if let acc = try? URL(string: str)?.decodeOTP() {
                        accounts.append(acc)
                        dataScanner.dismiss(animated: true)
                    }
                    else if let migratedAccounts = try? URL(string: str)?.decodeOTPMigration() {
                        accounts = migratedAccounts
                        dataScanner.dismiss(animated: true)
                    }
                }
            case .text(let recognizedText):
                if let account = try? URL(string: recognizedText.transcript.removingCharacters(in: .whitespacesAndNewlines))?.decodeOTP() {
                    accounts.append(account)
                    dataScanner.dismiss(animated: true)
                }
            default:
                break
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(accounts: $accounts)
    }
    
    func makeUIViewController(context: Context) -> DataScannerViewController {

        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr]), .text()],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        viewController.delegate = context.coordinator

        return viewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
    }
    
    typealias UIViewControllerType = DataScannerViewController
}

extension String {
    func removingCharacters(in ignoredChars: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !ignoredChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }
}
