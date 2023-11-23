//
//  TCASendBugApp.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-22.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCASendBugApp: SwiftUI.App {
	var body: some SwiftUI.Scene {
		WindowGroup {
			if !_XCTIsTesting {
				App.View(
					store: Store(
						initialState: App.State()
					) {
						App()
							._printChanges()
					}
				)
				.buttonStyle(.borderedProminent)
			} else {
				Text("Running tests")
			}
		}
	}
}
