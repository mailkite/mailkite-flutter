// Docs: docs/architecture/client-side-oauth-libraries.md
//
// Request/response models for the rich endpoints (send / agent / route). Mirrors
// the shapes the TypeScript client models precisely; everything else flows as
// plain `Map<String, dynamic>` / `dynamic`, matching the spec's `any` returns.

/// A file attached to a send() — reference an uploaded `url` or inline `content`.
class Attachment {
  final String filename;
  final String? url;
  final String? content;
  final String? contentType;

  const Attachment({
    required this.filename,
    this.url,
    this.content,
    this.contentType,
  });

  Map<String, dynamic> toJson() => {
    'filename': filename,
    if (url != null) 'url': url,
    if (content != null) 'content': content,
    if (contentType != null) 'contentType': contentType,
  };
}

/// Body for send(). `subject` is required unless supplied by a template.
class SendMessage {
  final String from;

  /// A single address or a list of addresses.
  final Object to;
  final String? subject;
  final String? html;
  final String? text;
  final Object? cc;
  final Object? bcc;
  final String? replyTo;
  final String? inReplyTo;
  final List<Attachment>? attachments;

  /// Send from a saved template — a user template (`tpl_…`) or base (`base_…`).
  final String? templateId;

  /// Values substituted into the template's `{{merge_tags}}`.
  final Map<String, Object?>? templateData;

  const SendMessage({
    required this.from,
    required this.to,
    this.subject,
    this.html,
    this.text,
    this.cc,
    this.bcc,
    this.replyTo,
    this.inReplyTo,
    this.attachments,
    this.templateId,
    this.templateData,
  });

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    if (subject != null) 'subject': subject,
    if (html != null) 'html': html,
    if (text != null) 'text': text,
    if (cc != null) 'cc': cc,
    if (bcc != null) 'bcc': bcc,
    if (replyTo != null) 'replyTo': replyTo,
    if (inReplyTo != null) 'inReplyTo': inReplyTo,
    if (attachments != null)
      'attachments': attachments!.map((a) => a.toJson()).toList(),
    if (templateId != null) 'templateId': templateId,
    if (templateData != null) 'templateData': templateData,
  };
}

/// Result of send().
class SendResult {
  final String id;
  final String status;

  const SendResult({required this.id, required this.status});

  factory SendResult.fromJson(Map<String, dynamic> j) => SendResult(
    id: (j['id'] ?? '').toString(),
    status: (j['status'] ?? '').toString(),
  );
}

/// Body for agent() — talk to one of your inbox agents.
class AgentMessage {
  final String text;
  final String? subject;
  final String? from;
  final String? html;
  final String? routeId;
  final String? address;
  final String? model;

  const AgentMessage({
    required this.text,
    this.subject,
    this.from,
    this.html,
    this.routeId,
    this.address,
    this.model,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    if (subject != null) 'subject': subject,
    if (from != null) 'from': from,
    if (html != null) 'html': html,
    if (routeId != null) 'routeId': routeId,
    if (address != null) 'address': address,
    if (model != null) 'model': model,
  };
}

/// Result of agent().
class AgentResult {
  final bool ok;
  final String? text;
  final String? messageId;
  final String? error;

  const AgentResult({required this.ok, this.text, this.messageId, this.error});

  factory AgentResult.fromJson(Map<String, dynamic> j) => AgentResult(
    ok: j['ok'] == true,
    text: j['text'] as String?,
    messageId: j['messageId'] as String?,
    error: j['error'] as String?,
  );
}

/// Body for route() — run an existing route's action.
class RouteMessage {
  final String from;
  final String? routeId;
  final String? address;
  final String? subject;
  final String? text;
  final String? html;

  const RouteMessage({
    required this.from,
    this.routeId,
    this.address,
    this.subject,
    this.text,
    this.html,
  });

  Map<String, dynamic> toJson() => {
    'from': from,
    if (routeId != null) 'routeId': routeId,
    if (address != null) 'address': address,
    if (subject != null) 'subject': subject,
    if (text != null) 'text': text,
    if (html != null) 'html': html,
  };
}

/// Result of route(). `id` plus the full raw payload.
class RouteResult {
  final String id;
  final Map<String, dynamic> raw;

  const RouteResult({required this.id, required this.raw});

  factory RouteResult.fromJson(Map<String, dynamic> j) =>
      RouteResult(id: (j['id'] ?? '').toString(), raw: j);
}
