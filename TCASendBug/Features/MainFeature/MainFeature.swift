//
//  MainFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI
import ComposableArchitecture

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
