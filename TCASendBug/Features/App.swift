//
//  App.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct App {
	struct State: Sendable, Hashable {}
	enum Action: Sendable, Equatable {}
	struct View: SwiftUI.View {
		let store: StoreOf<App>
		var body: some SwiftUI.View {
			Text("Impl me")
		}
	}
	var body: some ReducerOf<App> {
		EmptyReducer()
	}
}
