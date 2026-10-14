# Imported Windows license contract

The Linux edition will use the existing GOO Web Server production licensing contract. The following **public-only** verification assets were imported from the Windows product output:

```text
assets/licensing/windows-contract/
  license-signing-public.pem
  portal-encryption-public.pem
  key-manifest.json
```

No private signing/encryption key, device token, customer license, or customer registration data was copied.

## Confirmed contract

| Concern | Windows production contract | Linux adapter requirement |
| --- | --- | --- |
| Product code | `GOO_WEB_SERVER` | Use the same code in registration and license documents |
| License document format | `GOO_WEB_SERVER_LICENSE`, schema `1` | Reject any other format/schema |
| Encrypted license format | `GOO_WEB_SERVER_ENCRYPTED_LICENSE`, schema `2` | Required for offline license imports |
| Offline request format | `GOO_WEB_SERVER_REGISTRATION_REQUEST`, schema `2` | Generate compatible encrypted requests with Linux inventory |
| License signature | `ECDSA_P256_SHA256` | Verify using the imported signing public key before persistence |
| Signing key identity | `INOSAS_GOOWS_LICENSE_SIGNING_2026` | Verify fingerprint against `key-manifest.json` during build/release |
| Request encryption | hybrid `RSA_OAEP_SHA256_AES_256_GCM` | Encrypt requests to the imported portal encryption public key |
| Registration encryption key identity | `INOSAS_REGISTRATION_RSA_2026` | Verify fingerprint against `key-manifest.json` during build/release |
| Online activation endpoint | `https://webserver.goosm.com/api/v1/licenses/activate` | Send `installation_id`, license key, and Linux device inventory over TLS |
| Health endpoint | `https://webserver.goosm.com/api/v1/health` | Use for connectivity status only; never weaken a valid offline license on failure |
| Standard edition | `FREE`, `PERPETUAL` | Preserve these validation rules unless the existing contract changes |

Online activation returns a `license_document`; its signature must be verified locally exactly as an imported offline license is. A returned device access token is secret state and must be stored with Linux file permissions (`0600`, owned by `goows`), never in the package, Docker image, logs, or a support bundle.

## Linux substitutions

The Windows code uses DPAPI for the per-installation RSA private key, device token, public-network identity, and entitlement state. Linux will preserve the wire format and replace only at-rest protection:

| Windows dependency | Linux replacement |
| --- | --- |
| DPAPI | root/`goows`-owned state directory with `0700`; private key/token files with `0600`; optional system keyring or TPM-backed secret provider when available |
| Windows device inventory | Linux hostname, `/etc/machine-id`-derived stable device identity, OS release, architecture, non-secret network facts, selected GOO components |
| Windows Registry/service state | `/var/lib/inosas/goows/license/` state plus systemd/service metadata |
| WPF Manager registration UI | `http://localhost/goows/register` and equivalent `goowsctl license` commands |

The Linux registration request will label its platform facts as Linux/Ubuntu; it must not fabricate Windows-specific fields. The server-side registration contract must accept this platform-specific inventory before production release.

## Grace behavior aligned with Windows

Windows initializes `GRACE_ACTIVE` at installation and sets expiry to installation time plus seven days. It treats `ACTIVE_FREE` and `OFFLINE_ACTIVE` as registered. Linux will preserve these status strings and the seven-day calculation, then apply the Linux-specific reminder policy: after grace expiry, redirect the local GOO management application to `/goows/register` and restrict management actions. It must not redirect or stop customer-hosted web traffic without a separately approved licensing policy change.

## Required interoperability tests

1. A production-signed Windows-compatible `GOO_WEB_SERVER_LICENSE` validates on Linux.
2. A Linux-generated encrypted registration request is accepted by the existing registration service.
3. The resulting encrypted response is decryptable and signature-valid on Linux.
4. Wrong installation ID, edition, product code, validity type, schema, signature, or key fingerprint is rejected.
5. Online activation returns a document that validates through the same path as offline import.
6. Clock rollback and a missing/unreadable protected state fail safely without exposing secrets.
