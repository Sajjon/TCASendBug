//
//  ImportMnemonic.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct RecoverWalletControlWithBDFSComplete: FeatureReducer {
	@MainActor
	public struct View: SwiftUI.View {
		public let store: StoreOf<RecoverWalletControlWithBDFSComplete>
		public var body: some SwiftUI.View {
			VStack {
				Text("RecoverWalletControlWithBDFSComplete")
				Button("Next") {
					store.send(.view(.next))
				}
			}
		}
	}
	
	public struct State: Sendable, Hashable {
		public init() {}
	}
	
	public enum ViewAction: Sendable, Equatable {
		case next
	}
	
	public enum DelegateAction: Sendable, Equatable {
		case next
	}
	
	
	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .next:
			return .send(.delegate(.next))
		}
	}
}
