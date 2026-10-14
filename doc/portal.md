# Portal configuration and upgrades

The SharkTrust portal automates HTTPS certificates for embedded web interfaces
using a compatible ACME certificate authority (CA).
It can run on a public server or on a private IPv4 network. Devices keep the
existing SharkTrust binary protocol in both installations.

## Runtime and existing data

Use a Mako Server with BAS version 6375 or newer and a matching current
`mako.zip` containing `acme/engine.create`. Startup checks both requirements.
The portal uses the current certificate engine and exportable software private
keys because the device protocol transfers each device's key to that device.

Preserve the Mako home directory when upgrading, including `data` and `cert`.
The portal stores zones, devices, users, administrator credentials and device
certificate metadata in `data/portal.sqlite.db`. A dedicated writer serializes
transactions. Browser and device write responses follow the database commit.
WAN address groups are derived from device records.

On the first start, the portal imports existing zone and device JSON files in
one transaction. It checks referenced records and rejects orphan zones or
devices. Existing zone keys, device keys, names and owner password hashes are
preserved. The original JSON files remain unchanged as a recovery snapshot;
after migration, editing them does not change the portal. A failed import does
not activate a partially populated database. Fix the reported legacy data and
restart. See [stored data](data-structures.md) for the schema.

Stop Mako before making a filesystem backup. Back up the complete `data` and
`cert` directories together. To roll back to the old portal, restore the
pre-upgrade backup; the retained JSON files do not contain post-migration changes.

Certificate PEMs are stored separately under `cert/profiles/<profile>/`, with
device files in its `devices` subdirectory. The profile identifies the CA
directory URL and production/staging selection. Switching either creates a
separate store. Switching back reuses that profile's certificates and keys.
ACME accounts are stored separately for each CA directory URL. A legacy software account
in `cert/account.json` is reused only when its saved CA profile matches the
configured directory. A malformed saved account causes startup to fail rather
than silently replacing its identity.

Legacy PEM files are copied into a profile only when the saved account identifies
the same CA/environment, or when using the original default Let's Encrypt
production configuration without a saved account. For another known legacy CA,
set `acme.importLegacy=true` once after confirming that those PEMs belong to the
selected configuration. `cert/legacy-profile.json` records the association so
later CA changes cannot reassign those originals to another profile. The
original PEM files are retained.

The portal can run four device certificate orders concurrently. Each DNS zone
retains every active challenge when a device address changes or another order
finishes. Existing device keys are reused for renewal. Deleting a device or
stopping the application cancels its pending order and challenge timer.
For both device and portal certificates, ACME Renewal Information (ARI) selects
a random renewal time within the CA's suggested window. SQLite preserves that
time across restarts, bound to the certificate fingerprint and CA profile. An
unchanged window retains its selected time; a changed window selects a new one.
Renewal orders include the ARI identifier of the certificate being replaced.

Without usable ARI, renewal starts before expiration by the smaller of 22 days
or one third of the certificate's actual validity period. This automatically
adapts to 64-day, 45-day and shorter certificates. An ARI lookup failure retains
an already selected earlier renewal time. Expired certificates do not wait for
an ARI lookup. The CA's check interval is bounded to one minute through one day;
unavailable or invalid ARI is checked again after six hours. Renewal and ARI
checks run through the normal portal/device scans, with at most four ARI lookups
in progress. There is no additional configuration option.

Failed orders retry after 1, 5, 15 and 60 minutes, then every 6 hours until
successful. The delay resets after success. Pending DNS reloads retry every
30 seconds; the portal rebuilds zone files from the database at startup.

## Private on-premises installation

Set `settings.ip` to the server's private IPv4 address. The portal recognizes
the `10.0.0.0/8`, `172.16.0.0/12` and `192.168.0.0/16` private ranges. For example,
the following is the settings portion of an existing Mako configuration:

```lua
-- Use your own domain names and the portal's LAN address.
settings={
   dn="trust.example.com",
   ns1="ns1.example.com",
   ns2="ns2.example.com",
   ip="192.168.1.20",
   acme={production=true}
}
```

Registered zone apex records point to the private server address. The NS records
retain the configured authoritative DNS server names. Devices and zone users
connect over HTTPS; administrators can open `http://192.168.1.20/` from a private
network to configure the portal. HTTP administration is accepted only when the
request targets the configured private IP address and originates from a private
or loopback address. Use an isolated management network for this HTTP access.

On premises, registered zone certificates use DNS-01 validation. The portal
does not request HTTP-01 certificates for its static service and server names;
it continues to load certificates from the selected profile for those names. Public CA
issuance still requires a registered public domain, correct public delegation,
and authoritative DNS reachable by the CA. Private web addresses do not turn
SharkTrust into a private certificate authority or an offline issuer.

Linux installations require BIND9 and `dig` (`bind9-dnsutils` on Ubuntu), the
existing privileged service setup, and HTTP/HTTPS ports 80 and 443. Registration
checks the parent DNS delegation with `dig -4 +trace`; outbound DNS must be
available. WHOIS is not used to validate delegated subdomains.
The service can use `UMask=0077` to keep credentials and private keys private.
SharkTrust explicitly makes its BIND zone directory accessible (`0755`) and
its generated DNS files readable (`0644`) so BIND can load them as its own user.
On Windows, zone files are written under the
Mako home `bind` directory and BIND commands are simulated for local testing.

## Settings

On a public server, SharkTrust itself obtains HTTP-01 certificates for
`settings.dn` and the local authoritative server name. The matching DNS names
must point to this server, and the CA must reach port 80. Registered zone
certificates use DNS-01. All of these requests use `settings.acme`; a separate
top-level Mako `acme` configuration is not needed for the portal.

A fresh installation temporarily serves Mako's fallback certificate while
the first ACME orders complete. The log reports each certificate request and
the names whose certificates have been loaded. On subsequent starts, SharkTrust
loads its saved certificates without waiting for a new certificate order.

These fields belong to the existing `settings` table in `mako.conf`. Keep the
authentication `realm` and `log.smtp` settings. Administrator `users` remain
supported until a portal administrator is saved with `-credentials` below.
`log.smtp.to` must contain the service contact email address.

| Field | Type | Required/default | Meaning |
| --- | --- | --- | --- |
| `dn` | string | Required | Service domain name. |
| `ns1`, `ns2` | string | Required | Authoritative DNS server names; both must resolve. |
| `ip` | string | Optional | Portal IPv4 address. If omitted, detected from a connection to `ns1` on port 53. Set it explicitly on multihomed servers. |
| `acme.production` | boolean | Optional, `true` | Select production or staging CA directory. |
| `acme.directoryUrl` | string | Optional | Explicit HTTPS ACME directory URL for the selected environment; overrides `productionUrl` and `stagingUrl`. No embedded credentials, fragments or whitespace. |
| `acme.productionUrl` | string | Optional | Production directory URL; defaults to Let's Encrypt production. |
| `acme.stagingUrl` | string | Optional | Staging directory URL; defaults to Let's Encrypt staging. |
| `acme.importLegacy` | boolean | Optional, automatic matching only | Set `true` once to associate unassigned legacy PEM files with the selected profile after verifying their origin. |
| `acme.rsa` | boolean | Optional, `false` | Use RSA for newly generated certificate keys instead of ECC. Existing keys are retained. |
| `acme.bits` | integer | Optional, `2048` | RSA key size in bits, when `rsa=true`; must be supported by the runtime. |
| `acme.curve` | string | Optional, `"SECP384R1"` | ECC curve for new certificate keys; must be supported by the runtime. |

Browser sessions expire after 30 minutes of inactivity. Forms, device deletion
and logout use session-bound CSRF tokens. Password recovery requires the email
code and zone key; the code expires after ten minutes or five failed attempts.

## Select another certificate authority

Set an HTTPS ACME directory URL supplied by your CA, then restart Mako:

```lua
-- Merge into settings; replace the example URL with your CA's directory.
settings.acme={
   production=true,
   directoryUrl="https://ca.example.com/acme/directory"
}
```

For distinct test and production directories, omit `directoryUrl`, set both
`productionUrl` and `stagingUrl`, and switch with the boolean `production` field.
If the provider has no test service, use a separate test installation and domain.
The administrator's **Certificate service** page shows the selected directory,
environment and pending certificate or DNS retries.

The CA must support ACME and DNS-01 for zone/device issuance. Public portal
service names also use HTTP-01. The current BAS engine rejects directories that
require External Account Binding (EAB); it does not accept EAB enrollment keys.
The provider must accept ordinary ACME account creation and the configured key
algorithm. TLS verification of the CA is always enabled. A private CA needs
appropriate trust on Mako and on the browsers and devices using its certificates;
choosing that CA alone does not establish browser trust.

## Set or reset the portal administrator

Stop the existing Mako instance, then run it with its usual configuration and
the optional `-credentials` argument. For example, from the configured Mako
working directory:

```powershell
# Replace the example password and retain your normal startup arguments.
mako -credentials "admin@example.com:YOUR_NEW_PASSWORD"
```

Run this command in the foreground, without `-s` or `-d`. After the database
commit, Mako prints a confirmation
and exits with status 0. It does not start the portal's DNS or certificate work.
Invalid credentials or a database failure exit with a nonzero status.
Start Mako normally afterward, without `-credentials`.

The argument is one string in `username:password` form. Supply it only once.
The username must contain 1-254 bytes, without colons, control characters, or
leading or trailing whitespace. The password must contain 8-1024 bytes and no
NUL character. The first colon separates the username from the password;
additional colons and spaces are allowed in the password. Quote the argument
according to your shell's rules.

The portal saves the username and a salted PBKDF2-HMAC-SHA256 password hash
with 600,000 iterations in the SQLite database under the Mako home directory.
It does not save the password itself. Subsequent starts use the saved account
without the argument. Running the option again replaces that account, including
its username. Application reload invalidates existing system-administrator
sessions on both the administrator and zone pages.

Once saved, this account replaces `mako.conf` administrator `users` for the
SharkTrust portal. It can also administer registered zones. Zone-owner accounts
and credentials for other Mako applications are unchanged. Without a saved
account, the portal continues to accept its existing `mako.conf` users. An
unreadable or malformed saved record stops portal startup; use an explicit
`-credentials` reset to recover it.

Use this option only for setup or reset, separately from normal startup commands.
Command-line passwords can appear in shell history and process listings; do not
store the password in a permanent service command.

## Device clients

The [C client guide](../examples/README.md) covers the OpenSSL download examples
and the SharkSSL/Minnow Server example. Configure the portal hostname separately
from the device zone, provision the zone's own key, and retain each device's
registration credential across restarts.

ARI controls when the portal renews a certificate. Devices must still fetch
the replacement and install it in their web server. The updated Minnow example
and OpenSSL `--watch` mode poll at most 12 hours after a successful fetch, sooner
when the remaining certificate lifetime is short. The OpenSSL examples save
one atomic `DeviceCredentials.pem` bundle; the web server integration owns
reloading that bundle. Existing device protocol commands and response layouts
are unchanged.

## Zone users and sensitive operations

The zone owner and portal administrator can open **Users and sign-in** to add
users, set or reset their local passwords, and assign one of these roles:

| Role | Access |
| --- | --- |
| Viewer | View registered devices and details. |
| Operator | Viewer access, device removal and inactive-device cleanup. |
| Zone administrator | Operator access, user management, sign-in settings and zone credentials. |

Added usernames are email addresses, normalized to lowercase. Local passwords
use the same salted hash format as the portal administrator. Leaving a password
blank when editing retains it. Role or password changes and user removal revoke
the affected user's existing sessions. The original owner remains available
through the existing password and account recovery flow.

Showing the zone key and downloading the generated C credentials require a code
sent to the zone owner's email address. The code expires in ten minutes and allows
five verification attempts. Requests are limited to one per minute and five per
hour per session. Successful verification grants one use, for the selected action
and zone, within one minute. The SMTP service must work for this flow. Portal
administrators can use **Test email** to check SMTP acceptance.

Devices are no longer automatically deleted after 90 days. **Inactive devices**
previews devices that have not contacted the portal for the selected whole number
of days (1-36500, initially 90). A preview lasts five minutes and requires explicit
acknowledgement. Removal rechecks activity in the database transaction and retains
devices that reconnected after the preview. Removal revokes the device credential
and deletes its stored certificate material across profiles.

## Optional Microsoft Entra sign-in

In **Users and sign-in**, enable Entra and provide these fields:

| Field | Type and requirement |
| --- | --- |
| Tenant ID | Required UUID string for a single Microsoft Entra tenant. |
| Application (client) ID | Required UUID string for its Web application registration. |
| Client secret Value | Required string, up to 512 bytes; blank retains the saved value when editing. |
| Client secret expiration | Required date string in `YYYY-MM-DD` format. |

Register `https://<zone-domain>/sso` as the Web redirect URI. For every allowed
user, add their email address, role and Microsoft Entra user object ID (a UUID
string). An identity must match both the email and object ID. There is no
automatic user enrollment or implicit administrator access.

The portal uses authorization-code flow with PKCE and validates the ID-token
signature, issuer, tenant, audience, nonce and validity period. User permissions
come from the portal's database. Local password sign-in remains available when
Entra is unavailable. The portal emails the owner about client-secret expiration
or rejection. Replace the secret in **Users and sign-in** when needed; the saved
secret is never returned in the form. Restrict OS access to the database and its
backups because they contain this service credential and device enrollment keys.
