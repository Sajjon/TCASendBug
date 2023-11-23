//
//  ModalFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct Modal {
	struct State: Sendable, Hashable {}
	enum Action: Sendable, Equatable {
		case onTask
		case done
	}
	struct View: SwiftUI.View {
		let store: StoreOf<Modal>
		var body: some SwiftUI.View {
			VStack {
				Text("MODAL FEATURE")
					.font(.largeTitle)
					.foregroundColor(.white)
				Spacer()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.blue)
			.task {
				await store.send(.onTask).finish()
			}
		}
	}
	var body: some ReducerOf<Modal> {
		Reduce { state, action in
			switch action {
			case .onTask:
				return .run { send in
					await slowTask(name: "From MODAL")
					await send(.done)
				}
			default: return .none
			}
		}
	}
}
