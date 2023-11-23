#  TCA Send bug

This small app shows a bug in [TCA](https://github.com/pointfreeco/swift-composable-architecture), where a reducer never receives an action sent from iside an `Effect<Action>.run`, since that effect **is cancelled**. The way to trigger it is to set a `@PresentationState` destination to `nil` **and** let the `Effect<Action>.run` take 500 ms or more.

This demo app is using TCA version `1.4.2` - but we have been experiencing this bug for a long time with much older TCA version than that.

**Possibly the bug might stem from SwiftUI itself...? I do not know!**

# Demo

In the demo below, notice how we by using standard configuration never proceeded to the green "Success" screen. But when restarting the app, and changing either the toggle (i.e. **not** nilling `destination`) or lowering the duration of the scan to `100` ms, the flow succeds and we proceed to the green "Success" screen.

https://github.com/Sajjon/TCASendBug/assets/864410/622fab3f-aef0-4a7b-ac1a-60057d5e7b72

