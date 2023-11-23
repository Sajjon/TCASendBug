//
//  AccountRecoveryScanInProgressFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//


import Foundation
import SwiftUI
import ComposableArchitecture

// MARK: - AccountRecoveryScanInProgress
public struct AccountRecoveryScanInProgress: Sendable, FeatureReducer {
	
	public struct View: SwiftUI.View {
		public let store: StoreOf<AccountRecoveryScanInProgress>
		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack {
					Text("AccountRecoveryScanInProgress")
					switch viewStore.status {
					case .new:
						Button("Start") {
							store.send(.view(.start))
						}
					case .scanningNetworkForActiveAccounts:
						ProgressView()
					default: Text("`\(viewStore.status.rawValue)`")
					}
				}
				.destinations(with: store)
			}
		}
	}
	
	public struct State: Sendable, Hashable {
		public enum Status: String, Sendable, Hashable {
			case new
			case derivingPublicKeys
			case scanningNetworkForActiveAccounts
		}

		public var status: Status = .new
	
		@PresentationState
		public var destination: Destination.State? 
		{
			didSet {
				if case .some(.derivePublicKeys) = destination {
					self.status = .derivingPublicKeys
				}
			}
		}

		public init() {
			
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case start
		case continueTapped
	}
	
	public enum InternalAction: Sendable, Equatable {
		case extremelyImportantInternalActionChangingState
	}
	
	public enum DelegateAction: Sendable, Equatable {
		case complete
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case derivePublicKeys(DerivePublicKeys.State)
		}

		public enum Action: Sendable, Equatable {
			case derivePublicKeys(DerivePublicKeys.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.derivePublicKeys, action: /Action.derivePublicKeys) {
				DerivePublicKeys()
			}
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	
	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .extremelyImportantInternalActionChangingState:
			return .send(.delegate(.complete))
		}
	}


	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .start:
			state.destination = .derivePublicKeys(.init())
			return .none

		case .continueTapped:
			return .send(.delegate(.complete))
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .derivePublicKeys(.delegate(.completed)):
			return scanOnLedger(state: &state)
		default: return .none
		}
	}
}


extension AccountRecoveryScanInProgress {
	private func scanOnLedger(state: inout State) -> Effect<Action> {
		state.destination = nil
		state.status = .scanningNetworkForActiveAccounts

		return .run { send in
			// ‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
			// ‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
			// ‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
			// ‼️‼️‼️‼️‼️‼️‼️ 		WHAT WE DO HERE	   ‼️‼️‼️‼️‼️‼️‼️‼️‼️
			// ‼️‼️‼️‼️‼️‼️‼️		TRIGGERS THE BUG   ‼️‼️‼️‼️‼️‼️‼️‼️‼️
			// ‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
			// ‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
			try! await Task.sleep(for: .seconds(2)) // CRASH!
			await send(.internal(.extremelyImportantInternalActionChangingState))
		}
	}

}


private extension StoreOf<AccountRecoveryScanInProgress> {
	var destination: PresentationStoreOf<AccountRecoveryScanInProgress.Destination> {
		func scopeState(state: State) -> PresentationState<AccountRecoveryScanInProgress.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AccountRecoveryScanInProgress>) -> some View {
		let destinationStore = store.destination
		return derivingPublicKeys(with: destinationStore)
	}

	private func derivingPublicKeys(with destinationStore: PresentationStoreOf<AccountRecoveryScanInProgress.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /AccountRecoveryScanInProgress.Destination.State.derivePublicKeys,
			action: AccountRecoveryScanInProgress.Destination.Action.derivePublicKeys,
			content: {
				DerivePublicKeys.View(store: $0)
			}
		)
	}
}
