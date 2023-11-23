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
	
	// ‼️‼️‼️‼️‼️‼️‼️‼️‼️
	// Here is the bug! This reducer (`App`) never received the action `successfullyFinished`, even though
	// we send it in `run` below, after `await slowTask` has finished.
	//
	// If we skip setting `state.modal = ni` (skip dismissing the modal (we REALLY want to dismiss it)),
	// then no bug. Or the `slowTask` is not that slow, then it works. But this is a small demo, in real life
	// the `slowTask` is a network request of variable speed, so we cannot control how slow it is.
	//
	// And our UX dictactes that we must dismiss the modal. So neither of the "fixes" is acceptable.
	// ‼️‼️‼️‼️‼️‼️‼️‼️‼️
	func proceedToNextSlowTask(state: inout State) -> Effect<Action> {
		state.status = .requestInFlight
		state.modal = nil // 💡 <-- COMMENTING OUT THIS ✅🐞 NO BUG
		return .run { send in
			await slowTask(name: "App", iterations: 10_000) // 💡<--- OR IF YOU LOWER `iteration` to e.g `500` ✅🐞 NO BUG
			log.notice("`await send(.successfullyFinished)` is about to get called...")
			await send(.successfullyFinished)
			log.notice("`await send(.successfullyFinished)` called? Ever received???")
		}
	}
	
	var body: some ReducerOf<App> {
		Reduce { state, action in
			switch action {
			case .modal(.presented(.done)):
				return proceedToNextSlowTask(state: &state)
			case .successfullyFinished:
				log.notice("Successfully recevied `successfullyFinished`! No bug!")
				state.modal = nil
				state.status = .successfullyFinished
				return .none
			default: return .none
			}
		}
		.ifLet(\.$modal, action: /Action.modal) {
			Modal()
		}
	}
	
	struct State: Sendable, Hashable {
		@PresentationState
		var modal: Modal.State?
		enum Status: String, Sendable, Hashable {
			case idle, requestInFlight, successfullyFinished
		}
		var status: Status = .idle
		init() {
			self.modal = .init()
		}
	}
	enum Action: Sendable, Equatable {
		case modal(PresentationAction<Modal.Action>)
		case successfullyFinished
	}

	struct View: SwiftUI.View {
		let store: StoreOf<App>
		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack {
					Text("APP FEATURE")
						.font(.largeTitle)
					Spacer()
					switch viewStore.status {
					case .idle:
						Text("Idle")
					case .requestInFlight:
						ProgressView().controlSize(.extraLarge)
						Text("Request that might never finish due to send-bug is running...")
					case .successfullyFinished:
						Text("Successfully finished")
					}
					Spacer()
				}
				.sheet(
					store: store.scope(state: \.$modal, action: { .modal($0) }),
					content: {
						Modal.View(store: $0)
					}
				)
			}
		}
	}
	
}

func slowTask(name: String, iterations: Int = 10_000) async {
	log.info("Slow task - '\(name)' START")
	await Task {
		_ = (0...iterations).map { _ in
			Curve25519.Signing.PrivateKey().publicKey
		}
	}.value
	log.info("Slow task - '\(name)' DONE")
}
