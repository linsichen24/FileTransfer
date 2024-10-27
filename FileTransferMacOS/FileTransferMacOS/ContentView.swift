//
//  ContentView.swift
//  FileTransferMacOS
//
//  Created by Sichen Lin on 10/26/24.
//

import SwiftUI

struct ContentView: View {
    @State private var message: String = "Waiting for video..."

    var body: some View {
        VStack(spacing: 20) {
            Text("Mac Video Receiver")
                .font(.largeTitle)
                .padding()

            Button(action: {
                FileTransferMacOS.shared.startVideoReceiver { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let message):
                            self.message = message
                        case .failure(let error):
                            self.message = "Error receiving video: \(error.localizedDescription)"
                        }
                    }
                }
            }) {
                Text("Start Receiving Video")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Text(message)
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
