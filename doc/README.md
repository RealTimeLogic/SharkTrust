# SharkTrust manual

SharkTrust manages DNS names and TLS certificates for embedded web interfaces.
Use this manual to run a portal, register a product or customer zone, and connect
devices. For the product overview, start with the [project README](../README.md).

## Choose your starting point

- **Try a client:** use the [shared test zone](../examples/README.md#try-the-shared-test-zone).
  You do not need to install a portal or register a zone.
- **Manage your own device namespace:** follow the [user manual](user-guide.md),
  then [integrate a C client](../examples/README.md).
- **Host the service:** follow [installation with Ansible](installation.md),
  including the [on-premises guide](on-premises.md) when applicable.

## Chapters

| Chapter | What you will learn |
| --- | --- |
| [User manual](user-guide.md) | DNS delegation, zone registration, device discovery, credentials, roles, Microsoft Entra sign-in, cleanup, and recovery. |
| [Installation with Ansible](installation.md) | Controller and server requirements, DNS preparation, playbooks, first start, and acceptance checks. |
| [On-premises installations](on-premises.md) | Private addressing, local DNS, public CA reachability, and trusted HTTPS endpoints. |
| [Portal configuration](portal.md) | Ansible variables, Mako settings, administrator credentials, and compatible ACME CAs. |
| [Operations and upgrades](operations.md) | Monitoring, certificate renewal, backups, updates, legacy migration, and customization. |
| [Troubleshooting](troubleshooting.md) | Diagnose installation, DNS, TLS, SMTP, and client problems. |
| [Architecture](architecture.md) | Service components, routing, certificate flow, and trust boundaries. |
| [Device protocol](SharkTrust-Protocol.md) | The current binary protocol implemented by the portal and C examples. |
| [Stored data](data-structures.md) | Database schema, certificate files, renewal schedules, and data import. |
| [C client integration](../examples/README.md) | Build and adapt the examples, use your own zone, and install renewed credentials. |

These chapters document this repository's implementation. The installation and
zone-management sequence follows the approach used in the related
[SharkTrustX installation article](https://realtimelogic.com/articles/Installing-the-SharkTrustX-Portal)
and [zone-management article](https://realtimelogic.com/articles/SharkTrustX-Zone-Management).
Use the commands and client credentials in this manual for SharkTrust.

## Names used in the examples

| Name | Meaning |
| --- | --- |
| `portal.example.com` | Service hostname for registration, portal administration, and the device API. |
| `ns1.example.com`, `ns2.example.com` | Authoritative name servers for delegated zones. |
| `devices.example.com` | A registered zone, also serving that zone's web interface. |
| `controller.devices.example.com` | A device name; it resolves to the address published for that device. |
| `sharktrust.realtimelogic.com` | Real Time Logic's test portal endpoint. |
| `st.sharkssl.com` | Shared test device zone used by the bundled C credential file. |

Replace the `example.com` names and documentation-only addresses with your own.
The service hostname and device zone are separate settings: changing a zone
credential does not require changing the portal hostname when both zones use
the same portal.
