//
//  Footer.swift
//  TCASendBug
//
//  Created by Alexander Cyon on 2023-11-23.
//

import Foundation
import SwiftUI


extension View {
	@ViewBuilder
	func footer(visible: Bool = true, @ViewBuilder _ content: () -> some View) -> some View {
		if visible {
			modifier(FooterModifier(footerContent: content))
		} else {
			self
		}
	}
}

// MARK: - FooterModifier
private struct FooterModifier<FooterContent: View>: ViewModifier {
	@ViewBuilder
	let footerContent: FooterContent

	func body(content: Content) -> some View {
		content
			.safeAreaInset(edge: .bottom, spacing: 0) {
				VStack(spacing: 0) {
					Divider()
					VStack {
						footerContent
					}
					.padding(20)
				}
			}
	}
}

