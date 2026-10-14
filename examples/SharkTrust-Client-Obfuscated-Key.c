/* SharkTrust client using a portal-generated zone-key header.
 * The bundled getzkey.ch uses the shared st.sharkssl.com test zone.
 * Optionally replace it with the generated header for your own zone.
 * Build this file alone; it includes the shared client implementation.
 * See README.md for provisioning, TLS trust, and runtime options.
 * License: Zero-Clause BSD, https://opensource.org/licenses/0BSD
 */
#define SHARK_TRUST_OBFUSCATED_KEY
#include "SharkTrust-Client.c"
