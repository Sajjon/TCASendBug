//
//  RecoverWalletWithoutProfileCoordinatorFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-22.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct RecoverWalletWithoutProfileCoordinator: Sendable, FeatureReducer {
	
	@MainActor
	public struct View: SwiftUI.View {
		public let store: StoreOf<RecoverWalletWithoutProfileCoordinator>

		public init(store: StoreOf<RecoverWalletWithoutProfileCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				IfLetStore(
					store.scope(state: \.root, action: { .child(.root($0)) })
				) {
					path(for: $0)
				}
			} destination: {
				path(for: $0)
			}
			.destinations(with: store)
		}

		private func path(
			for store: StoreOf<RecoverWalletWithoutProfileCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .start:
					CaseLet(
						/RecoverWalletWithoutProfileCoordinator.Path.State.start,
						action: RecoverWalletWithoutProfileCoordinator.Path.Action.start,
						then: { RecoverWalletWithoutProfileStart.View(store: $0) }
					)
//				case .importMnemonic:
//					CaseLet(
//						/RecoverWalletWithoutProfileCoordinator.Path.State.importMnemonic,
//						action: RecoverWalletWithoutProfileCoordinator.Path.Action.importMnemonic,
//						then: { ImportMnemonic.View(store: $0) }
//					)
//
//				case .recoveryComplete:
//					CaseLet(
//						/RecoverWalletWithoutProfileCoordinator.Path.State.recoveryComplete,
//						action: RecoverWalletWithoutProfileCoordinator.Path.Action.recoveryComplete,
//						then: { RecoverWalletControlWithBDFSComplete.View(store: $0) }
//					)
				}
			}
		}
	}
	
	public struct State: Sendable, Hashable {
		public var root: Path.State?
		public var path: StackState<Path.State> = .init()


		@PresentationState
		var destination: Destination.State? = nil

		public init() {
			self.root = .init(.start(.init()))
		}
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case start(RecoverWalletWithoutProfileStart.State)
//			case importMnemonic(ImportMnemonic.State)
//			case recoveryComplete(RecoverWalletControlWithBDFSComplete.State)
		}

		public enum Action: Sendable, Equatable {
			case start(RecoverWalletWithoutProfileStart.Action)
//			case importMnemonic(ImportMnemonic.Action)
//			case recoveryComplete(RecoverWalletControlWithBDFSComplete.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.start, action: /Action.start) {
				RecoverWalletWithoutProfileStart()
			}

//			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
//				ImportMnemonic()
//			}
//
//			Scope(state: /State.recoveryComplete, action: /Action.recoveryComplete) {
//				RecoverWalletControlWithBDFSComplete()
//			}
		}
	}

	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			case accountRecoveryScanCoordinator(AccountRecoveryScanCoordinator.State)
		}

		public enum Action: Equatable, Sendable {
			case accountRecoveryScanCoordinator(AccountRecoveryScanCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.accountRecoveryScanCoordinator, action: /Action.accountRecoveryScanCoordinator) {
				AccountRecoveryScanCoordinator()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case backToStartOfOnboarding
		case profileCreatedFromImportedBDFS
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Path()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination
/*
	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.start(.delegate(.backToStartOfOnboarding))):
			return .send(.delegate(.backToStartOfOnboarding))

		case .root(.start(.delegate(.dismiss))):
			return .run { _ in
				await dismiss()
			}

		case .root(.start(.delegate(.recoverWithBDFSOnly))):
			state.path.append(.recoverWalletControlWithBDFSOnly(.init()))
			return .none

		case .path(.element(_, action: .recoverWalletControlWithBDFSOnly(.delegate(.continue)))):
			state.path.append(
				.importMnemonic(
					.init(
						// We SHOULD remove the mnemonic from keychain if it we do not
						// complete this flow.
						persistStrategy: .init(
							mnemonicForFactorSourceKind: .onDevice(
								.babylon
							),
							location: .intoKeychainOnly
						)
					)
				)
			)
			return .none

		case let .path(.element(_, action: .importMnemonic(.delegate(delegateAction)))):
			switch delegateAction {
			case let .persistedMnemonicInKeychainOnly(factorSource):
				guard let fromHash = factorSource.id.extract(FactorSource.ID.FromHash.self) else {
					fatalError("error handling")
				}
				let deviceFactorSource = DeviceFactorSource(id: fromHash, common: .init(), hint: .init(name: "iPhone", model: "iPhone", mnemonicWordCount: .twentyFour))
				state.factorSourceOfImportedMnemonic = deviceFactorSource
				state.destination = .accountRecoveryScanCoordinator(.init(purpose: .createProfile(deviceFactorSource), promptForSelectionOfInactiveAccountsIfAny: true))
				return .none

			default:
				let errorMsg = "Discrepancy! Expected to have saved mnemonic into keychain but other action happened: \(delegateAction)"
				loggerGlobal.error(.init(stringLiteral: errorMsg))
				assertionFailure(errorMsg)
				return .send(.delegate(.dismiss))
			}

		case .root(.recoveryComplete(.delegate(.profileCreatedFromImportedBDFS))):
			return .send(.delegate(.profileCreatedFromImportedBDFS))

		default: return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .accountRecoveryScanCoordinator(.delegate(.completed)):
			state.destination = nil
			state.path = .init()
			// replace root so we cannot go back from `recoveryComplete`
			state.root = .recoveryComplete(.init())
			return .none

		case .accountRecoveryScanCoordinator(.delegate(.dismissed)):
			return deleteSavedUnusedMnemonic(state: state)

		default: return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		deleteSavedUnusedMnemonic(state: state)
	}

	private func deleteSavedUnusedMnemonic(state: State) -> Effect<Action> {
		if
			let factorSourceID = state.factorSourceOfImportedMnemonic?.id
		{
			loggerGlobal.notice("We did not finish Account Recovery Scan Flow. Deleting mnemonic from keychain for safety reasons.")
			// We did not complete account recovery scan => delete the mnemonic from
			// keychain for security reasons.
			try? secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceID)
		}
		return .send(.delegate(.dismiss))
	}
 */
}


private extension StoreOf<RecoverWalletWithoutProfileCoordinator> {
	var destination: PresentationStoreOf<RecoverWalletWithoutProfileCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<RecoverWalletWithoutProfileCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

private extension View {
	@MainActor
	func destinations(with store: StoreOf<RecoverWalletWithoutProfileCoordinator>) -> some View {
		let destinationStore = store.destination
		return accountRecoveryScanCoordinator(with: destinationStore)
	}

	@MainActor
	private func accountRecoveryScanCoordinator(with destinationStore: PresentationStoreOf<RecoverWalletWithoutProfileCoordinator.Destination>) -> some View {
		fullScreenCover(
			store: destinationStore,
			state: /RecoverWalletWithoutProfileCoordinator.Destination.State.accountRecoveryScanCoordinator,
			action: RecoverWalletWithoutProfileCoordinator.Destination.Action.accountRecoveryScanCoordinator,
			content: { AccountRecoveryScanCoordinator.View(store: $0) }
		)
	}
}
