//
//  FaceIDView.swift
//  Challenge 2
//
//  Created by Arik Bagchi on 16/8/25.
//

import SwiftUI
import AVFoundation
import Vision
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
struct FaceIDView: View {
    @StateObject private var classifier = RealTimeClassifier()
    @AppStorage("passingAccuracy") private var passAcc: Double = 75
    @AppStorage("isAppUnlocked") private var isAppUnlocked: Bool = false
    @State var typesOfFaces: [String] = ["Null", "Eyes looking up, lips ready to make a raspberry sound", "Big open mouth laugh, tongue out"]
    @State var selectedTypeOfFace = 2
    @State private var isAnimating = false
        @State private var showUnlocked = false
        
    var body: some View {
        NavigationStack {
            ZStack {
                if isAppUnlocked {
                    Color.green.ignoresSafeArea()
                    VStack {
                        ZStack {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 80, weight: .bold))
                                            .foregroundStyle(.red.gradient)
                                            .scaleEffect(showUnlocked ? 0 : 1)
                                            .opacity(showUnlocked ? 0 : 1)
                                        
                                        Image(systemName: "lock.open.fill")
                                            .font(.system(size: 80, weight: .bold))
                                            .foregroundStyle(.green.gradient)
                                            .scaleEffect(showUnlocked ? 1.2 : 0)
                                            .opacity(showUnlocked ? 1 : 0)
                                            .rotationEffect(.degrees(showUnlocked ? 360 : 0))
                                    }
                                    .shadow(color: showUnlocked ? .green.opacity(0.5) : .red.opacity(0.5),
                                            radius: 20, x: 0, y: 8)
                        Text("Unlocked")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .padding(.top, 24)
                        Text("You may now access locked apps ONCE")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .onAppear {
                               withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                                   showUnlocked = true
                                   isAnimating = true
                               }
                           }
                } else {
                    Color.gray.ignoresSafeArea()

                    ZStack {
                        CameraPreview(session: classifier.session)
                            .clipShape(Circle())
                            .frame(width: 320, height: 320)
                            .shadow(radius: 10)

                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 10)
                            .frame(width: 320, height: 320)

                       
                        Circle()
                            .trim(from: 0, to: min((classifier.predictionDict[String(selectedTypeOfFace)] ?? 0) / 100.0, 1.0))
                            .stroke(
                                (classifier.predictionDict[String(selectedTypeOfFace)] ?? 0) >= passAcc ? .green : .yellow,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 320, height: 320)
                            .animation(.easeInOut(duration: 0.2), value: classifier.predictionDict[String(selectedTypeOfFace)])

                    }

                    VStack {
                        Text("Make this face:")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .padding(.top, 24)
                        Text(typesOfFaces[selectedTypeOfFace])
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        Spacer()
                        Text(classifier.predictionDict[String(selectedTypeOfFace)] != nil ? String(format: "Confidence: %.0f%%", classifier.predictionDict[String(selectedTypeOfFace)]!) : "Confidence: 0%")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle("Unlock with your face!")
        .onAppear { classifier.start() }
        .onDisappear { classifier.stop() }
        .onChange(of: classifier.predictionDict[String(selectedTypeOfFace)] ?? 0) { newVal in
            if newVal >= passAcc { isAppUnlocked = true }
         
            
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
        view.videoPreviewLayer.connection?.videoRotationAngle = 90
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.connection?.videoRotationAngle = 90
        uiView.setNeedsLayout()
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

final class RealTimeClassifier: NSObject, ObservableObject {
    @Published var prediction: String = "Starting…"
    @Published var predictionDict: [String: Double] = [:]
        @Published var confidencePerc: Double = 0
        @Published var faceDetected: Bool = false
        @Published var faceFillProgress: CGFloat = 0

        let session = AVCaptureSession()
        private let videoOutput = AVCaptureVideoDataOutput()
        private let sessionQueue = DispatchQueue(label: "camera.session.queue")
        private let outputQueue = DispatchQueue(label: "camera.video.output")
        private let analysisInterval: CFTimeInterval = 0.10
        private var lastAnalysisTime: CFTimeInterval = 0

        private let visionModel: VNCoreMLModel
        private lazy var classifyRequest: VNCoreMLRequest = {
            let request = VNCoreMLRequest(model: visionModel) { [weak self] req, _ in
                let results = req.results as? [VNClassificationObservation] ?? []

                let predictions = results.map { obs in
                    (obs.identifier, Double(obs.confidence * 100))
                }
                let predictionsDictionary = Dictionary(uniqueKeysWithValues: predictions)

                let lines = predictions.map { String(format: "%@  %.0f%%", $0.0, $0.1) }
                    .joined(separator: "\n")

                DispatchQueue.main.async {
                    self?.predictionDict = predictionsDictionary
                    self?.prediction = lines
                    self?.confidencePerc = predictions.first?.1 ?? 0
                }
               
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        }()

        private lazy var faceRequest: VNDetectFaceRectanglesRequest = {
            VNDetectFaceRectanglesRequest { [weak self] req, _ in
                guard let self else { return }
                let hasFace = (req.results as? [VNFaceObservation])?.isEmpty == false
                DispatchQueue.main.async {
                    self.faceDetected = hasFace
                    let target: CGFloat = hasFace ? 1.0 : 0.0
            
                    self.faceFillProgress += (target - self.faceFillProgress) * 0.5
                }
            }
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
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
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

     
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)

        do {
            try handler.perform([faceRequest])

            if faceDetected {
                try handler.perform([classifyRequest])
            } else {
                DispatchQueue.main.async {
                    self.prediction = "No face"
                    self.confidencePerc = 0
                }
            }
        } catch {
            
        }
    }
}
