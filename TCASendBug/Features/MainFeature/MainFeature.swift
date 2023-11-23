//
//  MainFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct Main: Sendable, Reducer {
	struct View: SwiftUI.View {
		let store: StoreOf<Main>
		var body: some SwiftUI.View {
			VStack {
				Text("SUCCESS!")
					.font(.headline)
				
				Text("As in, NO bug.")
			}
			.foregroundStyle(Color.white)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.green)
		}
	}
	struct State: Sendable, Hashable {}
	enum Action: Sendable, Hashable {}
	var body: some ReducerOf<Self> {
		EmptyReducer()
	}
}
