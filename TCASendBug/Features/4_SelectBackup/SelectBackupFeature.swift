//
//  SelectBackupFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-22.
//

import Foundation
import ComposableArchitecture
import SwiftUI

// MARK: - SelectBackup
public struct SelectBackup: Sendable, FeatureReducer {
	
	@MainActor
	public struct View: SwiftUI.View {
		public let store: StoreOf<SelectBackup>

		public init(store: StoreOf<SelectBackup>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: 20) {
					Text("SelectBackup")

					Divider()
					Button("Other restore options") {
						store.send(.view(.otherRestoreOptionsTapped))
					}
				}
				.destinations(with: store)
			}
			.task { @MainActor in
				await store.send(.view(.task)).finish()
			}
		}
	}
	
	public struct State: Hashable, Sendable {

		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case otherRestoreOptionsTapped
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case recoverWalletWithoutProfileCoordinator(RecoverWalletWithoutProfileCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case recoverWalletWithoutProfileCoordinator(RecoverWalletWithoutProfileCoordinator.Action)
		}

		public var body: some Reducer<State, Action> {
			Scope(state: /State.recoverWalletWithoutProfileCoordinator, action: /Action.recoverWalletWithoutProfileCoordinator) {
				RecoverWalletWithoutProfileCoordinator()
			}
		}
	}
	
	public var body: some ReducerOf<SelectBackup> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination


//	public enum InternalAction: Sendable, Equatable {
//		case loadBackupProfileHeadersResult(ProfileSnapshot.HeaderList?)
//		case loadThisDeviceIDResult(UUID?)
//		case snapshotWithHeaderNotFoundInCloud(ProfileSnapshot.Header)
//	}

	public enum DelegateAction: Sendable, Equatable {
		case backToStartOfOnboarding
		case profileCreatedFromImportedBDFS
	}


	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .none
//			return .run { send in
//				await send(.internal(.loadThisDeviceIDResult(
//					backupsClient.loadDeviceID()
//				)))
//
//				await send(.internal(.loadBackupProfileHeadersResult(
//					backupsClient.loadProfileBackups()
//				)))
//			}

	
		case .otherRestoreOptionsTapped:
			state.destination = .recoverWalletWithoutProfileCoordinator(.init())
			return .none
		
		}
	}


	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .recoverWalletWithoutProfileCoordinator(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case .recoverWalletWithoutProfileCoordinator(.delegate(.backToStartOfOnboarding)):
			state.destination = nil
			return .send(.delegate(.backToStartOfOnboarding))

		case .recoverWalletWithoutProfileCoordinator(.delegate(.profileCreatedFromImportedBDFS)):
			state.destination = nil
			// Unfortunately we need a short delay :/ otherwise the "Recovery Completed" screen pops back again,
			// SwiftUI nav bug...
			return delayedShortEffect(for: .delegate(.profileCreatedFromImportedBDFS))

		default:
			return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		state.destination = nil
		return .none
	}
}


private extension StoreOf<SelectBackup> {
	var destination: PresentationStoreOf<SelectBackup.Destination> {
		func scopeState(state: State) -> PresentationState<SelectBackup.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SelectBackup>) -> some View {
		let destinationStore = store.destination
		return self
			.recoverWalletWithoutProfileCoordinator(with: destinationStore)
	}

	private func recoverWalletWithoutProfileCoordinator(with destinationStore: PresentationStoreOf<SelectBackup.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore,
			state: /SelectBackup.Destination.State.recoverWalletWithoutProfileCoordinator,
			action: SelectBackup.Destination.Action.recoverWalletWithoutProfileCoordinator,
			content: { RecoverWalletWithoutProfileCoordinator.View(store: $0) }
		)
	}
}
