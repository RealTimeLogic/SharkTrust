# Portal storage

SharkTrust keeps its authoritative records in `data/portal.sqlite.db` under the
Mako home directory. Certificate PEMs remain in `cert`. See the
[upgrade and backup procedure](portal.md#runtime-and-existing-data) before
changing or moving an installation.

One dedicated writer connection owns schema changes and transactions. Reads use
short-lived read-only connections. The database uses SQLite rollback journaling
and foreign keys. Do not edit the database while the portal is running.

## Schema version 1

| Table | Stored values |
| --- | --- |
| `zones` | `zkey`: 64-character hexadecimal primary key; `zname`: unique domain string; `uname`: owner email string; `ha1`: existing owner password hash string; `rtime`: registration Unix time in seconds; `sso`: optional JSON text for Entra configuration. |
| `devices` | `dkey`: 20-character hexadecimal primary key; `zkey`: parent zone key; `name`: subdomain string, unique within its zone; `ip`: local IPv4 string; `wan`: peer IPv4/IPv6 string; `dns`: `local`, `wan` or `both`; `info`: device description string; `atime`: last address/certificate request Unix time in seconds. |
| `certificates` | `profile`: CA/environment profile string; `dkey`: device key; `expires`: BAS certificate time string. The profile/device pair is the primary key. |
| `users` | `id`: integer primary key; `zkey`: parent zone key; `name`: lowercase email string, unique within its zone; `role`: `viewer`, `operator` or `admin`; `password`: optional JSON password-hash record; `subject`: optional Entra object-ID string; `revision`: random string used to revoke sessions when permissions change. |
| `meta` | `name`: configuration key string; `value`: JSON text. Includes the portal administrator hash record, migration details and certificate renewal schedules. |

Deleting a zone cascades to its devices and users. Deleting a device cascades to
its certificate metadata. WAN groups are queried from devices rather than saved
as a separate mutable index. BIND files are regenerated from zone/device records
plus the currently active ACME challenges.

A password-hash record contains integer `version` (1), string `username`, a
32-character hexadecimal `salt`, a 64-character hexadecimal `hash`, and integer
`iterations` (600000). Hashes use PBKDF2-HMAC-SHA256 with a 32-byte output.

## Certificate profiles

A profile is the SHA-256 hexadecimal digest of the environment prefix
(`production:` or `staging:`) followed by the exact selected directory URL.
Portal PEM files are `cert/profiles/<profile>/<domain>.key.pem` and
`<domain>.cert.pem`. Device PEM files are
`cert/profiles/<profile>/devices/<dkey>.key` and `<dkey>.cert`.

ACME accounts use a separate directory-URL digest and retain their current
`cert/account-<digest>.json` format. Never publish the database, account files,
private keys, backup copies or generated device credentials.

Renewal schedules use the `meta` key `renewal:<profile>:<domain>`. Their JSON
records contain a string `fingerprint` (SHA-256 of the certificate PEM), numeric
`renewAt` and `checkAt` (Unix seconds), and optional string `ariId`. Optional
numeric `windowStart` and `windowEnd` preserve the CA's last accepted ARI window
in Unix seconds. A changed certificate ignores the old record. Removing a
device or zone removes its renewal records across profiles. These records fit
the existing schema version 1; no schema conversion is required.

## Legacy import

The importer reads `data/zones.json`, `data/z.<zkey>.json`, and
`data/d.<dkey>.json`. A saved `data/admin.json` account is imported if present and
not replaced by `-credentials`. The old `w.<zkey>.json` WAN indexes are superseded
by queries over device records. The importer validates record relationships,
imports the related rows in one transaction, and sets `PRAGMA user_version=1`.

Original JSON files remain a pre-upgrade recovery snapshot. Once SQLite has
schema version 1, they are no longer read as live state. Restore a complete
pre-upgrade backup when rolling back to a version that uses JSON files.
