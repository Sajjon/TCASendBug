//
//  AppFeature.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-22.
//

import Foundation
import SwiftUI
import ComposableArchitecture

//public struct App: Sendable, FeatureReducer {
//	public struct State: Hashable {
//		public enum Root: Hashable {
//			case main(Main.State)
//			case onboardingCoordinator(OnboardingCoordinator.State)
//			case splash(Splash.State)
//		}
//		
//		public var root: Root
//		
//		public init(
//			root: Root = .splash(.init())
//		) {
//			self.root = root
//			let retBuildInfo = buildInformation()
//			let config = BuildConfiguration.current?.description ?? "Unknown Build Config"
//			loggerGlobal.info("App started (\(config), RET=\(retBuildInfo.version))")
//		}
//	}
//}
