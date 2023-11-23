//
//  AccountRecoveryScanInProgressFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//


import Foundation
import SwiftUI
import ComposableArchitecture

// `AccountRecoveryScanInProgress`
// https://github.com/radixdlt/babylon-wallet-ios/blob/ABW-2412_restore_wallet_from_mnemonic_only/RadixWallet/Features/AccountRecoveryScan/Children/AccountRecoveryScanInProgress/AccountRecoveryScanInProgress.swift
public struct Onboarding: Sendable, FeatureReducer {
	
	public struct View: SwiftUI.View {
		public let store: StoreOf<Onboarding>
		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack {
					Text("Onboarding")
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
				.sheet(
					store: store.scope(state: \.$destination, action: { .destination($0) }),
					state: /Onboarding.Destination.State.derivePublicKeys,
					action: Onboarding.Destination.Action.derivePublicKeys,
					content: {
						DerivePublicKeys.View(store: $0)
					}
				)
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

		public init() {}
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
			.ifLet(\.$destination, action: /Action.destination) {
				Destination()
			}
	}

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

