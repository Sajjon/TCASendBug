//
//  DerivePublicKeysFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct DerivePublicKeys: FeatureReducer {
	@MainActor
	public struct View: SwiftUI.View {
		public let store: StoreOf<DerivePublicKeys>
		public var body: some SwiftUI.View {
			VStack {
				Text("DerivePublicKeys...")
			}
			.task {
				await store.send(.view(.task)).finish()
			 }
		}
	}
	
	public struct State: Sendable, Hashable {
		public init() {}
	}
	
	public enum ViewAction: Sendable, Equatable {
		case task
	}
	
	public enum InternalAction: Sendable, Equatable {
		case deriveKeys
	}
	
	public enum DelegateAction: Sendable, Equatable {
		case completed
	}
	private static let msgWhenDone = "Successfully DerivedKeys, delegating 'completed' now."
	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .deriveKeys:
			print(Self.msgWhenDone)
			return .send(.delegate(.completed))
		}
	}
	
	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				await deriveKeys(doneMessage: Self.msgWhenDone)
				await send(.internal(.deriveKeys))
			}
		}
	}
}

import CryptoKit
private func deriveKeys(doneMessage: String) async {
	print("\(Date.now.ISO8601Format()) - DERIVE KEYS - START")
	_ = (0..<50_000).map { _ in
		Curve25519.Signing.PrivateKey().publicKey
	}
	print("\(Date.now.ISO8601Format()) - DERIVE KEYS - DONE: EXPECT TO SEE:\n'\(doneMessage)'\nIf you dont, we have a TCA Send bug.")
}

// MARK: - OnFirstTaskViewModifier
struct OnFirstTaskViewModifier: ViewModifier {
	let priority: TaskPriority
	let action: @Sendable () async -> Void

	@State private var didFire = false

	func body(content: Content) -> some View {
		content.task(priority: priority) {
			guard !didFire else {
				return
			}
			didFire = true
			await action()
		}
	}
}

extension View {
	/// Executes a given action only once, when the first `task` is fired by the system.
	public func onFirstTask(
		priority: TaskPriority = .userInitiated,
		_ action: @escaping @Sendable () async -> Void
	) -> some View {
		modifier(OnFirstTaskViewModifier(priority: priority, action: action))
	}
}
