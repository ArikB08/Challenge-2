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
        Tab("Unlock now", systemImage: "faceid") {
        FaceIDView()
        }
        Tab("Settings", systemImage: "gear") {
        SettingsView()
        }
        }
    }
}

#Preview {
    HomePage()
}
