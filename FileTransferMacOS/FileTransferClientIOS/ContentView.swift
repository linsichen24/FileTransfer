//
//  ContentView.swift
//  FileTransferClientIOS
//
//  Created by Sichen Lin on 10/26/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var message: String = ""
    @State private var isShowingPicker = false

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                isShowingPicker = true
            }) {
                Text("Select and Send Video to Mac")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $isShowingPicker) {
                VideoPicker { videoUrl in
                    if let videoUrl = videoUrl {
                        FileTransferIOS.shared.sendVideoMultipart(videoUrl: videoUrl) { result in
                            switch result {
                            case .success(let message):
                                self.message = message
                            case .failure(let error):
                                self.message = "Error sending video: \(error.localizedDescription)"
                            }
                        }
                    }
                }
            }

            Text(message)
                .padding()
        }
        .padding()
    }
}

struct VideoPicker: UIViewControllerRepresentable {
    var onVideoPicked: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(onVideoPicked: onVideoPicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var onVideoPicked: (URL?) -> Void

        init(onVideoPicked: @escaping (URL?) -> Void) {
            self.onVideoPicked = onVideoPicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true, completion: nil)
            onVideoPicked(info[.mediaURL] as? URL)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
            onVideoPicked(nil)
        }
    }
}

#Preview {
    ContentView()
}
