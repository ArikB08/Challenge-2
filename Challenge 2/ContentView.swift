//
//  ContentView.swift
//  Challenge 2
//
//  Created by Arik Bagchi on 2/8/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack{
                Image(systemName: "faceid")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.tint)
                    .padding(.bottom)
                Text("Silly face app lock")
                NavigationLink(destination: HomePage()){
                    Text("Go to app")
                }
                .buttonStyle(BorderedProminentButtonStyle())

                NavigationLink(destination: FaceIDView()) {
                    Text("Unlock now")
                }
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .padding()
        }
    }


#Preview {
    ContentView()
}
