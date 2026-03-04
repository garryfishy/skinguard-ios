//
//  ProductScanView.swift
//  SkinGuard
//

import SwiftUI
import Vision
import UIKit

// MARK: - Models

struct IngredientAnalysisResponse: Codable {
    let success: Bool
    let data: IngredientAnalysisData?
    let error: IngredientAnalysisError?
}

struct IngredientAnalysisData: Codable {
    let riskyIngredients: [RiskyIngredient]
    let safeIngredients: [String]
    let safeCount: Int
    let totalDetected: Int
    let summary: String
}

struct RiskyIngredient: Codable, Identifiable {
    let name: String
    let aliases: [String]
    let risk: String
    let severity: String
    let severityReason: String
    let pregnancy: IngredientSafety
    let recommendation: IngredientSafety
    var id: String { name }
}

struct IngredientSafety: Codable {
    let safe: Bool
    let reason: String
}

struct IngredientAnalysisError: Codable {
    let code: String
    let message: String
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

// MARK: - Crop Selection View

private enum CornerID { case tl, tr, bl, br }

struct CropSelectionView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onRetake: () -> Void

    @State private var selRect: CGRect = .zero
    @State private var hasSelection = false
    @State private var containerSize: CGSize = .zero
    // Tracks which gesture is active to distinguish resize vs new draw
    @State private var lastDragStart: CGPoint = CGPoint(x: -1, y: -1)
    @State private var activeCorner: CornerID? = nil

    var hasValidSelection: Bool {
        hasSelection && selRect.width > 20 && selRect.height > 20
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(hasValidSelection
                     ? "Seret sudut untuk menyesuaikan area"
                     : "Seret jari untuk memilih area daftar bahan")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .animation(.easeInOut, value: hasValidSelection)

                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)

                        Canvas { context, size in
                            if hasSelection && selRect.width > 5 && selRect.height > 5 {
                                // Dim outside selection via even-odd rule
                                var path = Path()
                                path.addRect(CGRect(origin: .zero, size: size))
                                path.addRect(selRect)
                                context.fill(path, with: .color(.black.opacity(0.55)), style: FillStyle(eoFill: true))

                                // Border
                                context.stroke(Path(selRect), with: .color(.white), lineWidth: 2)

                                // Corner handles
                                for pt in cornerPoints() {
                                    context.fill(
                                        Path(ellipseIn: CGRect(x: pt.x - 8, y: pt.y - 8, width: 16, height: 16)),
                                        with: .color(.white)
                                    )
                                }
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 3)
                            .onChanged { value in
                                // Capture size here — guaranteed valid since gesture is firing
                                containerSize = geo.size

                                // Detect new gesture by change in startLocation
                                if value.startLocation != lastDragStart {
                                    lastDragStart = value.startLocation
                                    activeCorner = hasSelection
                                        ? nearestCorner(to: value.startLocation)
                                        : nil
                                }

                                if let corner = activeCorner {
                                    resizeCorner(corner, to: value.location)
                                } else {
                                    // Draw new selection
                                    let x = min(value.startLocation.x, value.location.x)
                                    let y = min(value.startLocation.y, value.location.y)
                                    selRect = CGRect(
                                        x: x, y: y,
                                        width: abs(value.location.x - value.startLocation.x),
                                        height: abs(value.location.y - value.startLocation.y)
                                    )
                                    hasSelection = true
                                }
                            }
                    )
                }


                VStack(spacing: 12) {
                    if !hasValidSelection {
                        Text("Belum ada area yang dipilih")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        Button("Foto Ulang") { onRetake() }
                            .buttonStyle(.bordered)

                        Button("Analisis Area Ini") {
                            onCrop(cropImage())
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!hasValidSelection)
                    }
                }
                .padding()
            }
            .navigationTitle("Pilih Area Bahan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func cornerPoints() -> [CGPoint] {
        [
            CGPoint(x: selRect.minX, y: selRect.minY),
            CGPoint(x: selRect.maxX, y: selRect.minY),
            CGPoint(x: selRect.minX, y: selRect.maxY),
            CGPoint(x: selRect.maxX, y: selRect.maxY)
        ]
    }

    private func nearestCorner(to point: CGPoint, threshold: CGFloat = 35) -> CornerID? {
        let corners: [(CornerID, CGPoint)] = [
            (.tl, CGPoint(x: selRect.minX, y: selRect.minY)),
            (.tr, CGPoint(x: selRect.maxX, y: selRect.minY)),
            (.bl, CGPoint(x: selRect.minX, y: selRect.maxY)),
            (.br, CGPoint(x: selRect.maxX, y: selRect.maxY))
        ]
        return corners.first { hypot($0.1.x - point.x, $0.1.y - point.y) < threshold }?.0
    }

    private func resizeCorner(_ corner: CornerID, to p: CGPoint) {
        let minSize: CGFloat = 20
        switch corner {
        case .tl:
            let newX = min(p.x, selRect.maxX - minSize)
            let newY = min(p.y, selRect.maxY - minSize)
            selRect = CGRect(x: newX, y: newY, width: selRect.maxX - newX, height: selRect.maxY - newY)
        case .tr:
            let newY = min(p.y, selRect.maxY - minSize)
            selRect = CGRect(x: selRect.minX, y: newY, width: max(minSize, p.x - selRect.minX), height: selRect.maxY - newY)
        case .bl:
            let newX = min(p.x, selRect.maxX - minSize)
            selRect = CGRect(x: newX, y: selRect.minY, width: selRect.maxX - newX, height: max(minSize, p.y - selRect.minY))
        case .br:
            selRect = CGRect(x: selRect.minX, y: selRect.minY, width: max(minSize, p.x - selRect.minX), height: max(minSize, p.y - selRect.minY))
        }
    }

    private func cropImage() -> UIImage {
        guard containerSize.width > 0, containerSize.height > 0 else { return image }

        let normalized = image.normalizedOrientation()
        let imageSize = normalized.size

        // How the image fits inside the container (scaledToFit)
        let scale = min(containerSize.width / imageSize.width,
                        containerSize.height / imageSize.height)
        let renderedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let offset = CGPoint(x: (containerSize.width - renderedSize.width) / 2,
                             y: (containerSize.height - renderedSize.height) / 2)

        // Map selection from screen space → image space
        let imageScale = 1.0 / scale
        let cropOrigin = CGPoint(
            x: max(0, (selRect.minX - offset.x) * imageScale),
            y: max(0, (selRect.minY - offset.y) * imageScale)
        )
        let cropSize = CGSize(
            width: min(imageSize.width - cropOrigin.x, selRect.width * imageScale),
            height: min(imageSize.height - cropOrigin.y, selRect.height * imageScale)
        )
        guard cropSize.width > 0, cropSize.height > 0 else { return normalized }

        // Draw into a renderer — avoids cgImage coordinate system issues entirely
        let renderer = UIGraphicsImageRenderer(size: cropSize)
        return renderer.image { _ in
            normalized.draw(at: CGPoint(x: -cropOrigin.x, y: -cropOrigin.y))
        }
    }
}

// MARK: - Ingredient Scan View

private enum ScanState {
    case camera
    case crop(UIImage)
    case processing
    case results(IngredientAnalysisData)
    case error(String)
}

struct IngredientScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scanState: ScanState = .camera

    var body: some View {
        switch scanState {
        case .camera:
            CameraPickerView { image in
                scanState = .crop(image)
            } onCancel: {
                dismiss()
            }
            .ignoresSafeArea()

        case .crop(let image):
            CropSelectionView(
                image: image,
                onCrop: { croppedImage in
                    Task { await processImage(croppedImage) }
                },
                onRetake: { scanState = .camera }
            )

        case .processing:
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.5)
                Text("Sedang menganalisis bahan...")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .results(let data):
            IngredientResultsView(data: data, onDone: { dismiss() }, onRetake: { scanState = .camera })

        case .error(let message):
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                HStack(spacing: 12) {
                    Button("Foto Ulang") { scanState = .camera }
                        .buttonStyle(.bordered)
                    Button("Tutup") { dismiss() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }

    private func processImage(_ image: UIImage) async {
        await MainActor.run { scanState = .processing }

        guard let ocrText = await extractText(from: image), !ocrText.isEmpty else {
            await MainActor.run {
                scanState = .error("Tidak ada teks yang ditemukan. Coba lagi dengan foto yang lebih jelas pada bagian daftar bahan.")
            }
            return
        }

        do {
            let data = try await analyzeIngredients(text: ocrText)
            await MainActor.run { scanState = .results(data) }
        } catch {
            await MainActor.run {
                scanState = .error("Tidak dapat menganalisis bahan. Periksa koneksi internet Anda dan coba lagi.")
            }
        }
    }

    private func extractText(from image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: ", ")
                continuation.resume(returning: text.isEmpty ? nil : text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }

    private func analyzeIngredients(text: String) async throws -> IngredientAnalysisData {
        let url = URL(string: "https://skinguard-api.oceandigital.id/api/analyze-ingredients")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["ingredientText": text])
        request.timeoutInterval = 40

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(IngredientAnalysisResponse.self, from: data)

        if response.success, let analysisData = response.data {
            return analysisData
        } else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - Results View

struct IngredientResultsView: View {
    let data: IngredientAnalysisData
    let onDone: () -> Void
    let onRetake: () -> Void

    var isRecommended: Bool {
        data.riskyIngredients.allSatisfy { $0.recommendation.safe }
    }

    var isSafeForPregnancy: Bool {
        data.riskyIngredients.allSatisfy { $0.pregnancy.safe }
    }

    var pregnancyWarnings: [String] {
        data.riskyIngredients.map { "\($0.name): \($0.pregnancy.reason)" }
    }

    var recommendationWarnings: [String] {
        data.riskyIngredients.map { "\($0.name): \($0.recommendation.reason)" }
    }

    var body: some View {
        NavigationStack {
            List {

                // MARK: - Rekomendasi
                Section("Rekomendasi") {
                    if isRecommended {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundStyle(.white)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Produk Aman Digunakan")
                                    .font(.subheadline.bold())
                                Text("Tidak ada bahan berbahaya ditemukan dari hasil analisis.")
                                    .font(.caption)
                                    .opacity(0.9)
                            }
                            .foregroundStyle(.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(primaryColor)
                        )
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "xmark.octagon.fill")
                                .font(.title2)
                                .foregroundStyle(.white)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tidak Direkomendasikan")
                                    .font(.subheadline.bold())
                                ForEach(recommendationWarnings, id: \.self) { reason in
                                    Text(reason)
                                        .font(.caption)
                                        .opacity(0.9)
                                }
                            }
                            .foregroundStyle(.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.red)
                        )
                    }
                }

                // MARK: - Keamanan Ibu Hamil
                Section("Keamanan Ibu Hamil") {
                    HStack(spacing: 12) {
                        Image("pregnant_woman_icon")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)   // ini penting
                            .foregroundColor(isSafeForPregnancy ? primaryColor : .red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(isSafeForPregnancy ? "Aman untuk Ibu Hamil" : "Tidak Aman untuk Ibu Hamil")
                                .font(.body.bold())

                            ForEach(pregnancyWarnings, id: \.self) { reason in
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Bahan Berbahaya (HANYA MUNCUL JIKA ADA)
                if !data.riskyIngredients.isEmpty {
                    Section("Bahan Berbahaya (\(data.riskyIngredients.count))") {
                        ForEach(data.riskyIngredients) { ingredient in
                            DisclosureGroup {
                                VStack(alignment: .leading, spacing: 8) {

                                    if !ingredient.aliases.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Juga dikenal sebagai")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            Text(ingredient.aliases.joined(separator: ", "))
                                                .font(.caption)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Risiko")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Text(ingredient.risk)
                                            .font(.caption)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Alasan")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Text(ingredient.severityReason)
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 4)
                            } label: {
                                Label {
                                    Text(ingredient.name)
                                        .font(.body.bold())
                                } icon: {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .red)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                // MARK: - Bahan Aman
                if !data.safeIngredients.isEmpty {
                    Section("Bahan Aman (\(data.safeIngredients.count))") {
                        ForEach(data.safeIngredients, id: \.self) { ingredient in
                            Label {
                                Text(ingredient)
                                    .font(.subheadline)
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, primaryColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Analisis Bahan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Foto Ulang") { onRetake() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Selesai") { onDone() }
                }
            }
        }
    }
}

extension UIImage {

    /// Fix image orientation from camera
    func normalizedOrientation() -> UIImage {

        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}
