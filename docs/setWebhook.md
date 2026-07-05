# `setWebhook`

Set or replace the domain's catch-all webhook.

**HTTP:** `PUT /api/domains/{id}/webhook`

## Parameters

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `url` | string | ✓ |  |

## Returns

`any`

## Example

```dart
final res = await mk.setWebhook(/* see Quickstart */);
```

---

[← All methods](../README.md#api-methods) · [Docs](https://mailkite.dev/docs) · [mailkite.dev](https://mailkite.dev)
