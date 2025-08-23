//
//  SettingsView.swift
//  Challenge 2
//
//  Created by Arik Bagchi on 16/8/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var faceNum: Double = 4
    
    var body: some View {
        VStack {
            Text("No. of faces before unlock")
            Slider(value: $faceNum, in: 0...10, step: 1)
        }
    }
}

#Preview {
    SettingsView()
}
