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

				case .onboardingCoordinator:
					CaseLet(
						/App.State.Root.onboardingCoordinator,
						action: App.ChildAction.onboardingCoordinator,
						then: { OnboardingCoordinator.View(store: $0) }
					)
				}
			}
		}
	}
	
	public struct State: Hashable {
		public enum Root: Hashable {
			case onboardingCoordinator(OnboardingCoordinator.State)
			case main(Main.State)
		}
		
		public var root: Root
		
		public init(
			root: Root = .onboardingCoordinator(.init())
		) {
			self.root = root
		}
	}
	
	
	public enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboardingCoordinator(OnboardingCoordinator.Action)
	}
	
	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.main, action: /ChildAction.main) {
					Main()
				}
				.ifCaseLet(/State.Root.onboardingCoordinator, action: /ChildAction.onboardingCoordinator) {
					OnboardingCoordinator()
				}
		}
		Reduce(core)
	}

	
	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .onboardingCoordinator(.delegate(.successfullyCompletedOnboarding)):
			state.root = .main(.init())
			return .none
		default: return .none
		}
	}
}

public struct Main: Sendable, FeatureReducer {
	public struct View: SwiftUI.View {
		public let store: StoreOf<Main>
		public var body: some SwiftUI.View {
			VStack {
				Text("SUCCESS!")
					.font(.headline)
				
				Text("As in, NO bug.")
			}
			.foregroundStyle(Color.white)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.green)
		}
	}
	public struct State: Sendable, Hashable {
		public init() {}
	}
	
}
