//
//  FeatureReducer.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-22.
//

import Foundation
import ComposableArchitecture
import SwiftUI

// MARK: - FeatureView
protocol FeatureView: SwiftUI.View where Feature.View == Self {
	associatedtype Feature: FeatureReducer

	@MainActor
	init(store: StoreOf<Feature>)
}

// MARK: - EmptyInitializable
protocol EmptyInitializable {
	init()
}

// MARK: - FeatureReducer
protocol FeatureReducer: Reducer where State: Sendable & Hashable, Action == FeatureAction<Self> {
	associatedtype ViewAction: Sendable & Equatable = Never
	associatedtype InternalAction: Sendable & Equatable = Never
	associatedtype ChildAction: Sendable & Equatable = Never
	associatedtype DelegateAction: Sendable & Equatable = Never

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action>
	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action>
	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action>
	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action>
	func reduceDismissedDestination(into state: inout State) -> Effect<Action>

	associatedtype Destination: DestinationReducer = EmptyDestination

	associatedtype ViewState: Equatable = Never
	associatedtype View: SwiftUI.View
}

// MARK: - FeatureAction
enum FeatureAction<Feature: FeatureReducer>: Sendable, Equatable {
	case destination(PresentationAction<Feature.Destination.Action>)
	case view(Feature.ViewAction)
	case `internal`(Feature.InternalAction)
	case child(Feature.ChildAction)
	case delegate(Feature.DelegateAction)
}

// MARK: - DestinationReducer
protocol DestinationReducer: Reducer where State: Sendable & Hashable, Action: Sendable & Equatable {}

// MARK: - EmptyDestination
enum EmptyDestination: DestinationReducer {
	struct State: Sendable, Hashable {}
	typealias Action = Never
	func reduce(into state: inout State, action: Never) -> Effect<Action> {}
	func reduceDismissedDestination(into state: inout State) -> Effect<Action> { .none }
}

extension Reducer where Self: FeatureReducer {
	typealias Action = FeatureAction<Self>

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func core(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .destination(.dismiss):
			reduceDismissedDestination(into: &state)
		case let .destination(.presented(presentedAction)):
			reduce(into: &state, presentedAction: presentedAction)
		case let .view(viewAction):
			reduce(into: &state, viewAction: viewAction)
		case let .internal(internalAction):
			reduce(into: &state, internalAction: internalAction)
		case let .child(childAction):
			reduce(into: &state, childAction: childAction)
		case .delegate:
			.none
		}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		.none
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		.none
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		.none
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		.none
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		.none
	}
}

typealias AlertPresentationStore<AlertAction> = Store<PresentationState<AlertState<AlertAction>>, PresentationAction<AlertAction>>

typealias PresentationStoreOf<R: Reducer> = Store<PresentationState<R.State>, PresentationAction<R.Action>>

typealias ViewStoreOf<Feature: FeatureReducer> = ViewStore<Feature.ViewState, Feature.ViewAction>

typealias StackActionOf<R: Reducer> = StackAction<R.State, R.Action>

// MARK: - FeatureAction + Hashable
extension FeatureAction: Hashable where Feature.Destination.Action: Hashable, Feature.ViewAction: Hashable, Feature.ChildAction: Hashable, Feature.InternalAction: Hashable, Feature.DelegateAction: Hashable {
	func hash(into hasher: inout Hasher) {
		switch self {
		case let .destination(action):
			hasher.combine(action)
		case let .view(action):
			hasher.combine(action)
		case let .internal(action):
			hasher.combine(action)
		case let .child(action):
			hasher.combine(action)
		case let .delegate(action):
			hasher.combine(action)
		}
	}
}

extension FeatureReducer {
	func delayedMediumEffect(internal internalAction: InternalAction) -> Effect<Action> {
		self.delayedMediumEffect(for: .internal(internalAction))
	}

	func delayedMediumEffect(
		for action: Action
	) -> Effect<Action> {
		delayedEffect(delay: .seconds(0.6), for: action)
	}

	func delayedShortEffect(
		for action: Action
	) -> Effect<Action> {
		delayedEffect(delay: .seconds(0.3), for: action)
	}

	func delayedEffect(
		delay: Duration,
		for action: Action
	) -> Effect<Action> {
		@Dependency(\.continuousClock) var clock
		return .run { send in
			try await clock.sleep(for: delay)
			await send(action)
		}
	}
}
