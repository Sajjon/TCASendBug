//
//  AppFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct OldApp: Sendable, Reducer {
	
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<OldApp>

		init(store: StoreOf<OldApp>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			VStack(spacing: 0) {
				
				VStack {
					Button("RESTART APP") {
						store.send(.view(.restart))
					}
					Divider()
				}
				.frame(maxWidth: .infinity, idealHeight: 50)
				.background(Color.gray)
				
				SwitchStore(store.scope(state: \.root, action: Action.child)) { state in
					switch state {
					case .main:
						CaseLet(
							/OldApp.State.Root.main,
							 action: OldApp.ChildAction.main,
							 then: { OldMain.View(store: $0) }
						)
						
					case .onboarding:
						CaseLet(
							/OldApp.State.Root.onboarding,
							 action: OldApp.ChildAction.onboarding,
							 then: { OldOnboarding.View(store: $0) }
						)
					}
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
		}
	}
	
	struct State: Hashable {
		enum Root: Hashable {
			case onboarding(OldOnboarding.State)
			case main(OldMain.State)
		}
		
		var root: Root = .onboarding(.init())
		
	}

	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case view(ViewAction)
	}
	
	enum ViewAction: Sendable, Equatable {
		case restart
	}
	
	enum ChildAction: Sendable, Equatable {
		case main(OldMain.Action)
		case onboarding(OldOnboarding.Action)
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.main, action: /ChildAction.main) {
					OldMain()
				}
				.ifCaseLet(/State.Root.onboarding, action: /ChildAction.onboarding) {
					OldOnboarding()
				}
		}
		Reduce { state, action in
			switch action {
			case .view(.restart):
				state = .init()
				return .none
			case let .child(childAction):
				return reduce(into: &state, childAction: childAction)
			}
		}
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
