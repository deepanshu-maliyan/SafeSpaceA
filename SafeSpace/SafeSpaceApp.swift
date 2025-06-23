//
//  SafeSpaceApp.swift
//  SafeSpace
//
//  Created by Devashish Upadhyay on 23/06/25.
//

import SwiftUI

@main
struct SafeSpaceApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}
