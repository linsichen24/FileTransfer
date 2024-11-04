//
//  FileTransferMacOS.swift
//  FileTransferMacOS
//
//  Created by Sichen Lin on 10/26/24.
//

import Cocoa
import Network

class FileTransferMacOS: NSObject {
    static let shared = FileTransferMacOS()
    var listener: NWListener?

    func startVideoReceiver(completion: @escaping (Result<String, Error>) -> Void) {
        do {
            listener = try NWListener(using: .tcp, on: 8080)
        } catch {
            completion(.failure(error))
            return
        }

        listener?.newConnectionHandler = { newConnection in
            newConnection.start(queue: .main)
            newConnection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024 * 10) { data, _, _, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                    return
                }

                let timestamp = Int(Date().timeIntervalSince1970)
                let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

                // 从数据中获取原始文件名，如果没有就用默认名
                let originalName = "receivedVideo"
                let filename = "\(originalName)-\(timestamp).mp4"
                let fileURL = downloadsDir.appendingPathComponent(filename)

                do {
                    try data.write(to: fileURL)
                    completion(.success("Video saved to \(fileURL.path)"))
                    self.sendResponse(to: newConnection, responseNumber: Int.random(in: 1...100))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        listener?.start(queue: .main)
    }

    private func sendResponse(to connection: NWConnection, responseNumber: Int) {
        let response = ["responseNumber": responseNumber]
        do {
            let responseData = try JSONSerialization.data(withJSONObject: response, options: [])
            connection.send(content: responseData, completion: .contentProcessed { error in
                if let error = error {
                    print("Failed to send response: \(error.localizedDescription)")
                } else {
                    print("Response sent successfully")
                }
            })
        } catch {
            print("Failed to serialize response: \(error.localizedDescription)")
        }
    }
}

