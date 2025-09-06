//
//  SettingsView.swift
//  Challenge 2
//
//  Created by Arik Bagchi on 16/8/25.
//

import SwiftUI
import AppIntents
import IntentsUI
struct CheckLockIntent: AppIntent {
    static let title: LocalizedStringResource = "Check if apps can unlock"
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> & OpensIntent {
        let isAppUnlocked = UserDefaults.standard.bool(forKey: "isAppUnlocked")
        if isAppUnlocked {
            UserDefaults.standard.set(false, forKey: "isAppUnlocked")
            return .result(value: true)
        } else {
            return .result(value: false, opensIntent: OpenMyAppIntent())
        }
    }
}


struct OpenMyAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open App"
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        
        return .result()
    }
}

struct SettingsView: View {
    @AppStorage("isAppUnlocked") private var isAppUnlocked: Bool = false
    
    @AppStorage("passingAccuracy") private var passAcc: Double = 75
    @State var appsPickerPresented = false
    
    @StateObject var model = ScreenTimeManager()
    func askForPermission() async {
        do {
            model.requestAuthorization()
        } catch {
            print(error.localizedDescription)
        }
    }
   
    var body: some View {
        VStack{
          
            Text("Passing Accuracy: \(passAcc, specifier: "%.1f")%")
            Slider(value: $passAcc, in: 0...100)
            
            
        }
        

    }
}

#Preview {
    SettingsView()
}
