//
//  LiveTextScannerView.swift
//  UpQuest
//
//  Created by Enes Eken on 30.07.2025.
//

import AVFoundation
import SwiftUI
import Vision

struct LiveTextScannerView: UIViewControllerRepresentable {
    typealias CompletionHandler = (Result<String, Error>) -> Void

    var completion: CompletionHandler

    init(completion: @escaping CompletionHandler) {
        self.completion = completion
    }

    class Coordinator: NSObject {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        ScannerViewController(completion: completion)
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

#Preview {
    LiveTextScannerView { result in
        switch result {
        case let .success(code):
            print("Scanned code: \(code)")
        case let .failure(error):
            print("Scan failed with error: \(error.localizedDescription)")
        }
    }
    .edgesIgnoringSafeArea(.all)
}
