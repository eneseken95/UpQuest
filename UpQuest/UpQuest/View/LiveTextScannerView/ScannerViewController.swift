//
//  ScannerViewController.swift
//  UpQuest
//
//  Created by Enes Eken on 30.07.2025.
//

import AVFoundation
import CoreImage
import UIKit
import Vision

class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var completion: ((Result<String, Error>) -> Void)?

    private var captureSession = AVCaptureSession()
    private var isScanning = true

    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var scanAreaView: UIView!
    private var infoLabel: UILabel!

    private var lastProcessingTime = Date(timeIntervalSince1970: 0)

    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupScanAreaView()
        setupCloseButton()
        setupInfoLabel()
    }

    private func setupScanAreaView() {
        let width: CGFloat = 260
        let height: CGFloat = 120
        let x = (view.bounds.width - width) / 2
        let y = (view.bounds.height - height) / 2 - 60

        let backgroundView = UIView(frame: view.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backgroundView.isUserInteractionEnabled = false
        view.addSubview(backgroundView)

        let path = UIBezierPath(rect: backgroundView.bounds)
        let transparentRect = CGRect(x: x, y: y, width: width, height: height)
        let transparentPath = UIBezierPath(roundedRect: transparentRect, cornerRadius: 10)
        path.append(transparentPath)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd

        backgroundView.layer.mask = maskLayer

        scanAreaView = UIView(frame: transparentRect)
        scanAreaView.layer.borderColor = UIColor.white.cgColor
        scanAreaView.layer.borderWidth = 2
        scanAreaView.backgroundColor = .clear
        scanAreaView.layer.cornerRadius = 10
        scanAreaView.isUserInteractionEnabled = false
        view.addSubview(scanAreaView)
    }

    private func setupInfoLabel() {
        infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.textColor = .white
        infoLabel.textAlignment = .center
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.numberOfLines = 0
        infoLabel.text = "Ask someone in the room to show the room code from 'Room Information' and scan it with the white box."

        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backgroundView.layer.cornerRadius = 10
        backgroundView.layer.masksToBounds = true

        view.addSubview(backgroundView)
        backgroundView.addSubview(infoLabel)

        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 10),
            infoLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -10),
            infoLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -12),
        ])

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }

    private func setupCamera() {
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            completion?(.failure(NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "No camera available"])))
            return
        }

        do {
            try videoDevice.lockForConfiguration()
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            if videoDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                videoDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            videoDevice.unlockForConfiguration()
        } catch {
            print("Error locking configuration: \(error)")
        }

        captureSession.sessionPreset = .high

        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        if now.timeIntervalSince(lastProcessingTime) < 0.5 { return }
        lastProcessingTime = now

        guard isScanning,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        var normalizedRect: CGRect = .zero
        var scanRect: CGRect = .zero
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            scanRect = self.scanAreaView.frame
            normalizedRect = self.previewLayer.metadataOutputRectConverted(fromLayerRect: scanRect)
            semaphore.signal()
        }

        semaphore.wait()

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        let cropRect = CGRect(
            x: normalizedRect.origin.x * imageWidth,
            y: (1 - normalizedRect.origin.y - normalizedRect.height) * imageHeight,
            width: normalizedRect.width * imageWidth,
            height: normalizedRect.height * imageHeight
        )

        var croppedImage = ciImage.cropped(to: cropRect)

        croppedImage = croppedImage.applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey: 1.5,
            kCIInputBrightnessKey: -0.1,
            kCIInputSaturationKey: 0,
        ])

        let handler = VNImageRequestHandler(ciImage: croppedImage, options: [:])

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                self.stopScanning()
                self.completion?(.failure(error))
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let texts = observations.compactMap { $0.topCandidates(1).first?.string }
            if let firstValid = texts.first(where: { $0.count >= 4 && $0.count <= 10 }) {
                DispatchQueue.main.async {
                    self.stopScanning()
                    self.completion?(.success(firstValid))
                }
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "tr-TR"]
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.02

        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform text recognition: \(error)")
        }
    }

    private func setupCloseButton() {
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backgroundView.layer.cornerRadius = 10
        backgroundView.layer.masksToBounds = true
        view.addSubview(backgroundView)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backgroundView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            closeButton.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            closeButton.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            closeButton.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),

            backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            backgroundView.widthAnchor.constraint(equalToConstant: 40),
            backgroundView.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    @objc private func closeTapped() {
        stopScanning()
    }

    private func stopScanning() {
        isScanning = false
        captureSession.stopRunning()
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
}
