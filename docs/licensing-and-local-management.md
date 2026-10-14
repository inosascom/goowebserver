# Licensing and local management

## Objective

GOO Web Server Ubuntu Edition uses the existing GOO licensing system and license semantics. Linux adds a local management surface and a time-based registration reminder; it does not create a competing licensing model.

The exact Windows license payload, signature algorithm, entitlement fields, activation API, and renewal rules remain authoritative. The Linux implementation exposes these through a `license-provider` adapter. Once the Windows license contract is supplied, the adapter uses the same request/response protocol and signature verification rules.

## Local management address

The management application is a local-only service bound to `127.0.0.1:8765`. The selected Nginx or Apache provider publishes it as:

```text
http://localhost/goows
```

The reverse-proxy rule only accepts loopback traffic by default. It must not be reachable on public interfaces, must not receive a public virtual-host alias automatically, and does not cause UFW changes. Remote administration uses an SSH tunnel or a later, explicitly enabled protected-management feature.

```text
Browser -> http://localhost/goows
                    |
                    v
Nginx or Apache localhost-only route -> 127.0.0.1:8765
                                              |
                                              v
                                  inosas-goows.service
```

The first local visit requires a bootstrap administrator credential created during setup. The setup output displays it once only; it is stored as a password hash/credential reference, never in an access log. Session cookies are `HttpOnly`, `Secure` when HTTPS is used, and `SameSite=Strict`. A CSRF token protects state-changing actions.

## Management capabilities

The Linux UI intentionally exposes only actions that are safe for this platform and product state:

| Area | Available action |
| --- | --- |
| Status | installed product version, license state, web-server/PHP-FPM/database health, ports and recent errors |
| License | online registration, offline registration request export, signed offline response import, license details, renewal status |
| Setup | view selected Nginx/Apache, PHP-FPM series, database choice, TLS status, paths, logs and service status |
| Operations | restart only product-managed services after a pre-check; create/download a support bundle; view transaction history |
| Security | rotate management credential; view trusted license endpoint identity; revoke local sessions |

PHP version switching, cross-provider database migration, web-server migration, arbitrary APT repository management, and firewall-policy editing are not available in the UI. They require a deliberate CLI migration flow and a reviewed plan because they can break a running web workload.

## Registration states

```text
installed -> unregistered-grace -> registration-reminder -> registered
                                    |                         |
                                    +-> offline-request -------+
                                    +-> invalid/expired --------> limited-management
```

| State | Meaning | Host behavior |
| --- | --- | --- |
| `unregistered-grace` | No valid license; fewer than 7 × 24 hours since first successful installation | Service operates normally; status displays remaining time |
| `registration-reminder` | No valid registration at or after the 7-day deadline | Management home is redirected to `/goows/register`; registration banner remains visible until resolved |
| `registered` | License signature, product binding, time validity and entitlement checks pass | Normal operation |
| `offline-request` | Administrator exported an activation request | Service continues according to grace/entitlement rules; UI provides response import |
| `invalid` / `expired` | Response fails verification or entitlement is no longer valid | Management is limited to status, diagnosis, registration, export/import and backup/support-bundle actions |

The first successful installer transaction writes the grace start timestamp to `/var/lib/inosas/goows/license/state.json`. It is protected by owner/mode restrictions and paired with the installer transaction record. The service detects obvious local-clock rollback and treats it as `invalid` until online validation or a valid offline response resolves it.

## Seven-day registration hook

At service start and on a periodic systemd timer, the licensing adapter reevaluates registration state. After seven full 24-hour periods without a valid registration it enables the registration hook.

The hook affects **only the GOO management application**: a visit to `/goows` automatically opens `/goows/register`, and all non-registration management pages carry a blocking registration notice. It never redirects, modifies, injects into, or disables customer web sites served by Nginx/Apache. This protects hosted workloads while still making the registration requirement unavoidable for product administration.

The normal registration prompt includes product version, non-secret installation identity, privacy notice, online registration form, “Generate offline request” action, and “Import offline response” action.

## Online registration

1. The UI collects the fields required by the existing GOO registration system.
2. The license adapter submits the request through TLS to the configured, pinned/verified licensing endpoint.
3. It verifies the signed response locally before persisting it.
4. The response and entitlement summary are stored under `/var/lib/inosas/goows/license`, mode-restricted to the `goows` service account.
5. A successful activation clears the reminder hook and records an auditable, secret-free transaction event.

Network errors never make an existing valid offline/online license invalid. They only show a retry status.

## Offline registration

1. The operator opens `/goows/register` and downloads a signed/encoded registration request file, or runs `goowsctl license request --output request.goows-license-request`.
2. The request is submitted through the existing Windows/GOO licensing workflow on an internet-connected device.
3. The operator imports the signed response in the UI or runs `goowsctl license import response.goows-license`.
4. The adapter verifies product binding, integrity/signature, issued/expiry dates, and entitlements before accepting it.

Offline registration requests contain a stable installation identifier and minimal product/system facts required by the existing license service. They must not include private keys, passwords, database credentials, full application configuration, or log data.

## CLI equivalence and automation

Every licensing action is available without a browser:

```bash
goowsctl license status
goowsctl license register --online --registration-file /secure/input.json
goowsctl license request --output request.goows-license-request
goowsctl license import --file response.goows-license
```

For non-interactive image builds, no machine-bound license is embedded in a Docker image. Registration happens after deployment so every scaled container or host has its own valid installation identity, unless the existing GOO license policy explicitly supports a signed fleet/workload entitlement.

## Implementation prerequisites

Before implementation, import or document these Windows product assets:

1. License request/response schemas and canonical serialization.
2. Public-key/signature verification method and key-rotation policy.
3. Product/edition identifiers and entitlement rules.
4. Online activation endpoint and certificate/pinning requirements.
5. Existing offline registration file format and expected user fields.

No license validation behavior will be guessed or reverse-engineered; the Linux adapter is implemented only against the approved existing contract.
