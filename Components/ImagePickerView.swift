//
//  ImagePickerView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/11/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct ImagePickerView: View {
    @Binding var imageData: Data?
    @State private var selectedImage: PhotosPickerItem?
    @State private var isImagePickerPresented = false
    @State private var showCameraOption = false
    @State private var showPhotoPicker = false
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    var body: some View {
        VStack {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    )
                    .overlay(
                        Button(action: {
                            self.imageData = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.7)))
                                .offset(x: 6, y: -6)
                        }
                        .padding(4),
                        alignment: .topTrailing
                    )
            } else {
                Button(action: {
                    showCameraOption = true
                }) {
                    VStack {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                        
                        Text(isEnglishLanguage ? "Add Photo" : "Зураг нэмэх")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    )
                }
            }
        }
        .confirmationDialog(
            isEnglishLanguage ? "Select Photo" : "Зураг сонгох",
            isPresented: $showCameraOption,
            titleVisibility: .visible
        ) {
            Button(isEnglishLanguage ? "Take Photo" : "Камер") {
                isImagePickerPresented = true
                showCameraOption = false
            }
            
            Button(isEnglishLanguage ? "Choose From Library" : "Зургийн сангаас сонгох") {
                showPhotoPicker = true
                showCameraOption = false
            }
            
            Button(isEnglishLanguage ? "Cancel" : "Цуцлах", role: .cancel) {
                showCameraOption = false
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            CameraPickerView(imageData: $imageData)
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedImage,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedImage) { _, newValue in
            Task {
                do {
                    if let newValue = newValue {
                        if let data = try? await newValue.loadTransferable(type: Data.self) {
                            DispatchQueue.main.async {
                                imageData = data
                                print("Successfully loaded image data")
                            }
                        } else {
                            print("Failed to load image data: format may be unsupported")
                        }
                    }
                } catch {
                    print("Error loading image: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Resize image to reduce storage requirements
                let maxSize: CGFloat = 1024
                let scale = min(maxSize/image.size.width, maxSize/image.size.height)
                let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                
                UIGraphicsBeginImageContext(newSize)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // Convert to JPEG data with moderate compression
                if let resizedImage = resizedImage,
                   let jpegData = resizedImage.jpegData(compressionQuality: 0.7) {
                    parent.imageData = jpegData
                }
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    @State var imageData: Data? = nil
    
    return ImagePickerView(imageData: $imageData)
        .padding()
} 
