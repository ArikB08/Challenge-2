//
//  SwiftUIView.swift
//  Challenge 2
//
//  Created by Arik Bagchi on 16/8/25.
//

import SwiftUI

struct HomePage: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
        ContentView()
        }
        Tab("Settings", systemImage: "gear") {
        SettingsView()
        }
        Tab("Unlock now", systemImage: "faceid") {
        FaceIDView()
        }
        
        }
    }
}

#Preview {
    HomePage()
}
