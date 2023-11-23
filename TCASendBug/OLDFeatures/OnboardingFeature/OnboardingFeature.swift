//
//  AccountRecoveryScanInProgressFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//


import Foundation
import SwiftUI
import ComposableArchitecture

// `AccountRecoveryScanInProgress`
// https://github.com/radixdlt/babylon-wallet-ios/blob/ABW-2412_restore_wallet_from_mnemonic_only/RadixWallet/Features/AccountRecoveryScan/Children/AccountRecoveryScanInProgress/AccountRecoveryScanInProgress.swift
struct OldOnboarding: Sendable, Reducer {
	
	// ‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
	//
	// Behaviour:
	// * A: set `state.destination = nil`
	// * B: sleep inside `.run` for more than 600ms
	//
	// If an A) AND B) is true, we never receive `.internal(.extremelyImportantInternalActionChangingState)`
	//
	// ‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
	private func scanOnLedger(state: inout State) -> Effect<Action> {
		guard let sleepDurationInMS = state.sleepDuration else {
			fatalError("Expected valid duration")
		}
		if state.shouldNilDestinationBeforeScanning {
			state.destination = nil
		}
		state.status = .scanningNetworkForActiveAccounts
		return .run { send in
			try? await Task.sleep(for: sleepDurationInMS)
			await send(.internal(.extremelyImportantInternalActionChangingState))
		}
	}
	
	struct View: SwiftUI.View {
		let store: StoreOf<OldOnboarding>
		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(alignment: .center, spacing: 30) {
					Text("Onboarding")
						.font(.title)
					Spacer(minLength: 0)
					switch viewStore.status {
					case .new:
						Text(LocalizedStringKey("Presents `DerivePublicKeys` inside `@PresentationState var destination` as a `sheet`. When `DerivePublicKeys` is done it will delegate to this reducer which will continue with 'Scanning' (network request, which we just mock as a `Task.sleep`).\n\n**If we set `state.destination = nil` before scanning AND duration of scan is ~ \(OldOnboarding.State.approxMinSleepDurationCausingBug)ms (or more) triggers bug.**\n\n🐞The bug is that the `Effect<Action>.run` gets cancelled, meaning our reducer never receives a sent action.🪲"))
						
						Divider()
						
							Toggle(
								isOn: viewStore.binding(
									get: \.shouldNilDestinationBeforeScanning,
									send: { .toggledShouldNilDestinationBeforeScanning($0) }
								)) {
									Text("Nil `destination` before scanning")
									Text("when set together with a high sleep duration causes crash.")
								}
							
						VStack(alignment: .leading, spacing: 0) {
							Text("Mocked duration of 'scan'")
							HStack {
								TextField(
									"Mocked duration of 'scan'",
									text: viewStore.binding(
										get: \.sleepDurationInMSString,
										send: { .sleepDurationInMSStringChanged($0) }
									)
								)
								Text("ms")
								Spacer(minLength: 0)
							}
						}
							
							Button("Start") {
								store.send(.view(.start))
							}
					case .scanningNetworkForActiveAccounts:
						ProgressView()
							.controlSize(.large)
							.tint(.purple)

						Text("'Scanning' (mocked network request)")
						Text(LocalizedStringKey("**If this request does not finish after `\(viewStore.sleepDurationInMSString) ms we have triggered the bug.**"))
						Spacer(minLength: 0)
					default: Text("`\(viewStore.status.rawValue)`")
					}
					Spacer(minLength: 0)
				}
				.multilineTextAlignment(.leading)
				.padding()
				.sheet(
					store: store.scope(state: \.$destination, action: { .destination($0) }),
					state: /OldOnboarding.Destination.State.derivePublicKeys,
					action: OldOnboarding.Destination.Action.derivePublicKeys,
					content: {
						DerivePublicKeys.View(store: $0)
					}
				)
			}
		}
	}
	
	struct State: Sendable, Hashable {
		enum Status: String, Sendable, Hashable {
			case new
			case derivingPublicKeys
			case scanningNetworkForActiveAccounts
		}

		var shouldNilDestinationBeforeScanning: Bool = true
		static let approxMinSleepDurationCausingBug = "600"
		var sleepDurationInMSString = Self.approxMinSleepDurationCausingBug
		var sleepDuration: Duration? {
			guard let ms = Int(sleepDurationInMSString) else {
				return nil
			}
			return .milliseconds(ms)
		}
		var status: Status = .new
	
		@PresentationState
		var destination: Destination.State? = nil
	}

	enum ViewAction: Sendable, Equatable {
		case start
		case toggledShouldNilDestinationBeforeScanning(Bool)
		case sleepDurationInMSStringChanged(String)
		case continueTapped
	}
	
	enum InternalAction: Sendable, Equatable {
		case extremelyImportantInternalActionChangingState
	}
	
	enum DelegateAction: Sendable, Equatable {
		case complete
	}

	struct Destination: Reducer {
		enum State: Sendable, Hashable {
			case derivePublicKeys(DerivePublicKeys.State)
		}

		enum Action: Sendable, Equatable {
			case derivePublicKeys(DerivePublicKeys.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.derivePublicKeys, action: /Action.derivePublicKeys) {
				DerivePublicKeys()
			}
		}
	}
	
	enum Action: Sendable, Equatable {
		case view(ViewAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
		case destination(PresentationAction<Destination.Action>)
	}
	

	init() {}


	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .view(viewAction):
				return reduce(into: &state, viewAction: viewAction)
			case let .`internal`(internalAction):
				return reduce(into: &state, internalAction: internalAction)
			case .destination(.dismiss):
				return .none
			case let .destination(.presented(presentedAction)):
				return reduce(into: &state, presentedAction: presentedAction)

			case .delegate:
				return .none
			}
		}
			.ifLet(\.$destination, action: /Action.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .extremelyImportantInternalActionChangingState:
			return .send(.delegate(.complete))
		}
	}


	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
			
		case let .toggledShouldNilDestinationBeforeScanning(newValue):
			state.shouldNilDestinationBeforeScanning = newValue
			return .none
			
		case let .sleepDurationInMSStringChanged(newValue):
			state.sleepDurationInMSString = newValue
			return .none
			
		case .start:
			state.status = .derivingPublicKeys
			state.destination = .derivePublicKeys(.init())
			return .none

		case .continueTapped:
			return .send(.delegate(.complete))
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .derivePublicKeys(.delegate(.completed)):
			return scanOnLedger(state: &state)
		default: return .none
		}
	}


}

