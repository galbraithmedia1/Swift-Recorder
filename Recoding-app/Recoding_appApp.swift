//
//  Recoding_appApp.swift
//  Recoding-app
//
//  Created by Taylor Galbraith on 12/28/24.
//

import SwiftUI

@main
struct AudioRecorderApp: App {
    var body: some Scene {
        WindowGroup {
            RecordingPermissionView()
        }
    }
}
