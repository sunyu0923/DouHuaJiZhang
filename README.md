# DouHuaJiZhang

DouHuaJiZhang is an iOS bookkeeping application with a companion Go backend. It supports personal and family ledgers, transaction tracking, savings plans, investment records, health records, badges, and real-time ledger synchronization.

## Main components

- `Sources/DouHuaJiZhang`: SwiftUI iOS client using TCA-style feature modules.
- `Tests/DouHuaJiZhangTests`: Swift model, feature, and UI tests.
- `server`: Go backend providing REST APIs and WebSocket synchronization.

## Backend behavior

Protected backend routes require a valid access token. Ledger-scoped transaction APIs and WebSocket sync also require the authenticated user to be a member of the target ledger. Personal investment and health delete operations are scoped to the authenticated user's own records.

## Running tests

```bash
# Backend
cd server
go test ./... -count=1

# Swift package tests
swift test
```

