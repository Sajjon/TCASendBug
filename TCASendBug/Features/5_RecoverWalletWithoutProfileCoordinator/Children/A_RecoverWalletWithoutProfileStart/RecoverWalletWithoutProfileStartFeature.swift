//
//  RecoverWalletWithoutProfileStartFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-22.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct RecoverWalletWithoutProfileStart: Sendable, FeatureReducer {
	
	public struct View: SwiftUI.View {
		public let store: StoreOf<RecoverWalletWithoutProfileStart>
		public var body: some SwiftUI.View {
			VStack {
				Text("RecoverWalletWithoutProfileStart")
				Button("Next") {
					store.send(.view(.recoverWithBDFSTapped))
				}
			}
		}
	}
	
	public struct State: Sendable, Hashable {

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case recoverWithBDFSTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case recoverWithBDFSOnly
	}


	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .recoverWithBDFSTapped:
			return .send(.delegate(.recoverWithBDFSOnly))
		}
	}
/*
	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .ledgerOrOlympiaOnlyAlert(.cancelTapped):
			state.destination = nil
			return .none

		case .ledgerOrOlympiaOnlyAlert(.continueTapped):
			state.destination = nil
			return .send(.delegate(.backToStartOfOnboarding))
		}
	}
 */
}
