# SharkTrust Ansible installer

Use the [installation guide](../doc/installation.md) for the complete controller,
DNS, server, deployment, and first-start procedure. Run Ansible on Linux or
**WSL2** on Windows.

| Playbook | Purpose |
| --- | --- |
| [NewMachine/main.yaml](NewMachine/main.yaml) | Optional preparation: bootstrap Python, create a deployment account, install its SSH public key, and configure passwordless sudo. |
| [SharkTrust/main.yaml](SharkTrust/main.yaml) | Install the portal, matched Mako runtime, BIND9 tools/configuration, and systemd service on a dedicated x86-64 Debian/Ubuntu server. |

The main installer deploys under `/opt/SharkTrust` and leaves the portal stopped
by default. BIND starts during installation. Set administrator credentials
before starting the portal. On upgrades, `start_portal: false` also stops and
disables an existing service.

See the [configuration reference](../doc/portal.md#installer-variables) for
variable types/defaults, runtime archives and checksums, CA selection, SMTP,
and the optional server-preparation settings. Keep deployment secrets outside
Git or in Ansible Vault. Follow [operations and upgrades](../doc/operations.md)
for state preservation, backups, and migration.
