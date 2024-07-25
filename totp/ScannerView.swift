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
                if let s = recognizedCode.payloadStringValue, let a = try? URL(string: s)?.decodeOTP() {
                    account = a
                    print(a.description) // FIXME: debug
                    dataScanner.dismiss(animated: true)
                }
            case .text(let recognizedText):
                if let a = try? URL(string: recognizedText.transcript.trimmingCharacters(in: .whitespacesAndNewlines))?.decodeOTP() {
                    account = a
                    print(a.description) // FIXME: debug
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
            isPinchToZoomEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        viewController.delegate = context.coordinator
        try? viewController.startScanning()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        //nix
    }
    
    typealias UIViewControllerType = DataScannerViewController
}
