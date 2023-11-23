//
//  AppFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct App: Sendable, FeatureReducer {
	
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<App>

		public init(store: StoreOf<App>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store.scope(state: \.root, action: Action.child)) { state in
				switch state {
				case .main:
					CaseLet(
						/App.State.Root.main,
						action: App.ChildAction.main,
						then: { Main.View(store: $0) }
					)

				case .onboarding:
					CaseLet(
						/App.State.Root.onboarding,
						action: App.ChildAction.onboarding,
						then: { Onboarding.View(store: $0) }
					)
				}
			}
		}
	}
	
	public struct State: Hashable {
		public enum Root: Hashable {
			case onboarding(Onboarding.State)
			case main(Main.State)
		}
		
		public var root: Root
		
		public init(
			root: Root = .onboarding(.init())
		) {
			self.root = root
		}
	}
	
	
	public enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboarding(Onboarding.Action)
	}
	
	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.main, action: /ChildAction.main) {
					Main()
				}
				.ifCaseLet(/State.Root.onboarding, action: /ChildAction.onboarding) {
					Onboarding()
				}
		}
		Reduce(core)
	}

	
	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .onboarding(.delegate(.complete)):
			state.root = .main(.init())
			return .none
		default: return .none
		}
	}
}
