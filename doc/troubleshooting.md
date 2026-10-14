# Troubleshoot SharkTrust

[Manual index](README.md) | [Installation](installation.md) | [Operations](operations.md)

Start with the failed operation and the corresponding server log. An active
systemd process, successful account email, or existing certificate does not
establish that the latest DNS change or renewal succeeded.

## Collect the relevant evidence

On the portal server:

```bash
# Capture logs before a restart, which can truncate the Mako log.
sudo systemctl status SharkTrust named --no-pager
sudo journalctl -u SharkTrust -u named -n 100 --no-pager
sudo tail -n 100 /var/log/mako.log
sudo rndc status
sudo runuser -u bind -- named-checkconf -z
```

Keep the timestamp, affected hostname, reported error, and operation that
triggered it. Remove passwords, zone/device keys, private-key PEMs, Entra
secrets, and tokens before sharing diagnostics. The **Certificate service**
page shows the CA selection and pending retries.

## Installation or startup failures

| Symptom | Check and corrective action |
| --- | --- |
| Ansible reports an unsupported OS, architecture, or service manager | The provided installer requires x86-64 Debian/Ubuntu with systemd. Use a matching target. |
| `ansible-playbook` or a collection is missing | Check the controller's PATH and Python environment, then install the two requirements files from the installation guide. On Windows, use WSL2. |
| SSH host-key verification fails | Confirm the target fingerprint through a trusted console/provider before updating the known-host record. Do not disable host-key checking. |
| SSH succeeds but sudo fails | Check `ssh rtl@portal.example.com sudo -n true` using the actual deployment account. The main playbook requires privilege escalation. |
| `apt` cache refresh fails | Inspect the named repository, connectivity, and system clock. Correct an unavailable or obsolete source before rerunning; an unrelated repository failure can block package installation. |
| Runtime checksum mismatch | Confirm the selected archive and publisher's digest. Keep the `sha256:` prefix and all 64 hexadecimal characters. |
| Runtime API probe fails | Install a matching executable/resource pair with the required SQLite, crypto, certificate-time, ACME engine, and ARI APIs. A new executable with an old `mako.zip` is insufficient. |
| Retained configuration does not load `SharkTrust.zip` | Review its site settings and the installer template, then use `replace_mako_conf: true` for that run. Do not replace a live configuration with unreviewed defaults. |
| Service exits before startup or `rndc status` fails | Check BIND health, its control configuration, and zone readability. The unit checks `rndc` before launching Mako. |
| Portal says it cannot resolve an IP address | Resolve both configured name-server names using the host resolver. Set `settings.ip` explicitly on multihomed/NAT systems. Do not use authoritative-only BIND as the only recursive resolver. |
| Port 80/443 is already in use | Stop or reconfigure the conflicting service. The Linux portal expects both default ports. |
| Portal is stopped after Ansible completes | `start_portal: false` is the default and also stops/disables an existing service. Set credentials before first start; set the option deliberately for later runs. |
| Credential command does not save or exits with an error | Run the installed `/usr/local/bin/mako` with the correct `-c` path, one `username:password` argument, and no `-s`/`-d`. Check permissions and password format. Successful setup prints confirmation and exits 0. |

## Zone delegation is not confirmed

Registration checks NS records returned by the parent zone, not WHOIS.
A subdomain such as `st.sharkssl.com` is delegated in the parent `sharkssl.com`
DNS zone; it does not need its own registrar WHOIS record.

Run the same lookup used by the portal, ideally from the portal host:

```bash
# Substitute the exact zone being registered; retain the unfiltered output.
dig -r -4 @8.8.8.8 +trace +nodnssec +time=2 +tries=1 NS devices.example.com
```

The parent must return both configured name-server names for the exact zone.
Adding A records or NS records only inside the child zone does not establish
parent delegation. Nameserver targets should be hostnames, not IP addresses.
DNS caches can retain previous answers until their TTL expires.

The final child query may fail before registration creates the zone. That is
different from a trace that never reaches the parent. For the latter, check
that `dig` is installed and outbound UDP/TCP 53 can reach `8.8.8.8`, root servers,
and the authoritative servers along the trace. WHOIS is not a fallback.

Errors about IPv6 addresses of root or other authoritative servers during an
unrestricted trace concern the lookup computer's IPv6 transport. They do not
mean your zone needs an AAAA record. `-4` uses IPv4 for the trace.

## Registration succeeds but DNS is broken

Once the portal has created the zone, query its authoritative servers directly
from a machine outside the portal network as well as from the local network:

```bash
# The zone should answer authoritatively over both UDP and TCP.
dig -4 @ns1.example.com devices.example.com SOA +norecurse
dig -4 +tcp @ns1.example.com devices.example.com SOA +norecurse
dig -4 @ns2.example.com devices.example.com NS +norecurse
dig -4 +tcp @ns2.example.com devices.example.com NS +norecurse
```

Look for `status: NOERROR`, the authoritative-answer (`aa`) flag, and the
expected zone data. Timeouts suggest routing/firewall/forwarding problems.
`SERVFAIL` requires checking the BIND log and configuration. Also verify the
device's A record after registration.

The portal uses `UMask=0077` for private files but explicitly makes generated
zone files and `named.conf.local` readable by BIND. Keep `/etc/bind/zones`
traversable and its `.db` files mode `0644`; do not loosen permissions on
`/opt/SharkTrust/data` or certificate private keys to fix a DNS permission error.
The installer repairs public DNS-file permissions and checks loading as `bind`.

`DNS configuration reload pending` or a zone-update error can follow a committed
database change. The portal retries DNS work every 30 seconds. Fix the cause
and verify actual answers; repeated registration is not the remedy. Do not hand
edit generated zone files because the portal will regenerate them.

## Certificate warnings

| Where the warning occurs | Check |
| --- | --- |
| Public portal hostname | Its A record, any published AAAA record, public TCP 80 reachability, selected CA/environment, and `Portal certificate ...` errors. Initial issuance can temporarily leave the fallback certificate in use. |
| On-premises service hostname | Private mode does not request static HTTP-01 certificates. Follow the [HTTPS bootstrap options](on-premises.md#bootstrap-administration-and-trusted-https). |
| Registered zone hostname | Public delegation, authoritative answers, DNS-01 TXT publication, and CA errors. The account email is delayed on a timer, not gated on certificate success. |
| Device hostname | Confirm its DNS address, usable downloaded certificate/key, matching hostname, complete chain, and web-server reload. The portal may have renewed a certificate the device has not fetched. |
| Every certificate after testing | Check for a staging CA or a private CA whose root is not installed on the relying clients. |

To inspect a public portal from a Linux checking machine with OpenSSL:

```bash
# Verification must succeed for this hostname and the local trust store.
openssl s_client -connect portal.example.com:443 -servername portal.example.com \
  -verify_hostname portal.example.com -verify_return_error </dev/null
```

For a private CA, supply its trusted CA file to the checking tool rather than
disabling verification. Check the client/server clock when validity checks fail.
Selecting a different CA or switching staging/production selects a separate
certificate profile; it does not convert previously issued certificates.

The current ACME engine rejects CAs that require External Account Binding.
Use a compatible directory and verify its supported challenges and algorithms.
Inspect CA-provided order errors for validation failures or rate limits.
Certificate retries back off up to six hours; do not delete accounts or device
credentials repeatedly to force new orders.

## Email errors and missing messages

An account-information email and an operational error email describe different
events. Receiving one does not mean a certificate or DNS error in the other has
recovered. Match each message's target name and timestamp with the local log.

| Message or symptom | Meaning and next step |
| --- | --- |
| `SharkTrust E-Mail Validation` | Continue registration using the supplied key within one hour. Request a new key after expiry or a portal restart. |
| `SharkTrust Account Information: <zone>` | Save the account's zone key and URL. Verify HTTPS separately. |
| Repeated `SharkTrust Error` messages | Read the actual error. Certificate/DNS retries may repeat a persistent failure; correct its cause and verify recovery rather than treating account creation as success. |
| Test email reports SMTP acceptance, but no mail arrives | Check the recipient, spam/quarantine, provider delivery logs, sender authorization, and mailbox policy. Acceptance is not inbox delivery. |
| Test email fails or local trace says `sendmail failed` | Check SMTP host/port, TLS mode, authentication, outbound firewall, system DNS, and the provider's accepted sender. SMTP errors may not be deliverable by email themselves. |
| No credential verification or recovery email | Check the zone owner's address and SMTP delivery. A recovery response is deliberately generic when an email does not match. Retry the action after fixing delivery. |
| Verification code is rejected | Use the code for that action in the original session; check its expiry/attempt limit. Request another after the resend delay. |

There is no durable outgoing-email queue in the portal. After fixing SMTP,
repeat the requested registration, verification, or recovery action as needed.
Do not assume a lost message will be redelivered automatically.

## Device problems

| Symptom | Check and action |
| --- | --- |
| `No Devices` on the public zone page | Discovery is filtered by the source address seen by the portal. Sign in and open **Manage** to check all registrations; VPNs/proxies or direct on-premises connections can affect the grouping. |
| Device link resolves but cannot connect | Check the published address, local routing, firewall, listener port, and whether a resolver blocks public names with private addresses. A certificate does not create network reachability. |
| `Forbidden` | Confirm the portal hostname and zone credential. A device key from another zone cannot be reused. |
| `Unknown` | The registration no longer exists. Register once and persist the replacement key. |
| `Processing` persists | Check CA/DNS retries on the portal. Keep polling; do not generate a new registration on every retry. |
| Names keep gaining numeric suffixes after reboot | The device is losing or not reusing its saved device key. Use one persistent credential per device and zone. |
| Header changed but example still uses the old zone | Rebuild after replacing `getzkey.ch`; the generated-key Make target depends on it. Run in a new private working directory for a different zone. |
| Certificate download succeeds but device TLS fails | Check the certificate/key pair, web-server installation/reload, hostname, trust chain, expiry, and clock. OpenSSL example files do not automatically configure your web server. |

## Microsoft Entra sign-in problems

Use a zone account with a local password while investigating. Verify the
single-tenant Web application, the exact `https://<zone>/sso` redirect URI,
tenant/client IDs, and the user's matching email and object ID. No user is
automatically enrolled by Entra.

An invalid or expired client-secret error requires a new valid secret **Value**
and its expiration date in **Users and sign-in**. An issuer, signature, nonce,
or time validation error is a different failure: check the indicated identity
configuration, signing-key retrieval, and clock. Do not disable validation.
Repeated metadata/keys refresh failures require checking outbound HTTPS, DNS,
and trust. Restarting alone does not repair incorrect settings or an expired secret.
