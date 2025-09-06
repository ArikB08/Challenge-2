//
//  Models.swift
//  Challenge 2
//
//  Created by Lai Hong Yu on 9/6/25.
//

import Foundation
import FamilyControls
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    @Published var status = 0
    
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                DispatchQueue.main.async {
                    self.status = 1
                }
                print("Authorization granted")
            } catch {
                print("Authorization failed: \(error)")
            }
        }
    }
}
