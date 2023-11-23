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
	
	public struct View: SwiftUI.View {
		public let store: StoreOf<SelectBackup>
		public var body: some SwiftUI.View {
			VStack {
				Text("SelectBackup")
				Button("Next") {
					store.send(.view(.otherRestoreOptionsTapped))
				}
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
/*
	public enum InternalAction: Sendable, Equatable {
		case loadBackupProfileHeadersResult(ProfileSnapshot.HeaderList?)
		case loadThisDeviceIDResult(UUID?)
		case snapshotWithHeaderNotFoundInCloud(ProfileSnapshot.Header)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selectedProfileSnapshot(ProfileSnapshot, isInCloud: Bool)
		case backToStartOfOnboarding
		case profileCreatedFromImportedBDFS
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dataReader) var dataReader
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.backupsClient) var backupsClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public init() {}

	public var body: some ReducerOf<SelectBackup> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				await send(.internal(.loadThisDeviceIDResult(
					backupsClient.loadDeviceID()
				)))

				await send(.internal(.loadBackupProfileHeadersResult(
					backupsClient.loadProfileBackups()
				)))
			}

		case .importFromFileInstead:
			state.isDisplayingFileImporter = true
			return .none

		case .otherRestoreOptionsTapped:
			state.destination = .recoverWalletWithoutProfileCoordinator(.init())
			return .none

		case let .selectedProfileHeader(header):
			state.selectedProfileHeader = header
			return .none

		case let .tappedUseCloudBackup(profileHeader):
			return .run { send in
				guard let snapshot = try await backupsClient.lookupProfileSnapshotByHeader(profileHeader) else {
					await send(.internal(.snapshotWithHeaderNotFoundInCloud(profileHeader)))
					return
				}
				await send(.delegate(.selectedProfileSnapshot(snapshot, isInCloud: true)))
			} catch: { error, send in
				loggerGlobal.error("Failed to load profile snapshot with header, error: \(error), header: \(profileHeader)")
				await send(.internal(.snapshotWithHeaderNotFoundInCloud(profileHeader)))
			}

		case .dismissFileImporter:
			state.isDisplayingFileImporter = false
			return .none

		case let .profileImportResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .profileImportResult(.success(profileURL)):
			do {
				guard profileURL.startAccessingSecurityScopedResource() else {
					throw LackedPermissionToAccessSecurityScopedResource()
				}
				defer { profileURL.stopAccessingSecurityScopedResource() }
				let data = try dataReader.contentsOf(profileURL, options: .uncached)
				let possiblyEncrypted = try ExportableProfileFile(data: data)
				switch possiblyEncrypted {
				case let .encrypted(encrypted):
					state.destination = .inputEncryptionPassword(.init(mode: .decrypt(encrypted)))
					return .none

				case let .plaintext(snapshot):
					return .send(.delegate(.selectedProfileSnapshot(snapshot, isInCloud: false)))
				}
			} catch {
				errorQueue.schedule(error)
				loggerGlobal.error("Failed to import profile, error: \(error)")
			}
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadBackupProfileHeadersResult(profileHeaders):
			state.backupProfileHeaders = profileHeaders
			return .none

		case let .loadThisDeviceIDResult(identifier):
			state.thisDeviceID = identifier
			return .none

		case let .snapshotWithHeaderNotFoundInCloud(headerOfNonFoundProfile):
			errorQueue.schedule(ProfileNotFoundInCloud(header: headerOfNonFoundProfile))
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

		case .inputEncryptionPassword(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case let .inputEncryptionPassword(.delegate(.successfullyDecrypted(_, decrypted))):
			state.destination = nil
			overlayWindowClient.scheduleHUD(.decryptedProfile)
			return .send(.delegate(.selectedProfileSnapshot(decrypted, isInCloud: false)))

		case .inputEncryptionPassword(.delegate(.successfullyEncrypted)):
			preconditionFailure("What? Encrypted? Expected to only have DECRYPTED. Incorrect implementation somewhere...")

		default:
			return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		state.destination = nil
		return .none
	}
 */
}