---
name: kwat-services
description: 'City of Milwaukee in-house Java servlet framework ("future_package_layout" package): CoreServices3 base servlet, ServiceData2 request context, JsonMap (HashMap-based custom JSON), AbstractRestApi generic REST client base class, and the Abstract*API + *ProdAPI/*TestAPI environment-facade pattern. Use when adding or editing a servlet endpoint (a "method" dispatched from processRequest), reading/writing JsonMap, calling an external REST API from one of these apps, or deciding where new code belongs (layer separation) in any repo that imports future_package_layout — e.g. InterfaceAccelaCRMWithDPWWorkOrders, ItmdServices, KWATClient, MyMilwaukeeHome, SanitationProbation, EqualRightsCommissionComplaint(Admin), DPW_AppAdmin, MilwaukeeHealthyHomeProgram, diggers_batch, SnowOperations.'
---

# KWAT Services Framework (`future_package_layout`)

## Purpose

Help an AI correctly extend servlets built on the shared `future_package_layout` framework used
across most City of Milwaukee custom Java web apps, without violating the framework's established
conventions or duplicating logic that already exists.

## Scope

**Included:** `future_package_layout.service.CoreServices3` (base servlet),
`future_package_layout.service.ServiceData2` (request context), `future_package_layout.jsonMap.JsonMap`
/ `aJsonMap` (custom JSON map), `future_package_layout.util.AbstractRestApi` (generic REST client base
class) and the per-integration `Abstract*API` + `*ProdAPI`/`*TestAPI` facade pattern built on top of it.

**Out of scope:** the business logic inside any single app — this skill is about the shared
plumbing, not what a given servlet does with it.

**Source of truth:** the framework source lives in `itmdutil/src/future_package_layout/**`
(canonical) with duplicate copies vendored into some apps' own `src/` (e.g.
`DPW_CitytimeSSO/src/main/java/future_package_layout/...`). Not present at all in some
workspaces (compiled dependency only, e.g. `InterfaceAccelaCRMWithDPWWorkOrders`) — in that case
`get_errors`/compile-checking may not catch real classpath problems (the project may not even be
resolved by the language server).

## When to Use

- Adding a new endpoint ("method") to an existing servlet in one of these apps
- Writing a new servlet from scratch on this framework
- Reading/writing `JsonMap` and unsure what methods/behavior it supports
- Calling an external REST API (Accela, Routeware, Samsara, etc.) from one of these apps and
  deciding whether to add code to a shared `Abstract*API` class or a domain/servlet layer
- Debugging why a request parameter isn't showing up where expected

## Routing Boundaries

**Use this skill when:**

- The code imports or extends the `future_package_layout` servlet, request-context, JSON, or REST-client framework.
- The task concerns `CoreServices3`, `ServiceData2`, `JsonMap`, `AbstractRestApi`, or the shared API-facade pattern.

**Use the Java skill instead when:**

- The task is generic Java, JDBC, classpath, build, or language work without this framework's conventions.
- The task is business logic specific to one application; use this skill only for the shared servlet or REST plumbing.

**Pair with:**

- [`../kwatcontrol-ui-config/SKILL.md`](../kwatcontrol-ui-config/SKILL.md) when a servlet change also consumes or updates KWATControl UI metadata.
- [`../../accela-platform/accela/SKILL.md`](../../accela-platform/accela/SKILL.md) for Accela-specific API behavior or record/workflow semantics.

## Key Conventions

### `CoreServices3` (base servlet)
- Override `doGetCustom` / `doPostCustom` / `processRequest` — that's the whole extension surface
  (see the class's own doc comment).
- **Do NOT** manually add `httpResponse.addHeader("Access-Control-Allow-Origin", "*")`,
  `setContentType("application/json")`, or `setCharacterEncoding("UTF-8")` in an override —
  `CoreServices3` already handles CORS/content-type/charset. Users of this framework have flagged
  this repeated boilerplate as unwanted cruft more than once.
- `processRequest(ServiceData2 serviceData)` is the standard dispatch point — servlets typically
  switch/if-chain on `serviceData.method` and route to private handler methods, returning a
  `JsonMap` directly.
- `callRemoteService(host, endpoint, method, params)` is how one app calls another app's servlet:
  it POSTs to `https://<host>/<endpoint>?method=<method>`. This is the origin of the "Services"
  naming convention (e.g. `ItmdServices`, `.../Services.java` servlets) — "KWAT services" refers to
  this shared inter-app servlet-calling convention, not a single service.

### `ServiceData2` (request context)
- Fields: `jsonRequest` (JsonMap), `httpRequest`, `httpResponse`, `method`, `user`, `id`,
  `requestBody`, `currentHost`.
- **`readJsonRequest()` parses the raw POST body into `jsonRequest` FIRST, then iterates
  `httpRequest.getParameterNames()` and does `jsonRequest.put(paramName, httpRequest.getParameter(paramName))`.**
  Query-string/form params are merged into (and can overwrite) the body JSON before your handler
  ever runs. **Never** add a fallback like
  `firstNonBlank(request.getString("x"), serviceData.httpRequest.getParameter("x"), default)` —
  the `httpRequest.getParameter` branch can never fire since it's already folded into
  `jsonRequest`. Just read `serviceData.jsonRequest.getString("x")` with a default.
- **Handler methods should take a single `ServiceData2 serviceData` parameter**, not
  `(ServiceData2 serviceData, JsonMap request)` or other split-out fields. Pull `jsonRequest`
  (and anything else needed) out *inside* the method body. The whole point of `ServiceData2` is to
  hold everything so signatures stay simple and consistent across handler methods — don't
  pre-extract fields into extra parameters before calling a private handler.

### `JsonMap` / `aJsonMap`
- `JsonMap extends aJsonMap extends HashMap<String, Object> implements iJsonMap, Serializable`.
  Behaves like a normal `Map<String,Object>` — `.get(key)`, `.put(key,val)`, `.containsKey(key)`
  all work as expected; typed getters (`getString`, `getJsonMap`, `getVectorOfJsonMaps`,
  `getDouble`, ...) do the casting/parsing for you.
- Constructing `new JsonMap(rawJsonText)` expects the text to already have its leading `{` (or
  equivalent single top-level key) — see the `AbstractRestApi` parsing gotcha below.

### `AbstractRestApi` + `Abstract*API` REST client pattern
- Per-integration REST clients (e.g. `AbstractAccelaAPI`) `extend AbstractRestApi` and hardcode auth
  (token fetch/refresh/caching) plus a set of `public static` generic-verb methods: `GET(url, env)`,
  `PUT(url, body, env)`, `POSTArray(url, body, env)` (POST with the body wrapped in `[...]`,
  response still parsed as a normal enveloped object), plus a few endpoint-specific hardcoded-URL
  methods (e.g. `searchRecords`, `getWorkFlowTasks`) that were already there before you started.
- **`makeJSONRequest`/`GET` do `response.substring(1)` before parsing** — this strips the leading
  `{` so the hand-rolled `JsonMap`/`aJsonMap` parser (expects `key: value` pairs, not a literal
  opening brace) can read it. Works for normal `{payload,errors,isValid}`-shaped object responses.
  **Gotcha:** an endpoint that returns a bare top-level JSON *array* can't be parsed this way —
  `substring(1)` would eat the `[` and the parser has no key to attach the array to. Fetch the raw
  text yourself and wrap it as `new JsonMap("items:" + rawArrayText)`, then read via
  `.getVectorOfJsonMaps("items")` (see `RoutewareAPI.GET_ARRAY` for a worked example).
- Environment-bound facades (`AccelaProdAPI`, `AccelaTestAPI`, ...) `extend Abstract*API`, fix a
  `public static final AccelaEnvironment ENVIRONMENT` constant, implement the abstract
  `getEnvironment()`, and add thin non-static delegating methods (`GET`, `PUT`, ...) for callers
  that always want one fixed environment. Code that needs a caller-supplied/dynamic environment
  (e.g. an endpoint parameter) calls the `Abstract*API` static methods directly instead, passing
  `environment` through — same pattern `AccelaAPO.java` uses.

### Layer separation (important, user-enforced repeatedly)
- **Don't add new methods to a shared `Abstract*API` class for a one-off feature** — even a
  trivial one-line wrapper. These files are used by every servlet in the app; treat them as fixed/
  stable. Check first whether an existing public generic method (`GET`, `PUT`, `POSTArray`,
  `search*`) already covers the new call — reuse the established idiom instead (e.g. `POSTArray`
  is the existing idiom other code already uses for "create via POST" business calls; reuse it for
  a new create-style call rather than adding a bespoke `createX` method to the REST layer).
- New business-specific API calls belong in the servlet itself or a domain util class (e.g.
  `AccelaAPO.java`), built out of the REST layer's existing public methods.
- If a genuinely new generic HTTP-verb capability is ever needed in the shared REST layer, ask the
  user before editing that file — don't assume it's fine just because a similar hardcoded-URL
  method already exists there.

### `getHelp` convention
- Servlets built on this framework conventionally expose a `getHelp` method (dispatched like any
  other, e.g. `GET /Xyz?method=getHelp`) that self-documents the servlet's own endpoints. Canonical
  shape (see `Routeware.java`'s `getHelp()`/`buildHelpEntry(methodName, url, description,
  parameterNames[])`): each entry is `{method, url, description, parameters[]}`, wrapped in
  `{success, serviceName, baseUrl, count, services[]}`.
- When adding a new servlet, or a new method/case to an existing one, add or update `getHelp` too —
  it's easy to forget since it's not required for the feature to function.

## Common Mistakes

- Re-adding CORS/content-type boilerplate that `CoreServices3` already sets.
- Falling back to `httpRequest.getParameter(...)` after already reading from `jsonRequest` —
  dead code, since query params are already merged in.
- Splitting `ServiceData2` into multiple handler parameters instead of passing the whole object.
- Adding a business-specific method to a shared `Abstract*API` REST client instead of reusing an
  existing generic verb method or putting new logic in the domain/servlet layer.
- Treating a bare JSON array response the same as an enveloped `{...}` object response when
  parsing with this framework's `JsonMap(String)` constructor.

## Related Skills

- [`../../accela-platform/accela/SKILL.md`](../../accela-platform/accela/SKILL.md) — for the Accela Civic Platform side of integrations
  built on `AbstractAccelaAPI`/`AccelaAPO`.
