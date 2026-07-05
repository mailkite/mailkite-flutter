# `sendBroadcast`

Send a broadcast now, or pass an ISO 8601 `scheduledAt` to schedule it. A one-click unsubscribe is always added. Returns the status and resolved audience count.

**HTTP:** `POST /api/broadcasts/{id}/send`

## Parameters

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `scheduledAt` | string |  |  |

## Returns

`any`

## Example

```dart
final res = await mk.sendBroadcast(/* see Quickstart */);
```

---

[← All methods](../README.md#api-methods) · [Docs](https://mailkite.dev/docs) · [mailkite.dev](https://mailkite.dev)
