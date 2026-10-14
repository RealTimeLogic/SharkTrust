# SharkTrust C client examples

SharkTrust gives an embedded web server a domain name and a TLS certificate.
The portal registers the device, updates its DNS address, and obtains and renews
the certificate through the configured ACME certificate authority (CA). These
clients download the certificate and private key over an authenticated TLS
connection. They do not implement ACME themselves.

Use the OpenSSL examples below to fetch credentials for an existing web server.
The [Minnow Server example](#minnow-server-example) also runs an HTTPS server and
installs downloaded credentials in memory. These are small integration examples;
adapt their socket, storage, and scheduling code to your application.

## Prepare your zone

Before running a client, configure a SharkTrust portal and register a DNS zone
you control. See [portal configuration](../doc/portal.md) for public and private
on-premises installations and CA selection.

1. Delegate the zone to the DNS servers specified by your portal operator.
   For a subdomain, add the delegation at its parent zone. Wait until the
   delegation resolves correctly; there is no fixed propagation time.
2. Open the portal, register the zone, and sign in as its owner.
3. Reveal the zone key or download the generated C header. Both actions require
   the verification code sent to the owner's email address.
4. Create a private working directory for this device and zone. Do not share
   its registration file with another device or reuse it with another zone.

The prepared test zone is **`st.sharkssl.com`**. The clients still connect to
**`sharktrust.realtimelogic.com`**. Once the portal and zone are ready, use the
zone key or generated header for `st.sharkssl.com` to receive a name such as
`device.st.sharkssl.com`. The zone key selects the namespace; the client does
not append the zone name itself. Use a new working directory when changing zones.

The device's IPv4 address must be reachable from the browser that will access
it. A private LAN address is expected for an intranet web interface. Publicly
trusted certificates require a publicly valid domain and successful CA
validation, even when the portal or device is on premises. A private CA requires
its trust root on the browsers and other clients that use the device.

## Build the OpenSSL client

The examples require a POSIX environment, a C compiler, and OpenSSL 1.1.1 or
later development headers and libraries. On Windows, use WSL with these
dependencies installed. Run the build commands from this `examples` directory.

Edit these settings near the top of `SharkTrust-Client.c` before building either
variant:

| Setting | Type, default, and purpose |
| --- | --- |
| `SHARK_TRUST_SERVICE_NAME` | DNS hostname string macro; defaults to `sharktrust.realtimelogic.com`, HTTPS port 443. Change for a private portal. |
| `caFile` | Optional PEM CA file path string; `NULL` uses OpenSSL's system trust roots. |
| `deviceName` | DNS-label string; defaults to `"device"`. Use 1-63 lowercase letters, digits, or hyphens, with no leading or trailing hyphen. The portal may add a numeric suffix. |
| `deviceIp` | Optional IPv4 string; `NULL` uses the portal connection's local address. Set it when the device is reachable at a different address. |

```sh
# Build the plain-key variant. No zone credential is needed to compile it.
cc -std=c99 -Wall -Wextra -o SharkTrust-Client SharkTrust-Client.c -lssl -lcrypto
```

The generated-key variant uses the same implementation. Download your zone's
`getzkey.ch` into this directory before building it:

```sh
# Compile this entry point alone; it includes SharkTrust-Client.c.
cc -std=c99 -Wall -Wextra -o SharkTrust-Client-Obfuscated-Key \
  SharkTrust-Client-Obfuscated-Key.c -lssl -lcrypto
```

The repository no longer supplies a working shared demo zone key. The generated
header is excluded by `.gitignore`; keep it private. Obfuscation makes a key
less apparent in an executable; it does not prevent extraction from firmware
or a running process.

## Fetch a certificate

Run one client process per private working directory. The following Bash
example uses the plain-key variant and prompts without placing the zone key in
the command history:

```bash
# Use an absolute executable path if your working directory is elsewhere.
umask 077
read -r -s -p 'Zone key: ' SHARK_TRUST_ZONE_KEY
printf '\n'
export SHARK_TRUST_ZONE_KEY
./SharkTrust-Client
unset SHARK_TRUST_ZONE_KEY
```

For the generated-key variant, run `./SharkTrust-Client-Obfuscated-Key`;
no environment variable is needed. Both accept `--watch` to keep fetching
renewals, or `--help` to print usage without connecting. Portal, CA, name, and
address settings are edited in the source.

`SHARK_TRUST_ZONE_KEY` is a required environment string for the plain variant:
exactly 64 hexadecimal characters, without a newline. A string literal supplied
as a C macro of the same name takes precedence, for existing integrations.
Environment variables and compiled credentials are accessible to sufficiently
privileged local users.

A first run registers the device, prints its assigned URL, and polls until a
certificate is ready. Later runs reuse the saved device key. The default mode
exits with status 0 after saving the certificate and key. Setup/write errors
and portal `Forbidden` or `ClientError` responses exit nonzero.
Connection errors, incomplete responses, and pending issuance retry after
70 seconds. Use Ctrl+C to stop waiting.

### Files and server reload

The client writes these files in its current directory:

| File | Contents and lifetime |
| --- | --- |
| `DEVICE.KEY` | The 20-character device credential. Keep it across restarts, private to this device and zone. A missing or short file triggers registration. |
| `DeviceCert.pem` | The downloaded PEM certificate chain. |
| `DeviceKey.pem` | The corresponding PEM private key. |

The example uses standard C file I/O and writes the two PEM files separately.
Your application owns file protection, recovery from interrupted writes, and
loading the certificate and key together into its HTTPS server. The client
verifies the portal's TLS certificate and hostname before sending credentials;
it saves the returned PEM data without parsing it again.

The response buffer is 8000 bytes, as in the original example. Increase it in
`main()` if your certificate chain and private key need more space. Oversized
or incomplete responses are rejected. Socket calls are blocking and use the
operating system's timeouts.

### Renewal and ARI

The portal uses ACME Renewal Information (ARI) when the CA supports it, with
a lifetime-aware fallback. See [portal renewal scheduling](../doc/portal.md).
The client only retrieves the resulting certificate.

With `--watch`, a successful fetch schedules the next fetch after the smaller
of **12 hours** and **one third of the returned remaining lifetime**, with a
one-second minimum. It does not assume a 90-day certificate or sleep until a
fixed number of days before expiration. This lets it collect an early ARI
replacement within the polling interval while connectivity is available.
Network or issuance failures retry after 70 seconds. A response reporting zero
remaining lifetime is retried without saving its certificate.

```sh
# Fetch renewed credentials continuously; your server owns installation.
./SharkTrust-Client --watch
```

Fetching a certificate also refreshes the registered address. If your address
can change between polls, arrange a prompt fetch after the change.

## Private portal and CA

Set `SHARK_TRUST_SERVICE_NAME` to your private portal's DNS hostname and `caFile`
to the PEM CA file path before building. Set `deviceIp` if the connection's
local address is not the address browsers should use.

Use the CA bundle that signs the **portal's HTTPS certificate**. This can differ
from the CA issuing device certificates. Changing the portal's ACME directory
does not change the device protocol. The client must trust the portal, and the
browser must separately trust the issuer of the downloaded device certificate.
Keep the host's UTC clock correct for certificate validity checks. Do not
disable verification to work around a missing trust root or an incorrect name.

## Minnow Server example

The SharkSSL SDK's `examples/SharkTrust.c` combines this device protocol with
the Minnow Server HTTPS/WebSocket demo. It uses SharkSSL's compact certificate
format instead of PEM and keeps the downloaded certificate and key in RAM.
It persists only `DEVICE.KEY`. This is a small integration example: adapt
device naming, addressing, storage, and scheduling to your firmware.

Download your zone's `getzkey.ch` into the SDK's `examples` directory. Build the
library, socket adapter, and example with `SHARKSSL_CHECK_DATE=1`; a correct
UTC clock is required. The Visual Studio `SharkTrust` project sets this option.
For the source SDK Makefile, run from the SDK root:

```sh
# Rebuild the library and client with the same date-checking configuration.
make -C build -B XCFLAGS=-DSHARKSSL_CHECK_DATE=1 libSharkSSL.a SharkTrust
```

Run the executable from a private working directory after DNS is ready. It
tries HTTPS port 443, then ports 9443-9459. Use the printed device hostname
and listening port, for example `https://device.st.sharkssl.com:9443`.
The embedded development certificate can cause a browser warning until the
first portal certificate has been installed.

The example uses the same 12-hour/lifetime polling policy as the OpenSSL
watch mode, using SharkSSL's existing `baGetUnixTime()` clock. Clock adjustments
also affect this demo's polling deadline. When a fetch is due, it closes the
demo WebSocket and the page reconnects automatically. This permits reuse of
TLS memory between the client and server. A failed fetch or installation
retains the previous certificate and retries after 70 seconds. The demo page
requires no external JavaScript download.

### SharkSSL configuration and embedded ports

These optional C macros configure the example. String-valued macros must
expand to C string literals.

| Macro | Type, default, and purpose |
| --- | --- |
| `SHARK_TRUST_SERVICE_NAME` | DNS hostname string; defaults to `sharktrust.realtimelogic.com`, port 443. Used for connection, Server Name Indication (SNI), and hostname verification. |
| `SHARK_TRUST_ZONE_KEY_HEADER` | Include-path string; defaults to `getzkey.ch`. The generated header supplies `getZoneKey`. Also available in the OpenSSL generated-key variant. |
| `SHARK_TRUST_CA_HEADER` and `SHARK_TRUST_CA_LIST` | Set together for a private portal. The first is an include-path string; the second is the generated `SharkSslCAList` expression. Defaults are `certificates/CA_ISRG_Root_X1.h` and `sharkSSL_CA_ISRG_Root_X1`. |
| `SHARKSSL_CHECK_DATE` | Required integer value `1` for the example and all linked SharkSSL/socket-adapter code. |

The example passes the `mainTask` function address, converted to `U32`, to
`sharkssl_entropy` as a demonstration seed. A function address is predictable
and does not provide cryptographic entropy. Before using TLS in a product,
replace this call with proper RNG seeding from your platform's entropy source.
The application is responsible for supplying sufficient entropy before any
TLS connections are created.

The host helpers use the first hostname label as the device name and the
portal connection's local IPv4 address as the device address. Adapt
`deviceName()` and `getIpAddr()` for your target. The demo stores the device
key with standard C file I/O; your application owns storage protection and
recovery from interrupted writes.

For `HOST_PLATFORM=0`, supply these platform functions along with the existing
SharkSSL socket and UTC-time ports:

| Function | Contract |
| --- | --- |
| `const char* deviceName(void)` | Return a persistent, NUL-terminated valid DNS label, 1-63 characters. |
| `char* getIpAddr(SOCKET* sock)` | Borrow the connected socket; return a NUL-terminated IPv4 string that remains valid while its header is copied. |
| `int readDeviceKey(char deviceKey[20])` | Copy the saved 20-byte device key and return 0, or return nonzero to register the device. |
| `void saveDeviceKey(char deviceKey[20])` | Store the 20-byte device key for reuse after restart. |
| `void terminate(void)` | Stop the task or process on a fatal configuration/storage error. Must not return. |

The generated `void getZoneKey(unsigned char* output)` fills exactly 64
hexadecimal bytes in caller-owned storage and does not append a NUL byte.
Keep the generated credential and device key out of logs.
