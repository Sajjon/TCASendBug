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
			.onFirstTask { @MainActor in
				/// For more information about that `sleep` please  check [this discussion in Slack](https://rdxworks.slack.com/archives/C03QFAWBRNX/p1687967412207119?thread_ts=1687964494.772899&cid=C03QFAWBRNX)
				@Dependency(\.continuousClock) var clock
				try? await clock.sleep(for: .milliseconds(700))

				await store.send(.view(.onFirstTask)).finish()
			}
		}
	}
	
	public struct State: Sendable, Hashable {
		public init() {}
	}
	
	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}
	
	public enum DelegateAction: Sendable, Equatable {
		case completed
	}
	
	
	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			return .run { send in
				try? await Task.sleep(for: .milliseconds(10))
				await send(.delegate(.completed))
			}
		}
	}
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
