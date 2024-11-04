// FileTransferIOS.swift
// FileTransferMacOS
// Created by Sichen Lin on 10/26/24.

import UIKit
import UniformTypeIdentifiers

enum FileTransferError: Error {
    case fileIOError(description: String)
    case networkError(description: String)
}

class FileTransferIOS: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    static let shared = FileTransferIOS()
    var completion: ((Result<URL, Error>) -> Void)?

    let serverURL = "http://172.20.10.117:8080/receive-video"

    func selectVideo(viewController: UIViewController, completion: @escaping (Result<URL, Error>) -> Void) {
        self.completion = completion
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.delegate = self
        viewController.present(picker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let videoUrl = info[.mediaURL] as? URL {
            self.completion?(.success(videoUrl))
        } else {
            self.completion?(.failure(FileTransferError.fileIOError(description: "Failed to select video")))
        }
    }

    func sendVideoMultipart(videoUrl: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: serverURL) else {
            completion(.failure(FileTransferError.networkError(description: "Invalid URL")))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let filename = videoUrl.lastPathComponent
        let mimeType = "video/mp4"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        do {
            let videoData = try Data(contentsOf: videoUrl)
            body.append(videoData)
        } catch {
            completion(.failure(FileTransferError.fileIOError(description: "Failed to read video data")))
            return
        }
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200, let data = data else {
                completion(.failure(FileTransferError.networkError(description: "Failed to upload video")))
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let responseNumber = json["responseNumber"] as? Int {
                    completion(.success("Video uploaded successfully! Response Number: \(responseNumber)"))
                } else {
                    completion(.failure(FileTransferError.networkError(description: "Invalid server response")))
                }
            } catch {
                completion(.failure(FileTransferError.networkError(description: "Failed to parse server response")))
            }
        }
        task.resume()
    }
}
