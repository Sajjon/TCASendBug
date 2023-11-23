
import SwiftUI
import ComposableArchitecture
import Foundation

// MARK: - OnboardingCoordinator
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	
	public struct View: SwiftUI.View {
		public let store: StoreOf<OnboardingCoordinator>
		public var body: some SwiftUI.View {
			SwitchStore(store.scope(state: \.root, action: Action.child)) { state in
				switch state {
				case .startup:
					CaseLet(
						/OnboardingCoordinator.State.Root.startup,
						action: OnboardingCoordinator.ChildAction.startup,
						then: { OnboardingStartup.View(store: $0) }
					)
				}
			}
		}
	}
	
	
	public struct State: Sendable, Hashable {
		public enum Root: Sendable, Hashable {
			case startup(OnboardingStartup.State)
		}

		public var root: Root

		public init() {
			self.root = .startup(.init())
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case startup(OnboardingStartup.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public enum InternalAction: Sendable, Equatable {
		case finishedOnboarding
	}


	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.startup, action: /ChildAction.startup) {
					OnboardingStartup()
				}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
			
		case .startup(.delegate(.profileCreatedFromImportedBDFS)):
			return sendDelegateCompleted(state: state)

		default:
			return .none
		}
	}

	private func sendDelegateCompleted(
		state: State
	) -> Effect<Action> {
		.send(.delegate(.completed))
	}
 
 public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
	 switch internalAction {
	 case .finishedOnboarding:
		 sendDelegateCompleted(state: state)
	 }
 }
}
