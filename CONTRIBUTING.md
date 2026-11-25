# Contributing to DeadLineTodo

Thanks for your interest in improving **DeadLineTodo**!

## Development Setup

1. Clone the repository and open `DeadLineTodo.xcodeproj` in Xcode 15.2+ (iOS 17.0+ SDK).
2. Switch the development team under **Signing & Capabilities** if running on a physical device.
3. For local in-app purchase testing, select `DeadLineTodoStore.storekit` in the scheme's Run → Options → StoreKit Configuration.

## Important Guidelines

- **SwiftData Schema Changes**: Never modify historical `TodoDataSchemaV1`–`V8` definitions in `LegacySchemas.swift`. Any breaking model change should introduce a new `VersionedSchema` and a corresponding `MigrationStage` in `TodoDataMigrationPlan`.
- **Localization**: Keep `en.lproj`, `zh-Hans.lproj`, and `zh-Hant.lproj` in sync whenever adding or updating user-facing strings.
- **Avoid committing local artifacts**: Do not commit `.DS_Store`, `xcuserdata/`, or personal signing team IDs.

## Pull Requests

1. Fork the repository and create a descriptive feature or fix branch.
2. Keep PRs focused on a single bug fix or enhancement.
3. Include screenshots or screen recordings for UI and WidgetKit changes.
