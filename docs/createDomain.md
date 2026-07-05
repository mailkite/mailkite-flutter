# `createDomain`

Add a domain. Returns the domain + DNS records.

**HTTP:** `POST /api/domains`

## Parameters

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `domain` | string | ✓ |  |

## Returns

`any`

## Example

```dart
final res = await mk.createDomain(/* see Quickstart */);
```

---

[← All methods](../README.md#api-methods) · [Docs](https://mailkite.dev/docs) · [mailkite.dev](https://mailkite.dev)
