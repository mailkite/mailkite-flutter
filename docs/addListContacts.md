# `addListContacts`

Add contacts (by id, ctr_…) to a list. Returns how many were newly added; contacts already on the list are ignored.

**HTTP:** `POST /api/lists/{id}/contacts`

## Parameters

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `contactIds` | array | ✓ |  |

## Returns

`any`

## Example

```dart
final res = await mk.addListContacts(/* see Quickstart */);
```

---

[← All methods](../README.md#api-methods) · [Docs](https://mailkite.dev/docs) · [mailkite.dev](https://mailkite.dev)
