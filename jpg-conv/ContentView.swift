//
//  ContentView.swift
//  jpg-conv
//
//  Created by Ali Siddique on 1/11/25.
//

import SwiftUI
import SwiftData


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
// ImageConverterApp.swift


// ContentView.swift
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ImageConverterViewModel()
    @State private var showingImagePicker = false
    @State private var showingExporter = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("Select Image")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                if viewModel.selectedImage != nil {
                    Picker("Convert to", selection: $viewModel.selectedFormat) {
                        ForEach(ImageFormat.allCases) { format in
                            Text(format.description).tag(format)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    Button(action: {
                        showingExporter = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Convert & Export")
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.convertedData == nil)
                }
                
                if viewModel.isConverting {
                    ProgressView()
                        .padding()
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Image Converter")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage)
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: viewModel.convertedDocument,
                contentType: viewModel.selectedFormat.utType,
                defaultFilename: "converted_image"
            ) { result in
                switch result {
                case .success(let url):
                    viewModel.error = nil
                    print("Saved to \(url)")
                case .failure(let error):
                    viewModel.error = "Export failed: \(error.localizedDescription)"
                }
            }
            .onChange(of: viewModel.selectedImage) { _ in
                viewModel.convertImage()
            }
            .onChange(of: viewModel.selectedFormat) { _ in
                viewModel.convertImage()
            }
        }
    }
}

// ImageConverterViewModel.swift
import SwiftUI
import UniformTypeIdentifiers

enum ImageFormat: String, CaseIterable, Identifiable {
    case jpeg
    case png
    case heic
    case pdf
    
    var id: String { rawValue }
    
    var description: String { rawValue.uppercased() }
    
    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .heic: return .heic
        case .pdf: return .pdf
        }
    }
    
    var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        case .heic: return "image/heic"
        case .pdf: return "application/pdf"
        }
    }
}

class ImageConverterViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedFormat: ImageFormat = .png
    @Published var convertedData: Data?
    @Published var error: String?
    @Published var isConverting = false
    
    var convertedDocument: ConvertedImageDocument? {
        guard let data = convertedData else { return nil }
        return ConvertedImageDocument(imageData: data, format: selectedFormat)
    }
    
    func convertImage() {
        guard let image = selectedImage else { return }
        
        isConverting = true
        error = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try self.convert(image: image, to: self.selectedFormat)
                
                DispatchQueue.main.async {
                    self.convertedData = data
                    self.isConverting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "Conversion failed: \(error.localizedDescription)"
                    self.isConverting = false
                }
            }
        }
    }
    
    private func convert(image: UIImage, to format: ImageFormat) throws -> Data {
        switch format {
        case .jpeg:
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                throw ConversionError.conversionFailed
            }
            return data
            
        case .png:
            guard let data = image.pngData() else {
                throw ConversionError.conversionFailed
            }
            return data
            
        case .heic:
            guard let data = try image.heicData() else {
                throw ConversionError.conversionFailed
            }
            return data
            
        case .pdf:
            return try image.pdfData()
        }
    }
}

// ImagePicker.swift
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// ConvertedImageDocument.swift
struct ConvertedImageDocument: FileDocument {
    let imageData: Data
    let format: ImageFormat
    
    static var readableContentTypes: [UTType] {
        [.jpeg, .png, .heic, .pdf]
    }
    
    init(imageData: Data, format: ImageFormat) {
        self.imageData = imageData
        self.format = format
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.imageData = data
        self.format = .jpeg // Default format for reading
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: imageData)
    }
}

// UIImage+Extensions.swift
extension UIImage {
    func heicData(compressionQuality: CGFloat = 0.8) throws -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, "public.heic" as CFString, 1, nil) else {
            throw ConversionError.conversionFailed
        }
        
        guard let cgImage = self.cgImage else {
            throw ConversionError.conversionFailed
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.conversionFailed
        }
        
        return data as Data
    }
    
    func pdfData() throws -> Data {
        let pdfData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
        
        var mediaBox = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
            throw ConversionError.conversionFailed
        }
        
        pdfContext.beginPage(mediaBox: &mediaBox)
        pdfContext.draw(self.cgImage!, in: mediaBox)
        pdfContext.endPage()
        
        return pdfData as Data
    }
}

// ConversionError.swift
enum ConversionError: Error {
    case conversionFailed
    
    var localizedDescription: String {
        switch self {
        case .conversionFailed:
            return "Failed to convert the image to the selected format"
        }
    }
}
