//
//  OnboardingStartupFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-22.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct OnboardingStartup: Sendable, FeatureReducer {
	
	public struct View: SwiftUI.View {
		public let store: StoreOf<OnboardingStartup>
		public var body: some SwiftUI.View {
			NavigationStack {
				WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
					VStack(spacing: 0) {
						Text("OnboardingStartup")
					}
					.footer {
						Button("Restore from backup") {
							viewStore.send(.selectedRestoreFromBackup)
						}
					}
				}
				.destinations(with: store)
			}
		}
	}
	
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedRestoreFromBackup
	}

	public enum DelegateAction: Sendable, Equatable {
		case profileCreatedFromImportedBDFS
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case restoreFromBackup(RestoreProfileFromBackupCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case restoreFromBackup(RestoreProfileFromBackupCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.restoreFromBackup, action: /Action.restoreFromBackup) {
				RestoreProfileFromBackupCoordinator()
			}
		}
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {

		case .selectedRestoreFromBackup:
			state.destination = .restoreFromBackup(.init())
			return .none
		}
	}
	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		
		case .restoreFromBackup(.delegate(.backToStartOfOnboarding)):
			state.destination = nil
			return .none

		case .restoreFromBackup(.delegate(.profileCreatedFromImportedBDFS)):
			state.destination = nil
			return .send(.delegate(.profileCreatedFromImportedBDFS))

		default:
			return .none
		}
	}
}


private extension StoreOf<OnboardingStartup> {
	var destination: PresentationStoreOf<OnboardingStartup.Destination> {
		func scopeState(state: State) -> PresentationState<OnboardingStartup.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<OnboardingStartup>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /OnboardingStartup.Destination.State.restoreFromBackup,
			action: OnboardingStartup.Destination.Action.restoreFromBackup,
			content: { RestoreProfileFromBackupCoordinator.View(store: $0) }
		)
	}
}
