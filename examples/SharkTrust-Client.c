/*
 * Minimal SharkTrust download example, OpenSSL 1.1.1 or later, POSIX.
 * Adapt the socket, storage, and scheduling calls when porting to a device.
 * Build: cc -std=c99 -Wall -Wextra -o SharkTrust-Client SharkTrust-Client.c -lssl -lcrypto
 * License: Zero-Clause BSD, https://opensource.org/licenses/0BSD
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

#ifdef SHARK_TRUST_OBFUSCATED_KEY
#ifndef SHARK_TRUST_ZONE_KEY_HEADER
#define SHARK_TRUST_ZONE_KEY_HEADER "getzkey.ch"
#endif
#include SHARK_TRUST_ZONE_KEY_HEADER
#endif

/* The HTTPS endpoint stays the same. Use a zone key for st.sharkssl.com
 * to receive names such as device.st.sharkssl.com; the portal assigns the name.
 */
#ifndef SHARK_TRUST_SERVICE_NAME
#define SHARK_TRUST_SERVICE_NAME "sharktrust.realtimelogic.com"
#endif
static const char *caFile=NULL; /* Private portal CA PEM file, or system roots. */
static const char *deviceName="device"; /* Requested DNS label. */
static const char *deviceIp=NULL; /* IPv4 string, or use the connection's local IP. */

enum { SUCCESS, FORBIDDEN, UNKNOWN, PROCESSING, SERVERERROR, CLIENTERROR };
enum { REGISTER, GET_DN, GET_CERT };
static const char *commands[] = { "Register", "GetDN", "GetCertificate" };
static char zoneKey[65];

static unsigned read16(const unsigned char *p)
{
   return ((unsigned)p[0] << 8) | p[1];
}

static uint32_t read32(const unsigned char *p)
{
   return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
      ((uint32_t)p[2] << 8) | p[3];
}

/* Blocking IPv4 socket for this host demo. */
static int openConnection(void)
{
   struct hostent *host=gethostbyname(SHARK_TRUST_SERVICE_NAME);
   struct sockaddr_in address;
   int sock;
   if(!host) return -1;
   memset(&address, 0, sizeof(address));
   address.sin_family=AF_INET;
   address.sin_port=htons(443);
   memcpy(&address.sin_addr, host->h_addr_list[0], sizeof(address.sin_addr));
   sock=socket(AF_INET, SOCK_STREAM, 0);
   if(sock>=0 && connect(sock, (struct sockaddr*)&address, sizeof(address)))
   { close(sock); return -1; }
   return sock;
}

/* TLS reads and writes need not transfer a complete protocol message. */
static int writeAll(SSL *ssl, const char *data, size_t len)
{
   while(len)
   {
      int n=SSL_write(ssl, data, (int)len);
      if(n<=0) return -1;
      data+=n; len-=(size_t)n;
   }
   return 0;
}

static int readExact(SSL *ssl, unsigned char *data, size_t len)
{
   while(len)
   {
      int n=SSL_read(ssl, data, (int)len);
      if(n<=0) return -1;
      data+=n; len-=(size_t)n;
   }
   return 0;
}

/* Read the binary response into the caller's fixed buffer. Check each length
 * before reading its payload, including the separate PEM private-key length.
 */
static int readResponse(SSL *ssl, int command, unsigned char *response, size_t capacity)
{
   size_t prefix, payload, total;
   if(readExact(ssl, response, 4) || response[0]!=0xFF || response[1]!=0x55 ||
      response[3] || response[2]>CLIENTERROR) return -1;
   if(response[2]!=SUCCESS) return response[2];
   prefix=command==REGISTER ? 26 : command==GET_DN ? 6 : 10;
   if(readExact(ssl, response+4, prefix-4)) return -1;
   payload=read16(response+prefix-2);
   total=prefix+payload+(command==GET_CERT ? 2 : 0);
   if(!payload || total>capacity) return -1;
   if(readExact(ssl, response+prefix, total-prefix)) return -1;
   if(command==GET_CERT)
   {
      size_t keylen=read16(response+total-2);
      if(!keylen || keylen>capacity-total || readExact(ssl, response+total, keylen))
         return -1;
   }
   return SUCCESS;
}

/* Verify the portal's TLS certificate and hostname before sending credentials. */
static int request(SSL_CTX *ctx, int command, const char *deviceKey,
                   unsigned char *response, size_t capacity)
{
   int sock=openConnection(), rc=-1, n;
   SSL *ssl=NULL;
   char message[2048];
   const char *ip=deviceIp;
   struct sockaddr_in local;
   socklen_t size=sizeof(local);
   if(sock<0) goto done;
   ssl=SSL_new(ctx);
   if(!ssl || SSL_set_fd(ssl, sock)!=1 ||
      SSL_set_tlsext_host_name(ssl, SHARK_TRUST_SERVICE_NAME)!=1 ||
      SSL_set1_host(ssl, SHARK_TRUST_SERVICE_NAME)!=1 || SSL_connect(ssl)!=1)
      goto done;
   if(!ip)
   {
      if(getsockname(sock, (struct sockaddr*)&local, &size)) goto done;
      ip=inet_ntoa(local.sin_addr);
   }
   n=snprintf(message, sizeof(message),
      "GET /device/ HTTP/1.0\r\nHost: %s\r\nX-Key: %s\r\nX-Command: %s\r\n"
      "X-CertType: X509\r\nX-IpAddress: %s\r\nX-Name: %s\r\n"
      "X-Info: OpenSSL SharkTrust Client Demo\r\nX-Dev: %s\r\n\r\n",
      SHARK_TRUST_SERVICE_NAME, zoneKey, commands[command], ip, deviceName, deviceKey);
   if(n<0 || (size_t)n>=sizeof(message) || writeAll(ssl, message, (size_t)n)) goto done;
   printf("Sending command: %s\n", commands[command]);
   rc=readResponse(ssl, command, response, capacity);
  done:
   SSL_free(ssl);
   if(sock>=0) close(sock);
   if(rc<0) { fprintf(stderr, "Connection or response failed\n"); ERR_print_errors_fp(stderr); }
   else if(rc) fprintf(stderr, "SharkTrust response: %d\n", rc);
   return rc;
}

/* Simple demo storage. The application owns file protection, recovery from
 * interrupted writes, and installing the certificate/key together in its server.
 */
static int saveFile(const char *path, const void *data, size_t len)
{
   FILE *fp=fopen(path, "wb");
   int failed;
   if(!fp) return -1;
   failed=fwrite(data, 1, len, fp)!=len;
   if(fclose(fp)) failed=1;
   return failed ? -1 : 0;
}

int main(int argc, char **argv)
{
   char deviceKey[21]={0};
   /* Increase this demo buffer if your CA returns a larger certificate chain. */
   unsigned char response[8000];
   SSL_CTX *ctx;
   FILE *fp;
   int command, rc, watch=0, exitCode=1;
   if(argc==2 && !strcmp(argv[1], "--watch")) watch=1;
   else if(argc!=1)
   {
      fprintf(stderr, "Usage: %s [--watch]\n", argv[0]);
      return argc==2 && !strcmp(argv[1], "--help") ? 0 : 1;
   }
#ifdef SHARK_TRUST_OBFUSCATED_KEY
   getZoneKey((unsigned char*)zoneKey);
#else
   {
#ifdef SHARK_TRUST_ZONE_KEY
      const char *key=SHARK_TRUST_ZONE_KEY;
#else
      const char *key=getenv("SHARK_TRUST_ZONE_KEY");
#endif
      if(!key || strlen(key)!=64)
      { fprintf(stderr, "Set SHARK_TRUST_ZONE_KEY to the 64-character zone key\n"); return 1; }
      memcpy(zoneKey, key, 64);
   }
#endif
   fp=fopen("DEVICE.KEY", "rb");
   if(fp)
   {
      if(fread(deviceKey, 20, 1, fp)!=1) deviceKey[0]=0;
      fclose(fp);
   }
   command=deviceKey[0] ? GET_DN : REGISTER;
   signal(SIGPIPE, SIG_IGN);
   ctx=SSL_CTX_new(TLS_client_method());
   if(!ctx) return 1;
   SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, NULL);
   if(SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION)!=1 ||
      (caFile ? SSL_CTX_load_verify_locations(ctx, caFile, NULL) : SSL_CTX_set_default_verify_paths(ctx))!=1)
   { fprintf(stderr, "Cannot load portal trust store\n"); goto done; }
   for(;;)
   {
      unsigned delay=70;
      rc=request(ctx, command, deviceKey, response, sizeof(response));
      if(rc==FORBIDDEN || rc==CLIENTERROR) break;
      if(rc==UNKNOWN) { deviceKey[0]=0; command=REGISTER; }
      else if(rc==SUCCESS)
      {
         if(command==REGISTER)
         {
            if(saveFile("DEVICE.KEY", response+4, 20))
            { fprintf(stderr, "Cannot save device registration\n"); break; }
            memcpy(deviceKey, response+4, 20);
            printf("Device registered; key saved\n");
            command=GET_DN;
            continue;
         }
         if(command==GET_DN)
         {
            printf("Your server URL: https://%.*s\n", (int)read16(response+4), response+6);
            command=GET_CERT;
            continue;
         }
         if(read32(response+4))
         {
            unsigned certLen=read16(response+8), keyLen=read16(response+10+certLen);
            if(saveFile("DeviceCert.pem", response+10, certLen) ||
               saveFile("DeviceKey.pem", response+12+certLen, keyLen))
            { fprintf(stderr, "Cannot save certificate or private key\n"); break; }
            printf("Saved DeviceCert.pem and DeviceKey.pem; expires in %u seconds\n", read32(response+4));
            if(!watch) { exitCode=0; break; }
            /* Fetch portal-side ARI renewals within 12 hours, sooner near expiry. */
            delay=read32(response+4)/3;
            if(delay>43200) delay=43200;
            if(!delay) delay=1;
         }
      }
      printf("Next fetch in %u seconds\n", delay);
      sleep(delay);
   }
  done:
   SSL_CTX_free(ctx);
   return exitCode;
}
