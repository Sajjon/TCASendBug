//
//  DerivePublicKeysFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import CryptoKit

struct DerivePublicKeys: Reducer {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DerivePublicKeys>
		var body: some SwiftUI.View {
			VStack {
				Text("DerivePublicKeys...")
				
				ProgressView()
					.controlSize(.large)
					.tint(Color.green)
			}
			.task {
				await store.send(.view(.task)).finish()
			}
		}
	}
	
	struct State: Sendable, Hashable {}
	
	enum ViewAction: Sendable, Equatable {
		case task
	}
	
	enum InternalAction: Sendable, Equatable {
		case deriveKeys
	}
	
	enum DelegateAction: Sendable, Equatable {
		case completed
	}
	
	enum Action: Sendable, Equatable {
		case view(ViewAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
	
	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .view(viewAction):
				return reduce(into: &state, viewAction: viewAction)
			case let .`internal`(internalAction):
				return reduce(into: &state, internalAction: internalAction)
			case .delegate:
				return .none
			}
		}
	}
	
	private static let msgWhenDone = "Successfully DerivedKeys, delegating 'completed' now."
	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .deriveKeys:
			print(Self.msgWhenDone)
			return .send(.delegate(.completed))
		}
	}
	
	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				await deriveKeys(doneMessage: Self.msgWhenDone)
				await send(.internal(.deriveKeys))
			}
		}
	}
}


private func deriveKeys(doneMessage: String) async {
	print("\(Date.now.ISO8601Format()) - DERIVE KEYS - START")
	_ = (0..<50_000).map { _ in
		Curve25519.Signing.PrivateKey().publicKey
	}
	print("\(Date.now.ISO8601Format()) - DERIVE KEYS - DONE: EXPECT TO SEE:\n'\(doneMessage)'\nIf you dont, we have a TCA Send bug.")
}
