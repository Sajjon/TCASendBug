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
	typealias Root = App
	var body: some SwiftUI.Scene {
		WindowGroup {
			if !_XCTIsTesting {
				Root.View(
					store: Store(
						initialState: Root.State()
					) {
						Root()
					}
				)
				.buttonStyle(.borderedProminent)
			} else {
				Text("Running tests")
			}
		}
	}
}
