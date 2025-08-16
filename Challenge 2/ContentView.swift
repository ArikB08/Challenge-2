//
//  ContentView.swift
//  Challenge 2
//
//  Created by Arik Bagchi on 2/8/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "faceid")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundStyle(.tint)
                .padding(.bottom)
            Text("Silly face app lock")
            Button {
                
            } label: {
                Text("Go to app")
            }
            .buttonStyle(BorderedProminentButtonStyle())
            Button {
                
            } label: {
                Text("Unlock now")
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
