////
////  ContentView.swift
////  jpg-conv
////
////  Created by Ali Siddique on 1/11/25.
////
//
//import SwiftUI
//import SwiftData
//
//
//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
//// ImageConverterApp.swift
//
//
//// ContentView.swift
//import SwiftUI
//import PhotosUI
//import UniformTypeIdentifiers
//
//struct ContentView: View {
//    @StateObject private var viewModel = ImageConverterViewModel()
//    @State private var showingImagePicker = false
//    @State private var showingExporter = false
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                if let image = viewModel.selectedImage {
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFit()
//                        .padding()
//                }
//                
//                Button(action: {
//                    showingImagePicker = true
//                }) {
//                    HStack {
//                        Image(systemName: "photo.fill")
//                        Text("Select Image")
//                    }
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                }
//                
//                if viewModel.selectedImage != nil {
//                    Picker("Convert to", selection: $viewModel.selectedFormat) {
//                        ForEach(ImageFormat.allCases) { format in
//                            Text(format.description).tag(format)
//                        }
//                    }
//                    .pickerStyle(MenuPickerStyle())
//                    .padding()
//                    
//                    Button(action: {
//                        showingExporter = true
//                    }) {
//                        HStack {
//                            Image(systemName: "square.and.arrow.up")
//                            Text("Convert & Export")
//                        }
//                        .padding()
//                        .background(Color.green)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                    }
//                    .disabled(viewModel.convertedData == nil)
//                }
//                
//                if viewModel.isConverting {
//                    ProgressView()
//                        .padding()
//                }
//                
//                if let error = viewModel.error {
//                    Text(error)
//                        .foregroundColor(.red)
//                        .padding()
//                }
//            }
//            .padding()
//            .navigationTitle("Image Converter")
//            .sheet(isPresented: $showingImagePicker) {
//                ImagePicker(image: $viewModel.selectedImage)
//            }
//            .fileExporter(
//                isPresented: $showingExporter,
//                document: viewModel.convertedDocument,
//                contentType: viewModel.selectedFormat.utType,
//                defaultFilename: "converted_image"
//            ) { result in
//                switch result {
//                case .success(let url):
//                    viewModel.error = nil
//                    print("Saved to \(url)")
//                case .failure(let error):
//                    viewModel.error = "Export failed: \(error.localizedDescription)"
//                }
//            }
//            .onChange(of: viewModel.selectedImage) { _ in
//                viewModel.convertImage()
//            }
//            .onChange(of: viewModel.selectedFormat) { _ in
//                viewModel.convertImage()
//            }
//        }
//    }
//}
//
//// ImageConverterViewModel.swift
//import SwiftUI
//import UniformTypeIdentifiers
//
//enum ImageFormat: String, CaseIterable, Identifiable {
//    case jpeg
//    case png
//    case heic
//    case pdf
//    
//    var id: String { rawValue }
//    
//    var description: String { rawValue.uppercased() }
//    
//    var utType: UTType {
//        switch self {
//        case .jpeg: return .jpeg
//        case .png: return .png
//        case .heic: return .heic
//        case .pdf: return .pdf
//        }
//    }
//    
//    var mimeType: String {
//        switch self {
//        case .jpeg: return "image/jpeg"
//        case .png: return "image/png"
//        case .heic: return "image/heic"
//        case .pdf: return "application/pdf"
//        }
//    }
//}
//
//class ImageConverterViewModel: ObservableObject {
//    @Published var selectedImage: UIImage?
//    @Published var selectedFormat: ImageFormat = .png
//    @Published var convertedData: Data?
//    @Published var error: String?
//    @Published var isConverting = false
//    
//    var convertedDocument: ConvertedImageDocument? {
//        guard let data = convertedData else { return nil }
//        return ConvertedImageDocument(imageData: data, format: selectedFormat)
//    }
//    
//    func convertImage() {
//        guard let image = selectedImage else { return }
//        
//        isConverting = true
//        error = nil
//        
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            guard let self = self else { return }
//            
//            do {
//                let data = try self.convert(image: image, to: self.selectedFormat)
//                
//                DispatchQueue.main.async {
//                    self.convertedData = data
//                    self.isConverting = false
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.error = "Conversion failed: \(error.localizedDescription)"
//                    self.isConverting = false
//                }
//            }
//        }
//    }
//    
//    private func convert(image: UIImage, to format: ImageFormat) throws -> Data {
//        switch format {
//        case .jpeg:
//            guard let data = image.jpegData(compressionQuality: 0.8) else {
//                throw ConversionError.conversionFailed
//            }
//            return data
//            
//        case .png:
//            guard let data = image.pngData() else {
//                throw ConversionError.conversionFailed
//            }
//            return data
//            
//        case .heic:
//            guard let data = try image.heicData() else {
//                throw ConversionError.conversionFailed
//            }
//            return data
//            
//        case .pdf:
//            return try image.pdfData()
//        }
//    }
//}
//
//// ImagePicker.swift
//struct ImagePicker: UIViewControllerRepresentable {
//    @Binding var image: UIImage?
//    
//    func makeUIViewController(context: Context) -> PHPickerViewController {
//        var config = PHPickerConfiguration()
//        config.filter = .images
//        
//        let picker = PHPickerViewController(configuration: config)
//        picker.delegate = context.coordinator
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, PHPickerViewControllerDelegate {
//        let parent: ImagePicker
//        
//        init(_ parent: ImagePicker) {
//            self.parent = parent
//        }
//        
//        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//            picker.dismiss(animated: true)
//            
//            guard let provider = results.first?.itemProvider else { return }
//            
//            if provider.canLoadObject(ofClass: UIImage.self) {
//                provider.loadObject(ofClass: UIImage.self) { image, error in
//                    DispatchQueue.main.async {
//                        self.parent.image = image as? UIImage
//                    }
//                }
//            }
//        }
//    }
//}
//
//// ConvertedImageDocument.swift
//struct ConvertedImageDocument: FileDocument {
//    let imageData: Data
//    let format: ImageFormat
//    
//    static var readableContentTypes: [UTType] {
//        [.jpeg, .png, .heic, .pdf]
//    }
//    
//    init(imageData: Data, format: ImageFormat) {
//        self.imageData = imageData
//        self.format = format
//    }
//    
//    init(configuration: ReadConfiguration) throws {
//        guard let data = configuration.file.regularFileContents else {
//            throw CocoaError(.fileReadCorruptFile)
//        }
//        self.imageData = data
//        self.format = .jpeg // Default format for reading
//    }
//    
//    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
//        FileWrapper(regularFileWithContents: imageData)
//    }
//}
//
//// UIImage+Extensions.swift
//extension UIImage {
//    func heicData(compressionQuality: CGFloat = 0.8) throws -> Data? {
//        let data = NSMutableData()
//        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, "public.heic" as CFString, 1, nil) else {
//            throw ConversionError.conversionFailed
//        }
//        
//        guard let cgImage = self.cgImage else {
//            throw ConversionError.conversionFailed
//        }
//        
//        let options: [CFString: Any] = [
//            kCGImageDestinationLossyCompressionQuality: compressionQuality
//        ]
//        
//        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
//        guard CGImageDestinationFinalize(destination) else {
//            throw ConversionError.conversionFailed
//        }
//        
//        return data as Data
//    }
//    
//    func pdfData() throws -> Data {
//        let pdfData = NSMutableData()
//        let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
//        
//        var mediaBox = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        
//        guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
//            throw ConversionError.conversionFailed
//        }
//        
//        pdfContext.beginPage(mediaBox: &mediaBox)
//        pdfContext.draw(self.cgImage!, in: mediaBox)
//        pdfContext.endPage()
//        
//        return pdfData as Data
//    }
//}
//
//// ConversionError.swift
//enum ConversionError: Error {
//    case conversionFailed
//    
//    var localizedDescription: String {
//        switch self {
//        case .conversionFailed:
//            return "Failed to convert the image to the selected format"
//        }
//    }
//}
//
//import SwiftUI
//import UIKit
//import PhotosUI
//import UniformTypeIdentifiers
//import AVFoundation
//
//// Main data model to store conversion items
//class ConversionItem: Identifiable, ObservableObject {
//    let id = UUID()
//    let originalImage: UIImage
//    let originalFormat: String
//    @Published var convertedData: Data?
//    let targetFormat: String
//    let date: Date
//    
//    init(originalImage: UIImage, originalFormat: String, targetFormat: String) {
//        self.originalImage = originalImage
//        self.originalFormat = originalFormat
//        self.targetFormat = targetFormat
//        self.date = Date()
//    }
//}
//// Image conversion service
//import UIKit
//import ImageIO
//import CoreImage
//import CoreGraphics
//import PDFKit
//import WebKit
//
//class ImageConverterService {
//    enum ConversionError: Error {
//        case conversionFailed
//        case invalidInput
//        case unsupportedFormat
//    }
//    
//    static func convert(image: UIImage, to format: String) -> Data? {
//        switch format.lowercased() {
//        case "jpg", "jpeg":
//            return image.jpegData(compressionQuality: 0.8)
//            
//        case "png":
//            return image.pngData()
//            
//        case "heic":
//            return convertToHEIC(image)
//            
//        case "heif":
//            return convertToHEIF(image)
//            
//        case "gif":
//            return convertToGIF(image)
//            
//        case "tiff":
//            return convertToTIFF(image)
//            
//        case "bmp":
//            return convertToBMP(image)
//            
//        case "pdf":
//            return convertToPDF(image)
//            
//        case "svg":
//            return convertToSVG(image)
//            
//        case "webp":
//            return convertToWebP(image)
//            
//        case "raw":
//            return convertToRAW(image)
//            
//        default:
//            return nil
//        }
//    }
//    
//
//    private static func convertToHEIF(_ image: UIImage) -> Data? {
//        guard let cgImage = image.cgImage else { return nil }
//        
//        let data = NSMutableData()
//        guard let destination = CGImageDestinationCreateWithData(
//            data as CFMutableData,
//            "public.heif" as CFString,
//            1,
//            nil
//        ) else {
//            return nil
//        }
//        
//        let options: [CFString: Any] = [
//            kCGImageDestinationLossyCompressionQuality: 0.8,
//            kCGImageDestinationOptimizeColorForSharing: true
//        ]
//        
//        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
//        
//        if CGImageDestinationFinalize(destination) {
//            return data as Data
//        }
//        return nil
//    }
//
//    private static func convertToHEIC(_ image: UIImage) -> Data? {
//        guard let cgImage = image.cgImage else { return nil }
//        
//        let data = NSMutableData()
//        guard let destination = CGImageDestinationCreateWithData(
//            data as CFMutableData,
//            "public.heic" as CFString,
//            1,
//            nil
//        ) else {
//            return nil
//        }
//        
//        let options: [CFString: Any] = [
//            kCGImageDestinationLossyCompressionQuality: 0.8,
//            kCGImageDestinationOptimizeColorForSharing: true
//        ]
//        
//        // Try to create HEIC
//        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
//        
//        if !CGImageDestinationFinalize(destination) {
//            // If HEIC fails, fallback to JPEG
//            return image.jpegData(compressionQuality: 0.8)
//        }
//        
//        return data as Data
//    }
//    private static func convertToGIF(_ image: UIImage) -> Data? {
//           guard let mutableData = CFDataCreateMutable(nil, 0),
//                 let destination = CGImageDestinationCreateWithData(
//                   mutableData,
//                   UTType.gif.identifier as CFString,
//                   1,
//                   nil
//                 ),
//                 let cgImage = image.cgImage else {
//               return nil
//           }
//           
//           let properties = [
//               kCGImagePropertyGIFDictionary: [
//                   kCGImagePropertyGIFHasGlobalColorMap: true,
//                   kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB,
//                   kCGImagePropertyDepth: 8
//               ]
//           ]
//           
//           CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
//           guard CGImageDestinationFinalize(destination) else { return nil }
//           return mutableData as Data
//       }
//    
//    private static func convertToTIFF(_ image: UIImage) -> Data? {
//        guard let mutableData = CFDataCreateMutable(nil, 0),
//              let destination = CGImageDestinationCreateWithData(mutableData, "public.tiff" as CFString, 1, nil),
//              let cgImage = image.cgImage else {
//            return nil
//        }
//        
//        let options: [CFString: Any] = [
//            kCGImageDestinationLossyCompressionQuality: 1.0, // TIFF supports lossless compression
//        ]
//        
//        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
//        guard CGImageDestinationFinalize(destination) else { return nil }
//        return mutableData as Data
//    }
//    
//    private static func convertToBMP(_ image: UIImage) -> Data? {
//        guard let cgImage = image.cgImage else { return nil }
//        
//        let bitsPerComponent = 8
//        let bytesPerRow = 4 * cgImage.width
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
//        
//        guard let context = CGContext(data: nil,
//                                    width: cgImage.width,
//                                    height: cgImage.height,
//                                    bitsPerComponent: bitsPerComponent,
//                                    bytesPerRow: bytesPerRow,
//                                    space: colorSpace,
//                                    bitmapInfo: bitmapInfo) else {
//            return nil
//        }
//        
//        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
//        
//        guard let data = context.data else { return nil }
//        
//        // BMP Header structure
//        let fileHeaderSize = 14
//        let infoHeaderSize = 40
//        let totalHeaderSize = fileHeaderSize + infoHeaderSize
//        let imageSize = cgImage.width * cgImage.height * 4
//        let fileSize = totalHeaderSize + imageSize
//        
//        var bmpData = Data()
//        
//        // File Header (14 bytes)
//        bmpData.append("BM".data(using: .ascii)!)  // Signature
//        withUnsafeBytes(of: UInt32(fileSize).littleEndian) { bmpData.append(contentsOf: $0) }  // File size
//        withUnsafeBytes(of: UInt16(0).littleEndian) { bmpData.append(contentsOf: $0) }  // Reserved
//        withUnsafeBytes(of: UInt16(0).littleEndian) { bmpData.append(contentsOf: $0) }  // Reserved
//        withUnsafeBytes(of: UInt32(totalHeaderSize).littleEndian) { bmpData.append(contentsOf: $0) }  // Offset to pixel data
//        
//        // Info Header (40 bytes)
//        withUnsafeBytes(of: UInt32(infoHeaderSize).littleEndian) { bmpData.append(contentsOf: $0) }  // Info header size
//        withUnsafeBytes(of: Int32(cgImage.width).littleEndian) { bmpData.append(contentsOf: $0) }  // Image width
//        withUnsafeBytes(of: Int32(cgImage.height).littleEndian) { bmpData.append(contentsOf: $0) }  // Image height
//        withUnsafeBytes(of: UInt16(1).littleEndian) { bmpData.append(contentsOf: $0) }  // Number of color planes
//        withUnsafeBytes(of: UInt16(32).littleEndian) { bmpData.append(contentsOf: $0) }  // Bits per pixel
//        withUnsafeBytes(of: UInt32(0).littleEndian) { bmpData.append(contentsOf: $0) }  // Compression method
//        withUnsafeBytes(of: UInt32(imageSize).littleEndian) { bmpData.append(contentsOf: $0) }  // Image size
//        withUnsafeBytes(of: Int32(2835).littleEndian) { bmpData.append(contentsOf: $0) }  // Horizontal resolution
//        withUnsafeBytes(of: Int32(2835).littleEndian) { bmpData.append(contentsOf: $0) }  // Vertical resolution
//        withUnsafeBytes(of: UInt32(0).littleEndian) { bmpData.append(contentsOf: $0) }  // Number of colors in palette
//        withUnsafeBytes(of: UInt32(0).littleEndian) { bmpData.append(contentsOf: $0) }  // Important colors
//        
//        // Pixel data
//        bmpData.append(Data(bytes: data, count: imageSize))
//        
//        return bmpData
//    }
//    
//    private static func convertToPDF(_ image: UIImage) -> Data? {
//        let pdfData = NSMutableData()
//        let pdfConsumer = CGDataConsumer(data: pdfData)!
//        
//        var mediaBox = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
//        
//        guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
//            return nil
//        }
//        
//        pdfContext.beginPage(mediaBox: &mediaBox)
//        pdfContext.draw(image.cgImage!, in: mediaBox)
//        pdfContext.endPage()
//        
//        return pdfData as Data
//    }
//    
//    private static func convertToSVG(_ image: UIImage) -> Data? {
//        guard let cgImage = image.cgImage else {
//            return nil
//        }
//        
//        let context = CIContext()
//        let filter = CIFilter(name: "CIPhotoEffectMono")
//        
//        guard let filter = filter else {
//            return nil
//        }
//        
//        filter.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
//        
//        guard let outputImage = filter.outputImage,
//              let monoImage = context.createCGImage(outputImage, from: outputImage.extent) else {
//            return nil
//        }
//        
//        // Basic SVG path generation
//        var svg = """
//        <?xml version="1.0" encoding="UTF-8" standalone="no"?>
//        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
//        <svg width="\(image.size.width)" height="\(image.size.height)" 
//             viewBox="0 0 \(image.size.width) \(image.size.height)"
//             xmlns="http://www.w3.org/2000/svg"
//             xmlns:xlink="http://www.w3.org/1999/xlink">
//        """
//        
//        // Add image as base64-encoded data
//        if let base64String = image.pngData()?.base64EncodedString() {
//            svg += "<image width=\"100%\" height=\"100%\" xlink:href=\"data:image/png;base64,\(base64String)\"/>"
//        }
//        
//        svg += "</svg>"
//        
//        return svg.data(using: .utf8)
//    }
//    
//    private static func convertToWebP(_ image: UIImage) -> Data? {
//        guard let data = image.pngData() else { return nil }
//        
//        let options: [CFString: Any] = [
//            kCGImageDestinationLossyCompressionQuality: 0.8,
//            kCGImageDestinationOptimizeColorForSharing: true
//        ]
//        
//        let mutableData = NSMutableData()
//        
//        guard let destination = CGImageDestinationCreateWithData(
//            mutableData,
//            "public.webp" as CFString,
//            1,
//            nil
//        ) else {
//            return nil
//        }
//        
//        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
//              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
//            return nil
//        }
//        
//        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
//        
//        guard CGImageDestinationFinalize(destination) else {
//            return nil
//        }
//        
//        return mutableData as Data
//    }
//    
//    private static func convertToRAW(_ image: UIImage) -> Data? {
//        guard let cgImage = image.cgImage else { return nil }
//        
//        let width = cgImage.width
//        let height = cgImage.height
//        let bitsPerComponent = 8
//        let bytesPerRow = width * 4
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
//        
//        guard let context = CGContext(data: nil,
//                                    width: width,
//                                    height: height,
//                                    bitsPerComponent: bitsPerComponent,
//                                    bytesPerRow: bytesPerRow,
//                                    space: colorSpace,
//                                    bitmapInfo: bitmapInfo) else {
//            return nil
//        }
//        
//        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
//        
//        var rawData = Data()
//        
//        // DNG Header
//        rawData.append("DNG\0".data(using: .ascii)!) // Magic number
//        
//        // Append width, height, and bits per component using withUnsafeBytes
//        withUnsafeBytes(of: UInt32(width).bigEndian) { rawData.append(contentsOf: $0) }
//        withUnsafeBytes(of: UInt32(height).bigEndian) { rawData.append(contentsOf: $0) }
//        withUnsafeBytes(of: UInt32(bitsPerComponent).bigEndian) { rawData.append(contentsOf: $0) }
//        
//        // Append pixel data
//        if let contextData = context.data {
//            rawData.append(Data(bytes: contextData, count: height * bytesPerRow))
//        }
//        
//        return rawData
//    }
//}
//
//// Main conversion view
//struct ConversionView: View {
//    @State private var selectedItems: [PhotosPickerItem] = []
//    @State private var selectedImages: [UIImage] = []
//    @State private var conversionItems: [ConversionItem] = []
//    @State private var selectedFormat = "PNG"
//    @State private var isConverting = false
//    @State private var showShareSheet = false
//    @Environment(\.dismiss) private var dismiss
//    
//    let formats = ["JPG", "PNG", "HEIC", "HEIF", "GIF", "TIFF", "BMP", "PDF", "SVG", "WEBP"]
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                // Image preview
//                ScrollView {
//                    if selectedImages.isEmpty {
//                        Text("Select images to convert")
//                            .foregroundColor(.gray)
//                            .padding()
//                    } else {
//                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
//                            ForEach(selectedImages.indices, id: \.self) { index in
//                                Image(uiImage: selectedImages[index])
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 100)
//                                    .cornerRadius(8)
//                            }
//                        }
//                        .padding()
//                    }
//                }
//                
//                // Format selector
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 10) {
//                        ForEach(formats, id: \.self) { format in
//                            Button(action: {
//                                selectedFormat = format
//                            }) {
//                                Text(format)
//                                    .padding(.horizontal, 16)
//                                    .padding(.vertical, 8)
//                                    .background(selectedFormat == format ? Color.blue : Color(.systemGray5))
//                                    .foregroundColor(selectedFormat == format ? .white : .primary)
//                                    .cornerRadius(20)
//                            }
//                        }
//                    }
//                    .padding()
//                }
//                
//                // Convert button
//                Button(action: convertImages) {
//                    if isConverting {
//                        ProgressView()
//                            .progressViewStyle(CircularProgressViewStyle())
//                    } else {
//                        Text("Convert")
//                            .fontWeight(.semibold)
//                    }
//                }
//                .disabled(selectedImages.isEmpty || isConverting)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(selectedImages.isEmpty ? Color.gray : Color.blue)
//                .foregroundColor(.white)
//                .cornerRadius(12)
//                .padding()
//                
//                PhotosPicker(selection: $selectedItems,
//                           matching: .images,
//                           photoLibrary: .shared()) {
//                    Text("Select More Images")
//                        .foregroundColor(.blue)
//                }
//            }
//            .navigationTitle("Convert Images")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    if !conversionItems.isEmpty {
//                        Button(action: { showShareSheet = true }) {
//                            Image(systemName: "square.and.arrow.up")
//                        }
//                    }
//                }
//            }
//        }
//        .onChange(of: selectedItems) { newItems in
//            loadSelectedImages(from: newItems)
//        }
//        .sheet(isPresented: $showShareSheet) {
//            if let firstItem = conversionItems.first,
//               let data = firstItem.convertedData {
//                ShareSheet(items: [data])
//            }
//        }
//    }
//    
//    private func loadSelectedImages(from items: [PhotosPickerItem]) {
//        Task {
//            var images: [UIImage] = []
//            for item in items {
//                if let data = try? await item.loadTransferable(type: Data.self),
//                   let image = UIImage(data: data) {
//                    images.append(image)
//                }
//            }
//            
//            await MainActor.run {
//                selectedImages.append(contentsOf: images)
//            }
//        }
//    }
//    private func convertImages() {
//        isConverting = true
//        
//        Task {
//            var newItems: [ConversionItem] = []
//            
//            for image in selectedImages {
//                let item = ConversionItem(
//                    originalImage: image,
//                    originalFormat: "unknown",
//                    targetFormat: selectedFormat
//                )
//                
//                // Fixed generic parameter inference issue
//                if let convertedData = await Task.detached(priority: .userInitiated) { () -> Data? in
//                    return ImageConverterService.convert(image: image, to: selectedFormat)
//                }.value {
//                    item.convertedData = convertedData
//                }
//                
//                newItems.append(item)
//            }
//            
//            await MainActor.run {
//                conversionItems = newItems
//                isConverting = false
//                if !newItems.isEmpty {
//                    showShareSheet = true
//                }
//            }
//        }
//    }
//}
//
//// Share sheet for converted images
//struct ShareSheet: UIViewControllerRepresentable {
//    let items: [Any]
//    
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        let controller = UIActivityViewController(
//            activityItems: items,
//            applicationActivities: nil
//        )
//        return controller
//    }
//    
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
//}
//
//// History view for showing conversion history
//struct ConversionHistoryView: View {
//    @Binding var items: [ConversionItem]
//    
//    var body: some View {
//        List {
//            ForEach(items) { item in
//                HStack {
//                    Image(uiImage: item.originalImage)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 50, height: 50)
//                        .cornerRadius(8)
//                    
//                    VStack(alignment: .leading) {
//                        Text("Converted to \(item.targetFormat)")
//                            .font(.headline)
//                        Text(item.date, style: .relative)
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                }
//            }
//        }
//    }
//}
//struct ImportButton: View {
//    let icon: String
//    let title: String
//    
//    var body: some View {
//        HStack {
//            Image(systemName: icon)
//                .frame(width: 30)
//            
//            Text(title)
//            
//            Spacer()
//            
//            Image(systemName: "chevron.right")
//                .foregroundColor(.gray)
//        }
//        .padding()
//        .background(Color(.systemBackground))
//    }
//}
//// Main content view
//struct ContentView: View {
//    @State private var showConversion = false
//    @State private var conversionHistory: [ConversionItem] = []
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 20) {
//                Text("Image Converter")
//                    .font(.largeTitle)
//                    .padding(.top)
//                
//                // Import buttons
//                VStack(spacing: 1) {
//                    Button(action: { showConversion = true }) {
//                        ImportButton(icon: "photo", title: "From Gallery")
//                    }
//                    
//                    Button(action: { showConversion = true }) {
//                        ImportButton(icon: "folder", title: "From Files")
//                    }
//                }
//                .background(Color(.systemBackground))
//                .cornerRadius(12)
//                .padding(.horizontal)
//                
//                // History section
//                Text("Convert History")
//                    .font(.title2)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal)
//                
//                if conversionHistory.isEmpty {
//                    Text("No conversions yet")
//                        .foregroundColor(.gray)
//                        .padding()
//                } else {
//                    ConversionHistoryView(items: $conversionHistory)
//                }
//                
//                Spacer()
//            }
//            .sheet(isPresented: $showConversion) {
//                ConversionView()
//            }
//        }
//    }
//}
//



import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import MediaToolSwift

// File conversion state
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import MediaToolSwift

// File conversion state
enum ConversionState {
    case idle
    case converting
    case completed(URL)
    case error(String)
}

// Supported output formats
enum OutputFormat: String, CaseIterable {
    // Standard formats
    case png = "PNG"
    case jpg = "JPEG"
    case heic = "HEIC"
    case heif = "HEIF"
    case heif10bit = "HEIF 10-bit"
    case heics = "HEICS"
    case gif = "GIF"
    case tiff = "TIFF"
    case bmp = "BMP"
    case webp = "WebP"
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpg: return "jpg"
        case .heic: return "heic"
        case .heif, .heif10bit: return "heif"
        case .heics: return "heics"
        case .gif: return "gif"
        case .tiff: return "tiff"
        case .bmp: return "bmp"
        case .webp: return "webp"
        }
    }
    
    var utType: UTType? {
        switch self {
        case .png: return .png
        case .jpg: return .jpeg
        case .heic: return .heic
        case .heif, .heif10bit: return UTType("public.heif")
        case .heics: return UTType("public.heics")
        case .gif: return .gif
        case .tiff: return .tiff
        case .bmp: return .bmp
        case .webp: return UTType("org.webmproject.webp")
        }
    }
    
    // Check if format supports animation
    var supportsAnimation: Bool {
        switch self {
        case .gif, .png, .heics, .webp:
            return true
        default:
            return false
        }
    }
}

class FileConverterViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedPDFURL: URL?
    @Published var outputFormat: OutputFormat = .png
    @Published var conversionState: ConversionState = .idle
    @Published var conversionProgress: Double = 0.0
    @Published var isAnimated: Bool = false
    @Published var preserveAnimation: Bool = true
    
    func convertFile() {
        guard let sourceURL = createTemporarySourceURL() else {
            DispatchQueue.main.async {
                self.conversionState = .error("Failed to create source file")
            }
            return
        }
        
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(outputFormat.fileExtension)
        
        Task { @MainActor in
            do {
                conversionState = .converting
                
                let info = try await ImageTool.convert(
                    source: sourceURL,
                    destination: destinationURL,
                    settings: .init(
                        format: outputFormat == .jpg ? .jpeg :
                               outputFormat == .heic ? .heic :
                               outputFormat == .heif || outputFormat == .heif10bit ? .heic :
                               outputFormat == .heics ? .heics :
                               outputFormat == .gif ? .gif :
                               outputFormat == .tiff ? .tiff :
                            outputFormat == .bmp ? .bmp : .png,
                        size: .fit(.hd),
                        edit: []
                    )
                )
                
                conversionState = .completed(destinationURL)
                conversionProgress = 1.0
            } catch {
                conversionState = .error(error.localizedDescription)
            }
        }
    }
    
    private func createTemporarySourceURL() -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        if let image = selectedImage {
            if let data = outputFormat == .jpg ? image.jpegData(compressionQuality: 1.0) : image.pngData() {
                try? data.write(to: tempURL)
                return tempURL
            }
        } else if let pdfURL = selectedPDFURL {
            try? FileManager.default.copyItem(at: pdfURL, to: tempURL)
            return tempURL
        }
        return nil
    }
    
    func checkForAnimation(at url: URL) {
        Task { @MainActor in
            if let type = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
               let utType = UTType(type) {
                isAnimated = utType == .gif || type.contains("webp") || type.contains("heics")
            }
        }
    }
}
struct FormatSelectionView: View {
    @Binding var selectedFormat: OutputFormat
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Output Format")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(OutputFormat.allCases, id: \.self) { format in
                        Button(action: { selectedFormat = format }) {
                            Text(format.rawValue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedFormat == format ?
                                    Color.blue : Color.blue.opacity(0.1)
                                )
                                .foregroundColor(
                                    selectedFormat == format ?
                                    Color.white : Color.blue
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Animation options view
struct AnimationOptionsView: View {
    @Binding var preserveAnimation: Bool
    let isAnimated: Bool
    let targetFormatSupportsAnimation: Bool
    
    var body: some View {
        if isAnimated && targetFormatSupportsAnimation {
            Toggle("Preserve Animation", isOn: $preserveAnimation)
                .padding(.horizontal)
        }
    }
}
// Main View
// File Selection Buttons View
struct FileSelectionButtons: View {
    let onImagePicker: () -> Void
    let onDocumentPicker: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onImagePicker) {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                    Text("Select Image")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button(action: onDocumentPicker) {
                VStack {
                    Image(systemName: "doc")
                        .font(.system(size: 30))
                    Text("Select File")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

// Preview View
struct PreviewView: View {
    let image: UIImage?
    let hasPDF: Bool
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
            } else if hasPDF {
                Image(systemName: "doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }
        }
    }
}

// Convert Button View
struct ConvertButtonView: View {
    let isConverting: Bool
    let isDisabled: Bool
    let onConvert: () -> Void
    
    var body: some View {
        Button(action: onConvert) {
            if isConverting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("Convert")
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .padding(.horizontal)
        .disabled(isDisabled)
    }
}

// Status View
struct StatusView: View {
    let conversionState: ConversionState
    let onShare: (URL) -> Void
    
    var body: some View {
        switch conversionState {
        case .completed(let url):
            Button("Share Converted File") {
                onShare(url)
            }
            .foregroundColor(.blue)
        case .error(let message):
            Text(message)
                .foregroundColor(.red)
        default:
            EmptyView()
        }
    }
}

// Main Content View
struct ContentView: View {
    @StateObject private var viewModel = FileConverterViewModel()
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    @State private var showShareSheet = false
    @State private var convertedFileURL: URL?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // File Selection
                    FileSelectionButtons(
                        onImagePicker: { showImagePicker = true },
                        onDocumentPicker: { showDocumentPicker = true }
                    )
                    
                    // Preview
                    PreviewView(
                        image: viewModel.selectedImage,
                        hasPDF: viewModel.selectedPDFURL != nil
                    )
                    
                    // Format Selection
                    FormatSelectionView(selectedFormat: $viewModel.outputFormat)
                    
                    // Animation Options
                    AnimationOptionsView(
                        preserveAnimation: $viewModel.preserveAnimation,
                        isAnimated: viewModel.isAnimated,
                        targetFormatSupportsAnimation: viewModel.outputFormat.supportsAnimation
                    )
                    
                    // Convert Button
                    ConvertButtonView(
                        isConverting: false,
                        isDisabled: viewModel.selectedImage == nil && viewModel.selectedPDFURL == nil,
                        onConvert: viewModel.convertFile
                    )
                    
                    // Status
                    StatusView(
                        conversionState: viewModel.conversionState,
                        onShare: { url in
                            convertedFileURL = url
                            showShareSheet = true
                        }
                    )
                    
                    Spacer()
                }
            }
            .navigationTitle("File Converter")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $viewModel.selectedImage)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(url: $viewModel.selectedPDFURL)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = convertedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}
// Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var url: URL?
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.url = url
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
