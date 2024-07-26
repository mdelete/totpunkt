//
//  ScannerView.swift
//  Totpunkt
//
//  Created by Marc Delling on 21.07.24.
//

import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {

    @Binding var account: TOTPAccount?
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        
        @Binding var account: TOTPAccount?

        init(account: Binding<TOTPAccount?>) {
            _account = account
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = allItems.first else { return }
            switch item {
            case .barcode(let recognizedCode):
                if let str = recognizedCode.payloadStringValue, let acc = try? URL(string: str)?.decodeOTP() {
                    account = acc
                    dataScanner.dismiss(animated: true)
                }
            case .text(let recognizedText):
                if let acc = try? URL(string: recognizedText.transcript.removingCharacters(in: .whitespacesAndNewlines))?.decodeOTP() {
                    account = acc
                    dataScanner.dismiss(animated: true)
                }
            default:
                break
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(account: $account)
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
