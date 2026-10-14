# Portal configuration

[Manual index](README.md) | [Installation](installation.md) | [Operations](operations.md)

Use the Ansible variables when installing a portal. The installer writes
`/opt/SharkTrust/mako.conf`, which Mako reads at startup. For an existing
installation, configuration is preserved unless you explicitly request replacement.
Do not assume that changing controller variables changes a retained `mako.conf`.

## Installer variables

The defaults are in [ansible/SharkTrust/vars.yaml](../ansible/SharkTrust/vars.yaml).
Put deployment overrides in a private extra-vars file as shown in the
[installation guide](installation.md#5-configure-your-installation).
The following are YAML values; do not quote booleans as strings.

### Deployment and runtime

| Variable | Type; default | Meaning |
| --- | --- | --- |
| `ansible_user` | String; `rtl` | SSH deployment account. The wrapper's optional second argument overrides it. |
| `ansible_python_interpreter` | Path string; `/usr/bin/python3` | Python interpreter on the target. |
| `start_portal` | Boolean; `false` | `true` enables and starts the portal after requiring a saved administrator record. `false` stops and disables an existing portal too. |
| `replace_mako_conf` | Boolean; `false` | `true` replaces existing configuration from reviewed variables and saves a timestamped backup. A fresh configuration is always created when absent. |
| `GitSharkTrust` | URL string; `https://github.com/RealTimeLogic/SharkTrust.git` | Repository cloned on the target when no local portal ZIP is selected. |
| `GitSharkTrustVersion` | Git revision string; `master` | Branch, tag, or commit. Pin a reviewed commit for repeatable deployment. |
| `SharkTrustSourceDir` | Absolute target path string; `/opt/SharkTrust-source` | Dedicated Git checkout used to package `www`. |
| `portal_local_archive` | Controller path string; empty | Optional ZIP containing the contents of `www` at its root, including hidden files. Overrides Git packaging. |
| `mako_local_archive` | Controller path string; empty | Optional Linux x86-64 tar.gz with `mako` and matching `mako.zip` at its root. Takes precedence over download. |
| `mako_download_url` | HTTPS URL string; empty | Required when no local runtime archive is supplied. There is no automatic default release. |
| `mako_archive_checksum` | String; no usable default | Required `sha256:` followed by the release archive's 64 hexadecimal digest characters. |

### Service names and CA selection

| Variable | Type; default | Runtime setting or meaning |
| --- | --- | --- |
| `settingsdn` | Hostname string; `sharktrust.realtimelogic.com` | `settings.dn`. Replace with your service hostname. |
| `settingsns1` | Hostname string; `ns1.realtimelogic.com` | `settings.ns1`. Replace for your installation. |
| `settingsns2` | Hostname string; `ns2.realtimelogic.com` | `settings.ns2`. Replace for your installation. |
| `settingsip` | IPv4 string; empty | `settings.ip`. Empty omits it and uses address detection. Private RFC 1918 ranges select on-premises behavior; public addresses select public behavior. |
| `settingsacmeproduction` | Boolean; `true` | `settings.acme.production`. `false` selects staging unless an explicit directory overrides it. |
| `settingsacmersa` | Boolean; `false` | `settings.acme.rsa`. New keys use ECC unless RSA is selected. |
| `settingsacmedirectoryurl` | HTTPS URL string; empty | Optional `settings.acme.directoryUrl`, overriding the environment's directory. |
| `settingsacmeproductionurl` | HTTPS URL string; empty | Optional `settings.acme.productionUrl`; empty keeps the Let's Encrypt production default. |
| `settingsacmestagingurl` | HTTPS URL string; empty | Optional `settings.acme.stagingUrl`; empty keeps the Let's Encrypt staging default. |
| `realm` | String; `SharkTrust Service` | Authentication realm. Preserve it when migrating existing zone-owner password hashes. |

The name-server names must resolve before startup. `settingsdn` remains a DNS
hostname for an on-premises deployment; the private address belongs in `settingsip`.

### Email

| Variable | Type; default | Meaning |
| --- | --- | --- |
| `emailserver` | Hostname string; placeholder `your-mail-server` | Required SMTP server; replace the placeholder. |
| `emailport` | Integer; `465` | SMTP TCP port, 1-65535. |
| `emailconsec` | String; `tls` | `tls` for TLS from connection start, or `starttls` for an SMTP TLS upgrade. |
| `emailuseauth` | Boolean; `true` | Whether SMTP authentication is used. |
| `emailuser` | String; example `no-reply@realtimelogic.com` | SMTP username, required when authentication is enabled. |
| `emailpassword` | String; placeholder `CHANGE_ME` | SMTP credential, required when authentication is enabled. Keep outside Git. |
| `emailfrom` | Email string; example `no-reply@realtimelogic.com` | Sender allowed by your mail provider; replace for your installation. |
| `emailto` | Email string; placeholder `log-file-receiver` | One operational contact address. Also used for ACME account registration. |
| `emailsubject` | String; `SharkTrust Server` | Normal operational log email subject. Error notifications may use a specific subject. |
| `emailsignature` | String; `Sent from SharkTrust` | Text signature for portal email. |

The template writes `log.logerr=true`, the SMTP table, and `log.signature`.
SMTP acceptance is not confirmation of inbox delivery; use **Test email** and
check the recipient's mailbox.

## Server preparation options

These values belong to
[ansible/NewMachine/vars.yaml](../ansible/NewMachine/vars.yaml).
They affect the optional account/server preparation playbook, not the main
portal playbook.

| Variable | Type; default | Meaning |
| --- | --- | --- |
| `onlineuser` | Linux username string; `rtl` | Non-root deployment account to create. |
| `deployment_public_key_file` | Controller path string | Wrapper selects `id_ed25519.pub` or `id_rsa.pub`, or its explicit second argument. Direct playbook use defaults to `~/.ssh/id_rsa.pub` unless overridden. |
| `ansible_python_interpreter` | Target path string; `/usr/bin/python3` | Python used after bootstrap. |
| `apt_lock_timeout` | Integer seconds; `300` | Package-manager lock wait. |
| `bootstrap_packages` | List of package strings; `[sudo, ca-certificates]` | Packages installed after Python bootstrap. |
| `perform_dist_upgrade` | Boolean; `false` | Upgrade the distribution's installed packages. |
| `configure_unattended_upgrades` | Boolean; `false` | Install and configure automatic system updates. |
| `configure_firewall` | Boolean; `false` | Configure and enable UFW. |
| `install_fail2ban` | Boolean; `false` | Install and start fail2ban. |
| `disable_root_ssh` | Boolean; `false` | Set `PermitRootLogin no`. Verify deployment-key access first. |
| `remove_conflicting_packages` | Boolean; `false` | Remove the configured package list. |
| `ssh_port` | Integer port; `22` | Port allowed by the optional firewall. For SSH transport on another port, also configure `ansible_port` or SSH configuration. |
| `ssh_service_name` | Service-name string; `ssh` | Service reloaded after SSH configuration changes. |
| `firewall_allowed_tcp_ports` | List of ports; SSH port, `53`, `80`, `443` | TCP services allowed by optional UFW tasks. |
| `firewall_allowed_udp_ports` | List of ports; `[53]` | UDP services allowed by optional UFW tasks. |
| `conflicting_packages` | List of package strings; `[sendmail, apache2]` | Removed only when the removal option is enabled. |

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

These runtime fields belong to the existing `settings` table in `mako.conf`. Keep the
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
and logout use session-bound tokens to prevent cross-site request forgery (CSRF).
Password recovery requires the email
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

The engine submits orders with ACME terms acceptance enabled. Review the
selected provider's terms before configuring its directory. There is no browser
prompt for each certificate order.

## Set or reset the portal administrator

Stop the existing Mako instance, then run it with its usual configuration and
the optional `-credentials` argument. For example, from the configured Mako
working directory:

```bash
# On the target server; stop the service before resetting its account.
sudo systemctl stop SharkTrust
cd /opt/SharkTrust
sudo /usr/local/bin/mako -c /opt/SharkTrust/mako.conf \
  -credentials 'admin@example.com:REPLACE_WITH_YOUR_PASSWORD'
# After successful completion, start the service without the credential option.
sudo systemctl start SharkTrust
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

## Runtime and existing data

Use a Mako Server with BAS 6375 or newer and matching resources providing
`acme/engine.create` and `renewalInfo`. The installer also probes certificate-time
parsing, PBKDF2, and SQLite. The application uses exportable software keys because
it sends device private keys to the corresponding clients.

See [operations and upgrades](operations.md) for backup, legacy JSON import,
certificate profile migration, and safe updates. The [storage reference](data-structures.md)
describes the database and certificate files. Follow the [on-premises guide](on-premises.md)
when `settings.ip` is a private address.
