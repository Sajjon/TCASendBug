#  TCA Send bug

This small app shows a bug in [TCA](https://github.com/pointfreeco/swift-composable-architecture), where a reducer never receives an action sent from iside an `Effect<Action>.run`, since that effect **is cancelled**. The way to trigger it is to set a `@PresentationState` destination to `nil` **and** let the `Effect<Action>.run` take 500 ms or more.

# Demo

https://github.com/Sajjon/TCASendBug/assets/864410/622fab3f-aef0-4a7b-ac1a-60057d5e7b72

