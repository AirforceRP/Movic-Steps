//
//  CameraView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI
import AVFoundation
import LockedCameraCapture
import SwiftData
import Combine
import Foundation

struct CameraView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    let onBarcodeDetected: (String) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        if(#available(iOS 10.0, *)) {
            UIApplication.shared.isStatusBarHidden = true
            UIApplication.shared.statusBarStyle = .darkContent;
        }
        
        let previewLayer = cameraManager.createPreviewLayer()
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Add scanning overlay
        let overlayView = ScanningOverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
        
        // Handle barcode detection
        if let barcode = cameraManager.detectedBarcode {
            onBarcodeDetected(barcode)
            cameraManager.detectedBarcode = nil
        }
    }
}

// MARK: - Scanning Overlay View
class ScanningOverlayView: UIView {
    private var scanningLine: UIView?
    private var isAnimating = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }
    
    private func setupOverlay() {
        backgroundColor = UIColor.clear
        
        // Add scanning frame
        let scanningFrame = UIView()
        scanningFrame.backgroundColor = UIColor.clear
        scanningFrame.layer.borderColor = UIColor.white.cgColor
        scanningFrame.layer.borderWidth = 2
        scanningFrame.layer.cornerRadius = 12
        scanningFrame.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scanningFrame)
        
        NSLayoutConstraint.activate([
            scanningFrame.centerXAnchor.constraint(equalTo: centerXAnchor),
            scanningFrame.centerYAnchor.constraint(equalTo: centerYAnchor),
            scanningFrame.widthAnchor.constraint(equalToConstant: 250),
            scanningFrame.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        // Add corner indicators
        addCornerIndicators(to: scanningFrame)
        
        // Add scanning line
        let scanningLine = UIView()
        scanningLine.backgroundColor = UIColor.systemBlue
        scanningLine.layer.cornerRadius = 2
        scanningLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scanningLine)
        
        NSLayoutConstraint.activate([
            scanningLine.leadingAnchor.constraint(equalTo: scanningFrame.leadingAnchor, constant: 8),
            scanningLine.trailingAnchor.constraint(equalTo: scanningFrame.trailingAnchor, constant: -8),
            scanningLine.heightAnchor.constraint(equalToConstant: 4),
            scanningLine.topAnchor.constraint(equalTo: scanningFrame.topAnchor, constant: 8)
        ])
        
        self.scanningLine = scanningLine
        
        // Add instruction label
        let instructionLabel = UILabel()
        instructionLabel.text = "Position barcode within the frame"
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: scanningFrame.bottomAnchor, constant: 30)
        ])
        
        // Start scanning animation
        startScanningAnimation()
    }
    
    private func addCornerIndicators(to frame: UIView) {
        let cornerLength: CGFloat = 20
        let cornerWidth: CGFloat = 3
        
        // Top left
        let topLeft = UIView()
        topLeft.backgroundColor = .systemBlue
        topLeft.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topLeft)
        
        NSLayoutConstraint.activate([
            topLeft.leadingAnchor.constraint(equalTo: frame.leadingAnchor),
            topLeft.topAnchor.constraint(equalTo: frame.topAnchor),
            topLeft.widthAnchor.constraint(equalToConstant: cornerLength),
            topLeft.heightAnchor.constraint(equalToConstant: cornerWidth)
        ])
        
        let topLeftVertical = UIView()
        topLeftVertical.backgroundColor = .systemBlue
        topLeftVertical.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topLeftVertical)
        
        NSLayoutConstraint.activate([
            topLeftVertical.leadingAnchor.constraint(equalTo: frame.leadingAnchor),
            topLeftVertical.topAnchor.constraint(equalTo: frame.topAnchor),
            topLeftVertical.widthAnchor.constraint(equalToConstant: cornerWidth),
            topLeftVertical.heightAnchor.constraint(equalToConstant: cornerLength)
        ])
        
        // Top right
        let topRight = UIView()
        topRight.backgroundColor = .systemBlue
        topRight.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topRight)
        
        NSLayoutConstraint.activate([
            topRight.trailingAnchor.constraint(equalTo: frame.trailingAnchor),
            topRight.topAnchor.constraint(equalTo: frame.topAnchor),
            topRight.widthAnchor.constraint(equalToConstant: cornerLength),
            topRight.heightAnchor.constraint(equalToConstant: cornerWidth)
        ])
        
        let topRightVertical = UIView()
        topRightVertical.backgroundColor = .systemBlue
        topRightVertical.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topRightVertical)
        
        NSLayoutConstraint.activate([
            topRightVertical.trailingAnchor.constraint(equalTo: frame.trailingAnchor),
            topRightVertical.topAnchor.constraint(equalTo: frame.topAnchor),
            topRightVertical.widthAnchor.constraint(equalToConstant: cornerWidth),
            topRightVertical.heightAnchor.constraint(equalToConstant: cornerLength)
        ])
        
        // Bottom left
        let bottomLeft = UIView()
        bottomLeft.backgroundColor = .systemBlue
        bottomLeft.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLeft)
        
        NSLayoutConstraint.activate([
            bottomLeft.leadingAnchor.constraint(equalTo: frame.leadingAnchor),
            bottomLeft.bottomAnchor.constraint(equalTo: frame.bottomAnchor),
            bottomLeft.widthAnchor.constraint(equalToConstant: cornerLength),
            bottomLeft.heightAnchor.constraint(equalToConstant: cornerWidth)
        ])
        
        let bottomLeftVertical = UIView()
        bottomLeftVertical.backgroundColor = .systemBlue
        bottomLeftVertical.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLeftVertical)
        
        NSLayoutConstraint.activate([
            bottomLeftVertical.leadingAnchor.constraint(equalTo: frame.leadingAnchor),
            bottomLeftVertical.bottomAnchor.constraint(equalTo: frame.bottomAnchor),
            bottomLeftVertical.widthAnchor.constraint(equalToConstant: cornerWidth),
            bottomLeftVertical.heightAnchor.constraint(equalToConstant: cornerLength)
        ])
        
        // Bottom right
        let bottomRight = UIView()
        bottomRight.backgroundColor = .systemBlue
        bottomRight.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomRight)
        
        NSLayoutConstraint.activate([
            bottomRight.trailingAnchor.constraint(equalTo: frame.trailingAnchor),
            bottomRight.bottomAnchor.constraint(equalTo: frame.bottomAnchor),
            bottomRight.widthAnchor.constraint(equalToConstant: cornerLength),
            bottomRight.heightAnchor.constraint(equalToConstant: cornerWidth)
        ])
        
        let bottomRightVertical = UIView()
        bottomRightVertical.backgroundColor = .systemBlue
        bottomRightVertical.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomRightVertical)
        
        NSLayoutConstraint.activate([
            bottomRightVertical.trailingAnchor.constraint(equalTo: frame.trailingAnchor),
            bottomRightVertical.bottomAnchor.constraint(equalTo: frame.bottomAnchor),
            bottomRightVertical.widthAnchor.constraint(equalToConstant: cornerWidth),
            bottomRightVertical.heightAnchor.constraint(equalToConstant: cornerLength)
        ])
    }
    
    private func startScanningAnimation() {
        guard let scanningLine = scanningLine else { return }
        
        isAnimating = true
        animateScanningLine()
    }
    
    private func animateScanningLine() {
        guard isAnimating, let scanningLine = scanningLine else { return }
        
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            scanningLine.transform = CGAffineTransform(translationX: 0, y: 130)
        }) { _ in
            if self.isAnimating {
                self.animateScanningLine()
            }
        }
    }
    
    func stopScanningAnimation() {
        isAnimating = false
        scanningLine?.layer.removeAllAnimations()
    }
}
