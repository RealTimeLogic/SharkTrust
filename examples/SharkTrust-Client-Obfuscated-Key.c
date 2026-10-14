/* SharkTrust client using a portal-generated zone-key header.
 * Download st.sharkssl.com's getzkey.ch once the portal and zone are ready.
 * Build this file alone; it includes the shared client implementation.
 * See README.md for provisioning, TLS trust, and runtime options.
 * License: Zero-Clause BSD, https://opensource.org/licenses/0BSD
 */
#define SHARK_TRUST_OBFUSCATED_KEY
#include "SharkTrust-Client.c"
