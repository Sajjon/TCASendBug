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
let log = Logger()


@Reducer
struct App {
	
	func proceedToNextSlowTask(state: inout State) -> Effect<Action> {
		state.status = .requestInFlight
		state.destination = nil // <-- COMMENTING OUT THIS (which we dont) "fixes" the bug. As in `run` below does not get cancelled
		return .run { send in
			await slowTask(name: "App")
			log.notice("`await send(.successfullyFinished)` is about to get called...")
			await send(.successfullyFinished)
			log.notice("`await send(.successfullyFinished)` called? Ever received???")
		}
	}
	
	
	var body: some ReducerOf<App> {
		Reduce { state, action in
			switch action {
			case .destination(.presented(.modal(.done))):
				return proceedToNextSlowTask(state: &state)
			case .successfullyFinished:
				log.notice("Successfully recevied `successfullyFinished`! No bug!")
				state.destination = nil
				state.status = .successfullyFinished
				return .none
			default: return .none
			}
		}
		.ifLet(\.$destination, action: /Action.destination) {
			Destination()
		}
	}
	
	struct State: Sendable, Hashable {
		@PresentationState
		var destination: Destination.State?
		enum Status: String, Sendable, Hashable {
			case idle, requestInFlight, successfullyFinished
		}
		var status: Status = .idle
		init() {
			log.debug("App start")
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
		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack {
					Text("APP")
					switch viewStore.status {
					case .idle: 
						Text("Idle")
					case .requestInFlight:
						ProgressView().controlSize(.extraLarge)
						Text("Request that might never finish due to send-bug is running...")
					case .successfullyFinished:
						Text("Successfully finished:")
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

func slowTask(name: String) async {
	log.info("Slow task - '\(name)' START")
	await Task {
		_ = (0...10000).map { _ in
			Curve25519.Signing.PrivateKey().publicKey
		}
	}.value
	log.info("Slow task - '\(name)' DONE")
}

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
			Text("MODAL")
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
