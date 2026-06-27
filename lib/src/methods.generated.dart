// AUTO-GENERATED from sdks/spec/api.json by sdks/clients/codegen.mjs — DO NOT EDIT.
// Docs: docs/architecture/client-side-oauth-libraries.md
// ignore_for_file: lines_longer_than_80_chars
import 'types.dart';

/// HTTP method surface, generated from the API spec. The client core extends this.
abstract class GeneratedMethods {
  /// The transport every generated method calls. Implemented by MailKiteClient.
  Future<dynamic> request(String method, String path, [Object? body]);

  /// Send a message over a verified domain. Pass `templateId` (+ optional `templateData`) to send from a saved or base template.
  Future<SendResult> send(SendMessage message) =>
      request('POST', '/v1/send', message.toJson())
          .then((j) => SendResult.fromJson(j as Map<String, dynamic>));

  /// List your saved email templates (light metadata only — no body). Use getTemplate for the full template.
  Future<dynamic> listTemplates() =>
      request('GET', '/api/templates');

  /// List the premade base templates (light metadata). Clone one with createTemplate({ baseId }) or send from it directly via send({ templateId }).
  Future<dynamic> listBaseTemplates() =>
      request('GET', '/api/templates/base');

  /// Get one template (full: subject, html, text, theme). Works for your templates (tpl_…) and base templates (base_…).
  Future<dynamic> getTemplate(String id) =>
      request('GET', '/api/templates/${Uri.encodeComponent(id)}');

  /// Create a template. Pass `baseId` to clone a base template into your own, or provide name/subject/html/text/theme directly.
  Future<dynamic> createTemplate(Map<String, dynamic> body) =>
      request('POST', '/api/templates', body);

  /// List your domains, each with its webhook URL.
  Future<dynamic> listDomains() =>
      request('GET', '/api/domains');

  /// Add a domain. Returns the domain + DNS records.
  Future<dynamic> createDomain(Map<String, dynamic> body) =>
      request('POST', '/api/domains', body);

  /// Get one domain with DNS records + webhook.
  Future<dynamic> getDomain(String id) =>
      request('GET', '/api/domains/${Uri.encodeComponent(id)}');

  /// Remove a domain.
  Future<dynamic> deleteDomain(String id) =>
      request('DELETE', '/api/domains/${Uri.encodeComponent(id)}');

  /// Check DNS and update status.
  Future<dynamic> verifyDomain(String id) =>
      request('POST', '/api/domains/${Uri.encodeComponent(id)}/verify');

  /// Set or replace the domain's catch-all webhook.
  Future<dynamic> setWebhook(String id, Map<String, dynamic> body) =>
      request('PUT', '/api/domains/${Uri.encodeComponent(id)}/webhook', body);

  /// Remove the domain's webhook.
  Future<dynamic> deleteWebhook(String id) =>
      request('DELETE', '/api/domains/${Uri.encodeComponent(id)}/webhook');

  /// Send a signed test event to the domain's webhook.
  Future<dynamic> testWebhook(String id) =>
      request('POST', '/api/domains/${Uri.encodeComponent(id)}/webhook/test');

  /// Check whether a domain is available to register, and at what price. Read-only — no charge.
  Future<dynamic> checkDomainAvailability(String domain) =>
      request('GET', '/api/domains/register/check?domain=${Uri.encodeComponent(domain)}');

  /// Register (buy) a domain on the customer's behalf; provisions mail DNS and adds it to the account in one call. Charges the registrar.
  Future<dynamic> registerDomain(Map<String, dynamic> body) =>
      request('POST', '/api/domains/register', body);

  /// List inbound routing rules.
  Future<dynamic> listRoutes() =>
      request('GET', '/api/routes');

  /// Create a route (match, action, destination).
  Future<dynamic> createRoute(Map<String, dynamic> body) =>
      request('POST', '/api/routes', body);

  /// Send a message to one of your inbox agents and get its reply. Defaults to the account's default agent; pass `routeId` or `address` to target a specific agent, or `model` to override the model. This is separate from inbound routing — it does not match or override routes.
  Future<AgentResult> agent(AgentMessage message) =>
      request('POST', '/v1/agent', message.toJson())
          .then((j) => AgentResult.fromJson(j as Map<String, dynamic>));

  /// Route a message to one of your registered routes (by `routeId` or `address`), running that route's action — agent, webhook, or forward. The route must already exist on your account; arbitrary destinations are not allowed.
  Future<RouteResult> route(RouteMessage message) =>
      request('POST', '/v1/route', message.toJson())
          .then((j) => RouteResult.fromJson(j as Map<String, dynamic>));

  /// List stored messages.
  Future<dynamic> listMessages() =>
      request('GET', '/api/messages');

  /// Get a message with deliveries + attachments.
  Future<dynamic> getMessage(String id) =>
      request('GET', '/api/messages/${Uri.encodeComponent(id)}');

  /// Re-deliver a stored message to its webhook.
  Future<dynamic> retryDelivery(String id) =>
      request('POST', '/api/deliveries/${Uri.encodeComponent(id)}/retry');

  /// List your contact lists (static, curated broadcast audiences), each with its member count.
  Future<dynamic> listLists() =>
      request('GET', '/api/lists');

  /// Create a contact list. Returns the list with its id (lst_…); add contacts with addListContacts.
  Future<dynamic> createList(Map<String, dynamic> body) =>
      request('POST', '/api/lists', body);

  /// Get one contact list with its member count.
  Future<dynamic> getList(String id) =>
      request('GET', '/api/lists/${Uri.encodeComponent(id)}');

  /// Rename a contact list.
  Future<dynamic> updateList(String id, Map<String, dynamic> body) =>
      request('PATCH', '/api/lists/${Uri.encodeComponent(id)}', body);

  /// Delete a contact list. The list is removed; the contacts themselves are kept.
  Future<dynamic> deleteList(String id) =>
      request('DELETE', '/api/lists/${Uri.encodeComponent(id)}');

  /// List the contacts that are members of a list.
  Future<dynamic> listListContacts(String id) =>
      request('GET', '/api/lists/${Uri.encodeComponent(id)}/contacts');

  /// Add contacts (by id, ctr_…) to a list. Returns how many were newly added; contacts already on the list are ignored.
  Future<dynamic> addListContacts(String id, Map<String, dynamic> body) =>
      request('POST', '/api/lists/${Uri.encodeComponent(id)}/contacts', body);

  /// Remove one contact from a list (the contact itself is kept).
  Future<dynamic> removeListContact(String id, String contactId) =>
      request('DELETE', '/api/lists/${Uri.encodeComponent(id)}/contacts/${Uri.encodeComponent(contactId)}');

  /// List your broadcasts (one-to-many sends) with status and send stats.
  Future<dynamic> listBroadcasts() =>
      request('GET', '/api/broadcasts');

  /// Create a broadcast draft. `from` is required; set `audience` to { type: "all" } or { type: "list", id: "lst_…" }. Returns the broadcast with its id (bct_…). Send it with sendBroadcast.
  Future<dynamic> createBroadcast(Map<String, dynamic> body) =>
      request('POST', '/api/broadcasts', body);

  /// Get one broadcast with its status and recipient summary.
  Future<dynamic> getBroadcast(String id) =>
      request('GET', '/api/broadcasts/${Uri.encodeComponent(id)}');

  /// Edit a draft broadcast (any of from/subject/audience/html/… ). Drafts only.
  Future<dynamic> updateBroadcast(String id, Map<String, dynamic> body) =>
      request('PATCH', '/api/broadcasts/${Uri.encodeComponent(id)}', body);

  /// Delete a broadcast draft.
  Future<dynamic> deleteBroadcast(String id) =>
      request('DELETE', '/api/broadcasts/${Uri.encodeComponent(id)}');

  /// Send a broadcast now, or pass an ISO 8601 `scheduledAt` to schedule it. A one-click unsubscribe is always added. Returns the status and resolved audience count.
  Future<dynamic> sendBroadcast(String id, Map<String, dynamic> body) =>
      request('POST', '/api/broadcasts/${Uri.encodeComponent(id)}/send', body);

  /// Semantic search over the MailKite documentation — returns the most relevant doc sections for a natural-language query (hybrid vector + keyword search over https://mailkite.dev/docs). Public; no authentication required.
  Future<dynamic> semanticSearch(String query) =>
      request('GET', '/v1/docs/search?query=${Uri.encodeComponent(query)}');
}
