import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var ejectionFractionText: String = ""
    @State private var coordinates: [String] = []
    @State private var isShowingPicker = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer()

                    Text("Video File Transfer and Analysis")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    Button(action: {
                        isShowingPicker = true
                    }) {
                        Text("Select and Send Video")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#FEBD2B"))
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                    .padding(.horizontal, 20)
                    .sheet(isPresented: $isShowingPicker) {
                        VideoPicker { videoUrl in
                            if let videoUrl = videoUrl {
                                FileTransferIOS.shared.sendVideoMultipart(videoUrl: videoUrl) { result in
                                    switch result {
                                    case .success(let json):
                                        parseResponse(json)
                                    case .failure(let error):
                                        self.ejectionFractionText = "Error: \(error.localizedDescription)"
                                        self.coordinates = []
                                    }
                                }
                            }
                        }
                    }

                    if !ejectionFractionText.isEmpty {
                        Text(ejectionFractionText)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#FEBD2B"))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                    }

                    ForEach(Array(coordinates.enumerated()), id: \.element) { index, coordinate in
                        Text("位点\(index + 1): \(coordinate)")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#FEBD2B"))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                    }

                    Spacer()
                    
                    Button("Clear Data") {
                        self.ejectionFractionText = ""
                        self.coordinates.removeAll()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
    }

    func parseResponse(_ response: [String: Any]) {
        if let ejectionFraction = response["ejectionFraction"] as? Int,
           let pacingRequired = response["pacingRequired"] as? Bool {
            self.ejectionFractionText = "Ejection Fraction: \(ejectionFraction)\(pacingRequired ? " 需起搏" : "")"
        }

        if let coordinatesArray = response["coordinates"] as? [[String: String]] {
            self.coordinates = coordinatesArray.enumerated().map { index, coord in
                let x = coord["x"] ?? "0"
                let y = coord["y"] ?? "0"
                return "(\(x), \(y))"
            }
        }
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
