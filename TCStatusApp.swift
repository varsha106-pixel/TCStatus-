//
//  TCStatusApp.swift
//  TCStatus
//
//  Created by Varsha Jawadi on 6/16/25.
//

import SwiftUI

@main
struct TCStatusApp: App {
    @StateObject private var sharedData = SharedData()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedData) 
        }
    }
}
