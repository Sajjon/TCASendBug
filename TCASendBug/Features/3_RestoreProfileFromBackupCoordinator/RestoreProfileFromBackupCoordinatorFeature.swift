//
//  RestoreProfileFromBackupFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-22.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct RestoreProfileFromBackupCoordinator: Sendable, FeatureReducer {
	
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<RestoreProfileFromBackupCoordinator>

		public init(store: StoreOf<RestoreProfileFromBackupCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				path(for: store.scope(state: \.root, action: { .child(.root($0)) }))
			} destination: {
				path(for: $0)
			}
		}

		private func path(
			for store: StoreOf<RestoreProfileFromBackupCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .selectBackup:
					CaseLet(
						/RestoreProfileFromBackupCoordinator.Path.State.selectBackup,
						action: RestoreProfileFromBackupCoordinator.Path.Action.selectBackup,
						then: { SelectBackup.View(store: $0) }
					)
				}
			}
		}
	}
	
	public struct State: Sendable, Hashable {
		public var root: Path.State
		public var path: StackState<Path.State> = .init()

		public init() {
			self.root = .selectBackup(.init())
		}
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case selectBackup(SelectBackup.State)
		}

		public enum Action: Sendable, Equatable {
			case selectBackup(SelectBackup.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.selectBackup, action: /Action.selectBackup) {
				SelectBackup()
			}
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case delayedAppendToPath(RestoreProfileFromBackupCoordinator.Path.State)
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case backToStartOfOnboarding
		case profileCreatedFromImportedBDFS
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Path()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}
/*
	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .delayedAppendToPath(destination):
			state.path.append(destination)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .root(.selectBackup(.delegate(.selectedProfileSnapshot(profileSnapshot, isInCloud)))):
			state.profileSelection = .init(snapshot: profileSnapshot, isInCloud: isInCloud)
			return .run { send in
				try? await clock.sleep(for: .milliseconds(300))
				await send(.internal(.delayedAppendToPath(
					.importMnemonicsFlow(.init(context: .fromOnboarding(profileSnapshot: profileSnapshot))
					))))
			}

		case .root(.selectBackup(.delegate(.backToStartOfOnboarding))):
			return .send(.delegate(.backToStartOfOnboarding))

		case .root(.selectBackup(.delegate(.profileCreatedFromImportedBDFS))):
			return .send(.delegate(.profileCreatedFromImportedBDFS))

		case let .path(.element(_, action: .importMnemonicsFlow(.delegate(.finishedImportingMnemonics(skipList, _, notYetSavedNewMainBDFS))))):
			loggerGlobal.notice("Starting import snapshot process...")
			guard let profileSelection = state.profileSelection else {
				preconditionFailure("Expected to have a profile")
			}
			return .run { send in
				loggerGlobal.notice("Importing snapshot...")
				try await backupsClient.importSnapshot(profileSelection.snapshot, fromCloud: profileSelection.isInCloud)

				if let notYetSavedNewMainBDFS {
					try await factorSourcesClient.saveNewMainBDFS(notYetSavedNewMainBDFS)
				}

				await send(.delegate(.profileImported(
					skippedAnyMnemonic: !skipList.isEmpty
				)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .path(.element(_, action: .importMnemonicsFlow(.delegate(.finishedEarly(didFail))))):
			state.path.removeLast()
			return didFail ? .send(.delegate(.failedToImportProfileDueToMnemonics)) : .none

		default:
			return .none
		}
	}
 */
}

