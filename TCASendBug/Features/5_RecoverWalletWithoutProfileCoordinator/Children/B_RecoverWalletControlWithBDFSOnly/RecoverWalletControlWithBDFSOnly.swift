//
//  RecoverWalletControlWithBDFSOnly.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct RecoverWalletControlWithBDFSOnly: Sendable, FeatureReducer {
	
	@MainActor
	public struct View: SwiftUI.View {
		public let store: StoreOf<RecoverWalletControlWithBDFSOnly>

		public init(store: StoreOf<RecoverWalletControlWithBDFSOnly>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
				VStack(alignment: .leading, spacing: 20) {
					Text("Recover Control Without Backup")

					Text("**If you have no wallet backup in the cloud or as an exported backup file**, you can still restore Account access only using your main “Babylon” seed phrase. You cannot recover your Account names or other wallet settings this way.\n\nYou will be asked to enter the primary seed phrase. There are **24 words** that the Radix Wallet mobile app showed you to write down and save securely.")

					Spacer(minLength: 0)
				}
				.padding()
				.footer {
					Button("Continue") {
						store.send(.view(.continueTapped))
					}
				}
			}
		}
	}
	
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case `continue`
	}

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueTapped:
			.send(.delegate(.continue))
		}
	}
}
