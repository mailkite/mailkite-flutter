# `listListContacts`

List the contacts that are members of a list, newest first. Optionally page with `before` (a `last_seen_at`/`created_at` cursor) and `limit`. Response is a bare array — paginate by passing the last row's `last_seen_at` (or `created_at`) as the next `before`.

**HTTP:** `GET /api/lists/{id}/contacts`

## Parameters

| Name | In | Description |
| --- | --- | --- |
| `id` | path | — |

## Returns

`any`

## Example

```dart
final res = await mk.listListContacts('lst_1');
```

---

[← All methods](../README.md#api-methods) · [Docs](https://mailkite.dev/docs) · [mailkite.dev](https://mailkite.dev)
