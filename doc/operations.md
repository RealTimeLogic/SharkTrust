# Operate and upgrade SharkTrust

[Manual index](README.md) | [Configuration](portal.md) | [Troubleshooting](troubleshooting.md)

The portal maintains DNS records and renews certificates without an operator
issuing each certificate manually. Operators still need working DNS, SMTP,
CA connectivity, protected backups, and clients that fetch renewed credentials.

## Service control and monitoring

The Ansible installation uses `SharkTrust.service` for the portal and
`named.service` for BIND. Run on the target:

```bash
# Inspect both services before restarting a failing installation.
sudo systemctl status SharkTrust named --no-pager
sudo journalctl -u SharkTrust -u named -n 100 --no-pager
sudo tail -n 100 /var/log/mako.log
```

Use `sudo systemctl stop SharkTrust`, `start SharkTrust`, or `restart SharkTrust`
for normal service control. For boot activation, use
`sudo systemctl enable SharkTrust`. The supplied service restarts failed portal
processes after three seconds. Inspect logs before restarting; the Mako log can
be truncated on a new start.

On the portal, **Certificate service** shows the configured CA directory,
production/staging selection, and pending certificate/DNS retries. **Test email**
checks SMTP acceptance. The zone's device details show the last contact and the
portal's stored certificate expiry. Check actual device HTTPS as well: an issued
certificate at the portal does not prove that the device installed it.

For foreground diagnosis, stop the service first, change to `/opt/SharkTrust`,
and run `/usr/local/bin/mako -c /opt/SharkTrust/mako.conf` with sudo. Do not run
two instances against the same home directory. Stop the foreground process
before starting systemd again.

## Certificate lifecycle

Public-mode service names use HTTP-01 validation. Registered zone apex names
and devices use DNS-01. Private-mode static service names only load their saved
certificates; see [on-premises HTTPS](on-premises.md#bootstrap-administration-and-trusted-https).

The portal can run four device certificate orders concurrently. Each order owns
its ACME engine and challenge; DNS rewrites retain all active TXT challenges,
including when an address changes during issuance. Portal-hostname orders are
processed serially. Existing device private keys are reused during renewal.

For managed portal and device certificates, ACME Renewal Information (ARI)
selects a random time in the CA's suggested renewal window. SQLite saves that
time with the certificate fingerprint and CA profile. An unchanged window
retains the selection across restarts; a changed window selects a new time.
Replacement orders include the previous certificate's ARI identifier when
available.

Without usable ARI, the renewal lead time is the smaller of **22 days** or
**one third of the certificate's actual validity period**. This adapts to
shorter certificates without assuming a fixed 90-day lifetime. An ARI failure
does not postpone an already selected earlier renewal. Expired certificates
do not wait for an ARI lookup.

ARI check intervals are bounded to one minute through one day. Missing or
invalid ARI is checked again after six hours. The normal certificate scans
process the schedule, with at most four ARI lookups in progress. No extra
operator setting is required.

Failed certificate orders retry after 1, 5, 15, and 60 minutes, then every six
hours. Success resets the delay. DNS configuration/reload failures retry every
30 seconds. Startup regenerates DNS files from the database. Repeated errors
need investigation while the previous certificate is still valid.

Devices must retrieve and install replacements. The OpenSSL `--watch` example
and updated Minnow example poll no later than 12 hours after a successful
fetch, sooner for short remaining lifetimes. The OpenSSL example saves
`DeviceCert.pem` and `DeviceKey.pem`; its application integration owns web-server
reload and any stronger storage guarantees. See the
[client guide](../examples/README.md) for the exact example behavior.

## Back up a consistent installation

Stop the portal before a filesystem backup. Save configuration, **both `data`
and `cert` together**, the application/runtime versions, and the BIND/service
configuration. The database alone does not contain the certificate private keys.

For the standard installation, the following stores a complete archive in a
root-only backup directory:

```bash
# Run on the target during a maintenance window.
sudo systemctl stop SharkTrust
sudo install -d -m 700 /var/backups/sharktrust
sudo tar -C / -czf "/var/backups/sharktrust/portal-$(date -u +%Y%m%dT%H%M%SZ).tar.gz" \
  opt/SharkTrust etc/bind etc/systemd/system/SharkTrust.service \
  usr/local/bin/mako usr/local/bin/mako.zip
# Check tar's exit status before restarting or copying the archive off the host.
sudo systemctl start SharkTrust
```

Protect the archive as carefully as the running portal. It includes enrollment
credentials, device private keys, ACME account keys, SMTP configuration, and any
Entra client secret. Keep an access-controlled off-host copy and test restoration
on an isolated machine; do not run a restored clone as a second writer for the
same live DNS service.

For recovery, stop the affected portal, restore the corresponding code/runtime,
configuration, `data`, and `cert` set, restore ownership and permissions, check
BIND access, then start and verify DNS, HTTPS, SMTP, and a known device. A restore
from before recent enrollments will lose those registrations. Timestamped
Ansible backups of individual code files do not replace a consistent state backup.

## Upgrade with Ansible

1. Read the change and choose a reviewed Git revision and compatible Mako archive.
2. Back up the stopped installation as above. Keep the configuration and runtime
   paired with the data for rollback.
3. On the controller, update the installer checkout. In the private variables
   file, set `GitSharkTrustVersion` to the chosen revision and update the Mako
   archive/checksum if needed.
4. Leave `replace_mako_conf: false` to preserve site settings. If configuration
   needs changing, first reconcile all current settings with the template, then
   explicitly set it to `true` for that run.
5. Choose `start_portal: true` to enable/start after installation, or `false`
   to leave it stopped for inspection. The latter also disables boot startup.
6. Run the same [installer command](installation.md#6-run-the-installer), then
   perform the [acceptance checks](installation.md#8-verify-the-installation).

The target packages the selected Git checkout's `www` contents. It preserves
`data`, `cert`, and an existing `mako.conf` by default. Replaced application ZIPs
and runtime files receive timestamped backups. A retained configuration must
load `/opt/SharkTrust/SharkTrust.zip` (or the equivalent relative package path).
An old configuration pointing at `www` must be reviewed and replaced.

To deploy a local portal build instead of Git, package the contents of `www`
including hidden files, then set the controller path in `portal_local_archive`:

```bash
# Run on the controller from the repository root.
(cd www && zip -qr /tmp/SharkTrust.zip .)
# Set portal_local_archive: /tmp/SharkTrust.zip in your private variables file.
```

## Migrate an older installation

The installer does not automatically move a legacy `/var` installation. First
back up and stop the old service, including any older service manager, and keep
it from starting alongside systemd. Install the new portal stopped. Copy the
old home's complete `data` and `cert` directories into the new home's matching
locations, retaining private permissions. Carry over the DNS, SMTP, authentication
realm, and CA settings through the reviewed new configuration. Keep the new
package-loading path and service unit.

On first database initialization, the portal imports related zone/device JSON
files in one transaction and checks their relationships. Zone keys, device keys,
names, and owner password hashes are retained. An orphaned or invalid record
stops migration instead of activating partial state; correct the reported
source data and retry. The [storage reference](data-structures.md#legacy-import)
lists the imported files.

After schema version 1 exists, SQLite is authoritative. Old JSON files remain
unchanged and are no longer live state. Do not edit them expecting to change the
portal. To roll back to a JSON-based version, restore the complete pre-upgrade
backup; retained JSON files do not include later activity.

### Certificate profiles and legacy PEM files

Certificates are separated by CA directory URL and production/staging flag.
Changing either selects a different profile; switching back reuses that profile's
keys and certificates. ACME accounts are stored per directory URL. A malformed
saved account stops startup rather than being silently replaced.

Legacy PEM files are copied into a profile only when their saved account matches
the selected CA/environment, or for the original default Let's Encrypt production
configuration with no saved account. For another known legacy CA, set
`settings.acme.importLegacy=true` once after confirming the files' origin.
`cert/legacy-profile.json` records the association so another CA cannot later
claim the same originals. Remove that temporary configuration override after
migration. Original PEM files are retained.

## Customize the dashboard

The portal uses a framework-free dashboard shell with dark neutral surfaces,
green primary actions, and yellow links, matching the current SharkTrustX theme.
Edit the [stylesheet](../www/assets/style.css),
[shared template](../www/.lua/www/template.lsp), and
[page menus](../www/.lua/www/zones.json) in your source checkout. Keep credential
checks and form CSRF fields when changing markup.

Review the [service agreement](../www/license.html) and registration/email text
for your deployment. Build and deploy a new application package after edits;
changing the target's source checkout does not change the installed ZIP by itself.
