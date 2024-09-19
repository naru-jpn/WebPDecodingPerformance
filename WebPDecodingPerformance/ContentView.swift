//
//  ContentView.swift
//  WebPDecodingPerformance
//
//  Created by Naruki Chigira on 2024/09/19.
//

import AsyncAlgorithms
import SwiftUI

private let counter = Counter(interval: 1.0 / 30.0)

struct ContentView: View {
    /// Array of UIImage converted from animated WebP.
    @State private var uiImages: [UIImage]?
    /// Array of Image converted from uiImages.
    @State private var images: [Image]?
    /// Array of UIImage used as animation frames.
    @State private var animatingImages: [Image]?
    /// Text representing progress of converting.
    @State private var convertingProgress: String?
    
    private let cpuUsage = CPUUsage()
    private let timer = AsyncTimerSequence(interval: .seconds(1), clock: .continuous)
    /// Monitoring CPU Usage.
    @State private var cpuUsageMessage: String = ""
    
    var body: some View {
        VStack(spacing: 40) {
            if let images, let uiImages {
                VStack(spacing: 20) {
                    if let animatingImages {
                        // Preview animation
                        AnimatingImage(images: animatingImages, counter: counter)
                    } else if let convertingProgress {
                        // Progress
                        Text(convertingProgress)
                    } else {
                        // Select procedure to see performance of decoding WebP images.
                        Button("Start Animation") {
                            animatingImages = images
                        }
                        Button("Convert All WebP to PNG Representation") {
                            Task.detached(priority: .background) {
                                await convertImagesToPNGRepresentation(images: uiImages)
                            }
                        }
                        Button("Convert All WebP to JPEG Representation") {
                            Task.detached(priority: .background) {
                                await convertImagesToJPEGRepresentation(images: uiImages)
                            }
                        }
                    }
                }
            } else {
                Text("Initializing...")
            }
            Text(cpuUsageMessage)
        }
        .padding()
        .onAppear {
            // Initialize
            convertWebPToImageArray()
            // Update CPU Usage
            Task {
                for await _ in timer {
                    if let value = cpuUsage.getCurrentUsage() {
                        cpuUsageMessage = String(format: "CPU Usage: %4.1f%%", value)
                    } else {
                        cpuUsageMessage = "CPU Usage: -"
                    }
                }
            }
        }
    }
    
    /// Convert bundled WebP file to image array.
    ///
    /// This method is fast.
    private func convertWebPToImageArray() {
        let path = Bundle.main.path(forResource: "sample", ofType: "webp")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path)) as CFData
        let source = CGImageSourceCreateWithData(data, nil)!
        let frameCount = CGImageSourceGetCount(source)
        
        let uiImages = (0..<frameCount).map { (index: Int) -> UIImage in
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                fatalError("Failed to create image from CGImageSource.")
            }
            return UIImage(cgImage: cgImage)
        }
        
        self.uiImages = uiImages
        self.images = uiImages.map(Image.init(uiImage:))
    }
    
    /// Convert all Webp frame images to PNG representation image.
    ///
    /// This method is slow.
    private func convertImagesToPNGRepresentation(images: [UIImage]) async {
        let count = images.count
        var datum: [Data] = []
        for i in 0..<count {
            await MainActor.run { convertingProgress = "Converting to PNG... \(i)/\(images.count)" }
            let data = images[i].pngData()!
            datum.append(data)
        }
        await MainActor.run {
            convertingProgress = nil
            self.animatingImages = datum.compactMap(UIImage.init(data:)).compactMap(Image.init(uiImage:))
        }
    }
    
    /// Convert all Webp frame images to JPEG representation image.
    ///
    /// This method is slow.
    private func convertImagesToJPEGRepresentation(images: [UIImage]) async {
        let count = images.count
        var datum: [Data] = []
        for i in 0..<count {
            await MainActor.run { convertingProgress = "Converting to JPEG... \(i)/\(images.count)" }
            let data = images[i].jpegData(compressionQuality: 1.0)!
            datum.append(data)
        }
        await MainActor.run {
            convertingProgress = nil
            self.animatingImages = datum.compactMap(UIImage.init(data:)).compactMap(Image.init(uiImage:))
        }
    }
}

private struct AnimatingImage: View {
    let images: [Image]
    @ObservedObject var counter: Counter
    var body: some View {
        VStack{
            images[counter.value % images.count]
            
        }
    }
}

private class Counter: ObservableObject {
    private var timer: Timer?
    @Published var value: Int = 0
    init(interval: Double) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in self.value += 1 }
    }
}

#Preview {
    ContentView()
}
