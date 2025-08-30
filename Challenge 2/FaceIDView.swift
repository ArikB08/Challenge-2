//
//  FaceIDView.swift
//  Challenge 2
//
//  Created by Arik Bagchi on 16/8/25.
//

import SwiftUI
import AVFoundation
import Vision

struct FaceIDView: View {
    @StateObject private var classifier = RealTimeClassifier()

    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreview(session: classifier.session)
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    Text(classifier.prediction)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Unlock with your face!")
            .onAppear { classifier.start() }
            .onDisappear { classifier.stop() }
        }
    }
}

#Preview {
    FaceIDView()
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.connection?.videoOrientation = .portrait
        uiView.setNeedsLayout()
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

final class RealTimeClassifier: NSObject, ObservableObject {
    @Published var prediction: String = "Starting…"

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let outputQueue = DispatchQueue(label: "camera.video.output")
    private let analysisInterval: CFTimeInterval = 0.10
    private var lastAnalysisTime: CFTimeInterval = 0
    private let visionModel: VNCoreMLModel
    private lazy var visionRequest: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: visionModel) { [weak self] req, _ in
            guard let self, let results = req.results as? [VNClassificationObservation],
                  let top = results.first else { return }
            let line = String(format: "%@  %.0f%%", top.identifier, top.confidence * 100.0)
            DispatchQueue.main.async {
                self.prediction = line
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        return request
    }()

    override init() {
        visionModel = try! VNCoreMLModel(for: FunnyFaceAI().model)
        super.init()
    }

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            if !granted {
                DispatchQueue.main.async {
                    self.prediction = "Camera permission denied"
                }
                return
            }
            sessionQueue.async {
                self.configureSessionIfNeeded()
                if !self.session.isRunning { self.session.startRunning() }
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private var configured = false
    private func configureSessionIfNeeded() {
        guard !configured else { return }
        session.beginConfiguration()
        session.sessionPreset = .high
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(for: .video)
        guard let camera = device,
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(videoOutput)
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported { connection.videoOrientation = .portrait }
            if connection.isVideoMirroringSupported { connection.isVideoMirrored = (camera.position == .front) }
        }
        configured = true
        session.commitConfiguration()
    }
}

extension RealTimeClassifier: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard now - lastAnalysisTime >= analysisInterval else { return }
        lastAnalysisTime = now
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .up,
                                            options: [:])
        do {
            try handler.perform([visionRequest])
        } catch {
        }
    }
}
