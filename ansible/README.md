# SharkTrust Ansible installer

Install the SharkTrust portal and Mako/BIND dependencies under
`/opt/SharkTrust`. The two playbooks prepare a deployment account and install
the portal. Run them only when ready to change the target server.

The portal stays stopped by default for command-line credential setup.

## Requirements

Use a dedicated x86-64 Debian or Ubuntu server with systemd. The portal owns
`/etc/bind/named.conf.local`. The installer configures BIND for authoritative
DNS, with public queries allowed and recursion disabled. Do not use it on a
shared DNS server.

It installs BIND9, `bind9-utils` (`rndc` and configuration checks),
`bind9-dnsutils` (`dig`), CA certificates, Python 3, Git, tar, unzip, coreutils,
libc-bin, and util-linux. It checks zone readability as the `bind` user and `rndc status`
before activation. The host resolver must also resolve the configured portal
and nameserver names; it must not rely on this authoritative-only BIND for
recursive lookups. The service uses `UMask=0077`; generated public DNS files
receive readable permissions without relaxing access to private keys.

Allow inbound TCP and UDP port 53, TCP ports 80 and 443, and your SSH port in
both host and cloud firewalls. The optional `NewMachine` firewall tasks include
these ports. Outbound UDP and TCP port 53 must reach arbitrary authoritative
servers for `dig -4 +trace`. Also allow outbound HTTPS for ACME/downloads and
TCP to your configured SMTP host and port.

Both nameserver names and the service name must resolve to the portal. Public
installations need port 80 reachable by the CA. On-premises installations set
`settingsip` to the LAN IPv4 address; public delegation and port forwarding
must still let the CA query the authoritative DNS service.

## Controller setup and server preparation

Run on Linux or **Ubuntu-22.04 WSL2** on Windows. Use Linux paths for local
archives. Install Ansible and the required collections:

```bash
# Run from the installer root on the controller.
sudo apt-get install pipx sshpass zip
pipx install ansible --include-deps
pipx ensurepath
ansible-galaxy collection install -r NewMachine/requirements.yml
ansible-galaxy collection install -r SharkTrust/requirements.yml
```

Use a current Ansible release. Validation used ansible-core 2.21.3.
Confirm the server's SSH host-key fingerprint through your VPS provider and
connect once with SSH before running either script. Host-key checking remains
enabled.

Edit `NewMachine/vars.yaml`, then prepare a fresh VPS:

```bash
# The script asks for the VPS's initial root password.
cd NewMachine
bash main.sh portal.example.com
```

The script selects `id_ed25519.pub` or `id_rsa.pub` in your controller's SSH
directory. Pass another public-key path as its second argument. It installs
Python, sudo, and CA certificates, then creates a deployment account with
SSH-key access and passwordless sudo.

The boolean options `perform_dist_upgrade`, `configure_unattended_upgrades`,
`configure_firewall`, `install_fail2ban`, `disable_root_ssh`, and
`remove_conflicting_packages` default to `false`. Verify SSH-key login and
`sudo -n true` as the deployment user before disabling root SSH.
Installing required packages can still upgrade BIND dependencies and restart
DNS even when full distribution upgrades are disabled.

## Install or upgrade

Edit `SharkTrust/vars.yaml`. Keep passwords outside Git; use Ansible Vault or an
untracked extra-vars file. The wrapper forwards additional Ansible options:

```bash
# From the installer root; replace the hostname and SSH deployment account.
cd SharkTrust
bash main.sh portal.example.com rtl -e @/private/portal-vars.yaml
```

| Setting | Type and default | Purpose |
| --- | --- | --- |
| `ansible_user` | String, `rtl` | SSH account; the wrapper's second argument overrides it. |
| `replace_mako_conf` | Boolean, `false` | Preserve configuration; `true` replaces it from reviewed variables with a timestamped backup. |
| `start_portal` | Boolean, `false` | Enable/start the service. `false` also stops/disables an existing service. |
| `portal_local_archive` | String, empty | Controller-local ZIP; otherwise use Git. |
| `GitSharkTrust`, `GitSharkTrustVersion`, `SharkTrustSourceDir` | Strings; see `vars.yaml` | Source repository, revision, and dedicated checkout directory. |
| `mako_local_archive` | String, empty | Controller-local x86-64 Linux tar.gz containing `mako` and `mako.zip` at its root. |
| `mako_download_url` | String, empty | HTTPS release URL when no local archive is supplied. Configure one source. |
| `mako_archive_checksum` | String, required | `sha256:` followed by the release archive's 64 hexadecimal digest characters. |
| `settingsns1`, `settingsns2`, `settingsdn` | Strings; example names in `vars.yaml` | Two nameserver names and the portal HTTPS name. Replace for your installation. |
| `settingsip` | String, empty | Explicit portal IPv4 address; use its LAN address for on-premises operation. |
| `settingsacmeproduction`, `settingsacmersa` | Booleans, `true`, `false` | Production/staging CA and RSA/ECC key selection. |
| `settingsacmeproductionurl`, `settingsacmestagingurl` | Strings, empty | Optional HTTPS directories for a compatible ACME CA. |
| `realm` | String, `"SharkTrust Service"` | Authentication realm. |
| `emailserver`, `emailuser`, `emailpassword`, `emailfrom`, `emailto` | Strings; placeholders in `vars.yaml` | SMTP host, authentication, sender, and operational contact/CA email. Replace placeholders. |
| `emailport`, `emailconsec`, `emailuseauth` | Integer `465`, string `"tls"`, boolean `true` | Port 1-65535, `tls` or `starttls`, and SMTP authentication. |
| `emailsubject`, `emailsignature` | Strings; product-name defaults | Operational email subject and signature. |

The Mako archive is checksum-verified and checked for the required Lua, SQLite,
and ACME APIs without starting the portal or requesting certificates. The
portal package must contain the DNS delegation and BIND permission fixes.
Use a Git revision containing these changes, or provide a local package:

```bash
# Run in the portal checkout's www directory, including hidden Lua files.
zip -qr /tmp/SharkTrust.zip .
# Set portal_local_archive to /tmp/SharkTrust.zip in the installer variables.
```

Only application code is packaged. Configuration, databases, certificates,
and ACME accounts stay under `/opt/SharkTrust` and are preserved on upgrades.
Replaced application packages and runtime files receive timestamped backups.
The installer does not migrate a legacy `/var` installation.

If an existing `mako.conf` loads a `www` directory, copy its settings into the
installer variables and set `replace_mako_conf: true`. The generated
configuration loads `/opt/SharkTrust/SharkTrust.zip`. A preserved configuration
pointing elsewhere is rejected.

## Validation

```bash
# Parse the playbooks without connecting to a deployment target.
ansible-playbook -i localhost, --syntax-check NewMachine/main.yaml
ansible-playbook -i localhost, --syntax-check SharkTrust/main.yaml
```

Local checks do not establish public DNS delegation, SMTP delivery, real CA
issuance, or reboot behavior. After deployment, check `systemctl status SharkTrust named`,
portal logs, authoritative DNS, and HTTPS certificate validation. HTTPS may
initially serve Mako's fallback certificate while the CA issues a certificate.

## Set credentials and start SharkTrust

After installation, run on the server:

```bash
# Stop first when resetting credentials on an existing installation.
sudo systemctl stop SharkTrust
cd /opt/SharkTrust
sudo /usr/local/bin/mako -c /opt/SharkTrust/mako.conf -credentials 'admin@example.com:REPLACE_WITH_YOUR_PASSWORD'
# The credential command saves the password hash and exits.
sudo systemctl enable --now SharkTrust
```

Set `start_portal: true` for later installer runs that should leave it running.
The installer requires a saved administrator record before starting.
No administrator password is stored in `vars.yaml` or `mako.conf`.

`settingsacmedirectoryurl` is an optional string, empty by default, with an
HTTPS ACME directory URL. When set, it overrides the selected production or
staging URL. The current BAS engine does not support providers that require
External Account Binding.

See [Portal configuration](../doc/portal.md) for on-premises routing,
compatible CAs, and certificate renewal.
