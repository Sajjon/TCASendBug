//
//  AppFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct App: Sendable, FeatureReducer {
	
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<App>

		init(store: StoreOf<App>) {
			self.store = store
		}

		var body: some SwiftUI.View {
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
	
	struct State: Hashable {
		enum Root: Hashable {
			case onboarding(Onboarding.State)
			case main(Main.State)
		}
		
		var root: Root = .onboarding(.init())
		
	}
	
	
	enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboarding(Onboarding.Action)
	}
	
	var body: some ReducerOf<Self> {
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

	
	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .onboarding(.delegate(.complete)):
			state.root = .main(.init())
			return .none
		default: return .none
		}
	}
}
