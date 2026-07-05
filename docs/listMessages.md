# `listMessages`

List stored messages, newest first. Optionally filter with `search` (matches sender, recipient, or subject) and page with `before` (a `received_at` cursor) and `limit`; omit all for the default newest 100. Response is a bare array — paginate by passing the last row's `received_at` as the next `before`.

**HTTP:** `GET /api/messages`

## Parameters

_None._

## Returns

`any`

## Example

```dart
final res = await mk.listMessages();
```

---

[← All methods](../README.md#api-methods) · [Docs](https://mailkite.dev/docs) · [mailkite.dev](https://mailkite.dev)
