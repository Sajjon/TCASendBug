//
//  App.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import CryptoKit
import OSLog

@Reducer
struct App {
	
	var body: some ReducerOf<App> {
		Reduce { state, action in
			switch action {
			case .destination(.presented(.modal(.done))):
				return proceedToNextSlowTask(state: &state)
			case .successfullyFinished:
				state.successfullyFinished = true
				return .none
			default: return .none
			}
		}
	}
	
	func proceedToNextSlowTask(state: inout State) -> Effect<Action> {
		state.destination = nil
		return .run { send in
			try! await Task.sleep(for: .seconds(2))
			await send(.successfullyFinished)
		}
	}
	
	struct State: Sendable, Hashable {
		@PresentationState
		var destination: Destination.State?
		var successfullyFinished = false
		init() {
			self.destination = .modal(.init())
		}
	}
	enum Action: Sendable, Equatable {
		case destination(PresentationAction<Destination.Action>)
		case successfullyFinished
	}
	struct Destination: Reducer {
		enum State: Sendable, Hashable {
			case modal(Modal.State)
		}

		enum Action: Sendable, Equatable {
			case modal(Modal.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.modal, action: /Action.modal) {
				Modal()
			}
		}
	}
	struct View: SwiftUI.View {
		let store: StoreOf<App>
		struct ViewState: Equatable { let successfullyFinished: Bool }
		var body: some SwiftUI.View {
			WithViewStore(store, observe: { ViewState(successfullyFinished: $0.successfullyFinished) }) { viewStore in
				VStack {
					Text("APP")
					if viewStore.successfullyFinished {
						Text("Successfully finished:")
					} else {
						Text("Has NOT finished yet - OR failed.")
					}
				}
					.sheet(
						store: store.scope(state: \.$destination, action: { .destination($0) }),
						state: /App.Destination.State.modal,
						action: App.Destination.Action.modal,
						content: {
							Modal.View(store: $0)
						}
					)
			}
		}
	}
	
}

let log = Logger()

func slowTask(name: String) async {
	log.info("Slow task - '\(name)' START")
	await Task {
		_ = (0...50000).map { _ in
			Curve25519.Signing.PrivateKey().publicKey
		}
	}.value
	log.info("Slow task - '\(name)' DONE")
}

@Reducer
struct Modal {
	struct State: Sendable, Hashable {}
	enum Action: Sendable, Equatable {
		case done
	}
	struct View: SwiftUI.View {
		let store: StoreOf<Modal>
		var body: some SwiftUI.View {
			Text("MODAL")
				.task {
					await slowTask(name: "From MODAL")
					store.send(.done)
				}
		}
	}
	var body: some ReducerOf<Modal> {
		EmptyReducer()
	}
}
