# `send`

Send a message over a verified domain. Pass `templateId` (+ optional `templateData`) to send from a saved or base template.

**HTTP:** `POST /v1/send`

## Parameters

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `from` | string | ✓ | An address on a verified domain. |
| `to` | string \| array | ✓ | One recipient or a list. |
| `subject` | string |  | Required unless supplied by a template. |
| `html` | string |  |  |
| `text` | string |  |  |
| `templateId` | string |  | Send using a saved template — a user template (tpl_…) or a base template (base_…). Its… |
| `templateData` | object |  | Values substituted into the template's {{merge_tags}} (e.g. {"name":"Ann"} fills… |
| `cc` | string \| array |  |  |
| `bcc` | string \| array |  |  |
| `replyTo` | string |  |  |
| `inReplyTo` | string |  |  |
| `headers` | object |  | Extra raw MIME headers, applied after threading headers (caller wins). Use for what the… |
| `attachments` | array |  |  |

## Returns

`send-response` — see the [`send-response`](https://mailkite.dev/docs/api-reference) schema.

## Example

```dart
final res = await mk.send(/* see Quickstart */);
```

---

[← All methods](../README.md#api-methods) · [Docs](https://mailkite.dev/docs) · [mailkite.dev](https://mailkite.dev)
