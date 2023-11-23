//
//  AccountRecoveryScanCoordinatorFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

// `AccountRecoveryScanCoordinator`: https://github.com/radixdlt/babylon-wallet-ios/blob/ABW-2412_restore_wallet_from_mnemonic_only/RadixWallet/Features/AccountRecoveryScan/Coordinator/AccountRecoveryScanCoordinator.swift
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	
	@MainActor
	public struct View: SwiftUI.View {
		public let store: StoreOf<OnboardingCoordinator>

		public init(store: StoreOf<OnboardingCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				AccountRecoveryScanInProgress.View(store: store.scope(
					state: \.root,
					action: { .child(.root($0)) }
				))
			} destination: { _ in
				Text("never used")
			}
		}
	
	}
	
	public struct State: Sendable, Hashable {

		public var root: AccountRecoveryScanInProgress.State
		public var path: StackState<Path.State> = .init()

		public init() {
			self.root = .init()
		}
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
		}

		public enum Action: Sendable, Equatable {
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case root(AccountRecoveryScanInProgress.Action)
		case path(StackActionOf<Path>)
	}

	

	public enum DelegateAction: Sendable, Equatable {
		case successfullyCompletedOnboarding
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			AccountRecoveryScanInProgress()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}


	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.delegate(.complete)):
			return .send(.delegate(.successfullyCompletedOnboarding))

		default: return .none
		}
	}


}
