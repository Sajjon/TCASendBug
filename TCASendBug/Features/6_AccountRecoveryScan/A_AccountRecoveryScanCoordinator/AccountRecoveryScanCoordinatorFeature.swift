//
//  AccountRecoveryScanCoordinatorFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct AccountRecoveryScanCoordinator: Sendable, FeatureReducer {
	
	public struct View: SwiftUI.View {
		public let store: StoreOf<AccountRecoveryScanCoordinator>
		public var body: some SwiftUI.View {
			VStack {
				Text("AccountRecoveryScanCoordinator")
//				Button("Next") {
//					store.send(.view(.recoverWithBDFSTapped))
//				}
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
//			case selectInactiveAccountsToAdd(SelectInactiveAccountsToAdd.State)
		}

		public enum Action: Sendable, Equatable {
//			case selectInactiveAccountsToAdd(SelectInactiveAccountsToAdd.Action)
		}

		public var body: some ReducerOf<Self> {
//			Scope(state: /State.selectInactiveAccountsToAdd, action: /Action.selectInactiveAccountsToAdd) {
//				SelectInactiveAccountsToAdd()
//			}
			EmptyReducer()
		}
	}
/*
	public enum ViewAction: Sendable, Equatable {
		case closeTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case root(AccountRecoveryScanInProgress.Action)
		case path(StackActionOf<Path>)
	}

	public enum InternalAction: Sendable, Equatable {
		case createProfileResult(TaskResult<EqVoid>)
		case addAccountsToExistingProfileResult(TaskResult<EqVoid>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
		case dismissed
	}

	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.dismiss) var dismiss
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeTapped:
			.run { send in
				await dismiss()
				await send(.delegate(.dismissed))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .addAccountsToExistingProfileResult(.success):
			return .send(.delegate(.completed))
		case let .addAccountsToExistingProfileResult(.failure(error)):
			fatalError("todo error handling")
		case .createProfileResult(.success):
			loggerGlobal.notice("Successfully created a Profile using Account Recovery Scanning ✅")
			return .send(.delegate(.completed))
		case let .createProfileResult(.failure(error)):
			fatalError("todo error handling")
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .root(.delegate(.foundAccounts(active, inactive))):
			if state.promptForSelectionOfInactiveAccountsIfAny, !inactive.isEmpty {
				state.path.append(.selectInactiveAccountsToAdd(.init(active: active, inactive: inactive)))
				return .none
			} else {
				return completed(purpose: state.purpose, inactiveToAdd: inactive, active: active)
			}

		case let .path(.element(_, action: .selectInactiveAccountsToAdd(.delegate(.finished(selectedInactive, active))))):
			return completed(purpose: state.purpose, inactiveToAdd: selectedInactive, active: active)

		default: return .none
		}
	}

	private func completed(
		purpose: State.Purpose,
		inactiveToAdd: IdentifiedArrayOf<Profile.Network.Account>,
		active: IdentifiedArrayOf<Profile.Network.Account>
	) -> Effect<Action> {
		// FIXME: check with Matt - should we by default we add ALL accounts, even inactive?
		var all = active
		all.append(contentsOf: inactiveToAdd)
		let accounts = all.sorted(by: \.index).asIdentifiable()

		switch purpose {
		case let .createProfile(deviceFactorSource):
			let recoveredAccountAndBDFS = AccountsRecoveredFromScanningUsingMnemonic(
				accounts: accounts,
				deviceFactorSource: deviceFactorSource
			)
			return .run { send in
				let result = await TaskResult<EqVoid> {
					try await onboardingClient.finishOnboardingWithRecoveredAccountAndBDFS(recoveredAccountAndBDFS)
				}
				await send(.internal(.createProfileResult(result)))
			}
		case .addAccounts:
			return .run { send in
				let result = await TaskResult<EqVoid> {
					try await accountsClient.saveVirtualAccounts(Array(accounts))
				}
				await send(.internal(.addAccountsToExistingProfileResult(result)))
			}
		}
	}
 */
}