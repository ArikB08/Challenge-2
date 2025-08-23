//
//  SettingsView.swift
//  Challenge 2
//
//  Created by Arik Bagchi on 16/8/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var faceNum: Double = 4
    @State private var passAcc: Double = 75
    
    var body: some View {
        VStack {
            Text("No. of faces before unlock: \(faceNum, specifier: "%.1f")") // how to remove the dp
            Slider(value: $faceNum, in: 0...10, step: 1)
            Text("")
            Text("") // How do you make space between the two sliders 😭
            Text("")
            Text("")
            Text("Passing Accuracy: \(passAcc, specifier: "%.1f")%")
            Slider(value: $passAcc, in: 0...100, step: 1) // can change the step to have
        }
    }
}

#Preview {
    SettingsView()
}
