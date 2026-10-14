# DTO Conventions

1. **Immutability**: DTOs are immutable (use `final` for all fields).
2. **Type-checking**: `fromJson` type-checks every field. It never lets `dynamic` escape.
3. **Enums**: Enums parse with an explicit unknown fallback (e.g. `UNKNOWN` or a safe default), so an unexpected value does not crash the client.
4. **Whitelisting**: Request DTOs have an explicit whitelisted `toJson` method containing only the fields the contract allows for that endpoint. Never spread a map or forward unknown fields.
5. **No copyWith on requests**: No `copyWith` from response to request (do not build a request body from a server response object).
