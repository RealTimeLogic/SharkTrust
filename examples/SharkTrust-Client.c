/*

  SharkTrust Example Program

  Compile as follows:
  gcc -o SharkTrust-Client SharkTrust-Client.c -lssl -lcrypto

  Alternatively (adding zone-key):
  gcc -D'SHARK_TRUST_ZONE_KEY="the-key"' -o SharkTrust-Client\
  SharkTrust-Client.c -lssl -lcrypto

  Windows users: compile using Cygwin or install the Windows 10 Linux subsystem.

  This is a generic example and the required SharkTrust secure
  communication link is managed by OpenSSL. You may use the code as a
  template when porting to your TLS stack of choice. SharkSSL users
  should instead use the SharkTrust example bundled with the SharkSSL
  IDE.

  The example, by default, connects to the SharkTrust demo instance
  operated by Real Time Logic. You may use this service for test
  purposes, however, before using this C code, sign up for the service
  and set the SHARK_TRUST_ZONE_KEY macro to the zone key received after
  signing up for the service.

  SharkTrust service demo instance: https://sharktrust.realtimelogic.com/

  The example is designed to be minimal and uses virtually no error
  checking. The example expects that it can save the device-key (X-Dev),
  device-certificate, and device-certificate-key in the current
  directory.

  An X.509 certificate and it's corresponding private key is saved in
  the current directory after successfully running the program. You may
  import the certificate and key into your HTTPS server and navigate to
  the URL: https://[hostname].[zone], where hostname is the sub-domain name
  used by this C code and zone is the zone (domain name) used when
  signing up for the SharkTrust service.

  WARNING:

  This example does not validate the SharkTrust service's
  certificate. You must validate the certificate when porting to your
  TLS stack of choice or add validation to this example if your selected
  TLS stack is OpenSSL. The TLS connection is rendered useless when the
  SharkTrust service's certificate is not validated. See the following
  tutorial for details:
    realtimelogic.com/articles/How-Anyone-Can-Hack-Your-Embedded-Web-Server

  LICENSE:
  This software (this example) is licensed under: Zero-Clause BSD
  https://opensource.org/licenses/0BSD
*/

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <malloc.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <resolv.h>
#include <netdb.h>
#include <openssl/ssl.h>
#include <openssl/x509v3.h>
#include <openssl/err.h>

/* If denied access */
static void terminate()
{
   printf("Press Enter to exit program\n");
   getchar();
   exit(1);
}

/****************************************************************************
                  Generic socket connection and OpenSSL stuff
****************************************************************************/

/* Connect to server 'hostname' @ port.
   Returns the socket descriptor.
*/
int openConnection(const char *hostname, int port)
{
   int sd;
   struct hostent *host;
   struct sockaddr_in addr;
   if ( (host = gethostbyname(hostname)) == NULL )
   {
      perror(hostname);
      terminate();
   }
   sd = socket(PF_INET, SOCK_STREAM, 0);
   bzero(&addr, sizeof(addr));
   addr.sin_family = AF_INET;
   addr.sin_port = ntohs(port);
   addr.sin_addr.s_addr = *(long*)(host->h_addr);
   if ( connect(sd, (struct sockaddr*)&addr, sizeof(addr)) != 0 )
   {
      close(sd);
      perror(hostname);
      terminate();
   }
   return sd;
}


/* Returns an SSL_CTX object
   https://www.openssl.org/docs/manmaster/man3/SSL_CTX_new.html
*/
SSL_CTX* initCTX(void)
{
   const SSL_METHOD *method;
   SSL_CTX *ctx;
   OpenSSL_add_all_algorithms();  /* Load cryptos, et.al. */
   SSL_load_error_strings();   /* Bring in and register error messages */
   method = SSLv23_method();  /* Create new client-method instance */
   ctx = SSL_CTX_new(method);   /* Create new context */
   if ( ! ctx )
   {
      ERR_print_errors_fp(stderr);
      terminate();
   }
   return ctx;
}

/* Closes all descriptors/objects associated with one secure connection
 */
void closeAll(SSL* ssl, int sock, SSL_CTX* ctx)
{
   SSL_free(ssl);
   close(sock);
   SSL_CTX_free(ctx);
}


/* Returns the local (LAN) IP address
 */
char* getIpAddr(int sock)
{
   struct sockaddr_in in;
   int size=sizeof(struct sockaddr_in);
   int status=getsockname(sock, (struct sockaddr *)&in, &size);
   if(status)
   {
      perror("getIpAddr");
      terminate();
   }
   return inet_ntoa(in.sin_addr);
}


/* Functions for converting network endian to host endian
 */

#if defined(__ORDER_LITTLE_ENDIAN__)
static void
netConvU16(uint8_t* out, const uint8_t* in)
{
   out[0] = in[1];
   out[1] = in[0];
}
static void
netConvU32(uint8_t* out, const uint8_t* in)
{
   out[0] = in[3];
   out[1] = in[2];
   out[2] = in[1];
   out[3] = in[0];
}
#elif defined(__ORDER_BIG_ENDIAN__)
#define netConvU16(out, in) memcpy(out,in,2)
#define netConvU32(out, in) memcpy(out,in,4)
#else
#error Need endian macros
#endif



/****************************************************************************
                        SharkTrust Client
****************************************************************************/

/* The SharkTrust service instance name. Change this macro when you
   have your own SharkTrust service instance.
*/
#if 1
#define SHARK_TRUST_SERVICE_NAME "sharktrust.realtimelogic.com"
#else
/* See documentation for details on the following test server */
#define SHARK_TRUST_SERVICE_NAME "sharktrustEC.realtimelogic.com"
#endif


/* The zone (domain name) key. You must at a minimum register one
 * domain name, such as product.company.com.
 */
#ifndef SHARK_TRUST_ZONE_KEY
#define SHARK_TRUST_ZONE_KEY "the-64-byte-key"
#error remove this line after setting the zone key above.
#endif


/* SharkTrust response codes
 */
#define RSP_SUCCESS     0
#define RSP_FORBIDDEN   1
#define RSP_UNKNOWN     2
#define RSP_PROCESSING  3
#define RSP_SERVERERROR 4
#define RSP_CLIENTERROR 5


/* All HTTP SharkTrust commands start with:
 */
static const char sharkTrustRequestHeader[]={
   "GET /device/ HTTP/1.0\n"
   "X-Key: " SHARK_TRUST_ZONE_KEY "\n"
   "X-Command: " /* Header key, the header value is added by C code below */
};

/* Register device */
static const char cmdRegister[]={
   "Register\n" /* X-Command: */
   "X-Info: OpenSSL SharkTrust Client Demo\n" /* Optional */
   "X-IpAddress: " /* Header key, the header value is added by C code below */
};

/* Download certificate */
static const char cmdGetCert[]={
   "GetCertificate\n" /* X-Command: */
   "X-CertType: X509\n"
   "X-IpAddress: " /* Header key, the header value is added by C code below */
};


/* Open a secure link to the SharkTrust service and send the data in
 * the sharkTrustRequestHeader[].
 */
int openSharkTrustCon(SSL_CTX** ctx, SSL** ssl)
{
   int ssock = openConnection(SHARK_TRUST_SERVICE_NAME, 443);
   *ctx = initCTX();
   *ssl = SSL_new(*ctx);
   SSL_set_fd(*ssl, ssock);    /* attach the socket descriptor */
   if( SSL_connect(*ssl) != 1 )   /* perform the connection */
   {
      ERR_print_errors_fp(stderr);
      terminate();
   }
   SSL_write(*ssl, sharkTrustRequestHeader, sizeof(sharkTrustRequestHeader)-1);
   return ssock;
}


/* Send an HTTP key/value header to the SharkTrust service.
 */
void writeHttpHeader(SSL* ssl, const char* key, const char* val)
{
   if(key)
   {
      SSL_write(ssl, key, strlen(key));
      SSL_write(ssl, ":", 1);
   }
   SSL_write(ssl, val, strlen(val));
   SSL_write(ssl, "\n", 1);
}


/* Get the complete SharkTrust response and validate the binary
 * response header.
 */
int getSharkTrustResponse(SSL *ssl, uint8_t* buf, int blen)
{
   const char* msg;
   int rlen = SSL_read(ssl, buf, blen);
   /* We expect a full SharkTrust response in one TLS frame */
   if(rlen < 4)
   {
      if(rlen <=0)
         perror("getSharkTrustResponse");
      else
         printf("SharkTrust response length error!\n");
      terminate();
   }
   if(buf[0] != 0xFF || buf[1] != 0x55)
   {
      printf("Response is not from SharkTrust!\n"
             "Note: this client is not designed to connect via a proxy.\n");
      terminate();
   }

#if 0
   /* If you want to save the raw response data */
   FILE* fp = fopen("dump.bin","wb");
   fwrite(buf,rlen,1,fp);
   fclose(fp);
#endif

   switch(buf[2])
   {
      case RSP_SUCCESS: msg="Success"; break;
      case RSP_FORBIDDEN: msg="Forbidden"; break;
      case RSP_UNKNOWN: msg="Unknown"; break;
      case RSP_PROCESSING: msg="Processing"; break;
      case RSP_SERVERERROR: msg="ServerError"; break;
      case RSP_CLIENTERROR: msg="ClientError"; break;
      default:
         printf("Invalid SharkTrust response %d\n",buf[2]);
         terminate();
   }
   printf("SharkTrust response %d : %s\n",buf[2], msg);
   switch(buf[2])
   {
      case RSP_FORBIDDEN: /* Invalid SHARK_TRUST_ZONE_KEY */
      case RSP_CLIENTERROR: /* Your client is not working (bug) */
         terminate();
   }
   return rlen;
}


/* Sleep N seconds
 */
void secSleep(int seconds)
{
   struct timespec tp;
   tp.tv_sec = 1;
   tp.tv_nsec = 0;
   printf("Sleeping for %d seconds ", seconds);
   fflush(stdout);
   for( ; seconds > 0 ; seconds--)
   {
      nanosleep(&tp,0);
      putchar('.');
      fflush(stdout);
   }
   putchar('\n');
}


/* Register device and download certificate.
 */
int main()
{
   SSL_CTX *ctx;
   SSL *ssl;
   int16_t slen;
   char deviceKey[21];
   char hostname[30]; /* Used as sub-domain name (for demo purposes) */
   /* We have simplified things and made a huge buffer for response data */
   uint8_t recBuffer[8000];
   int ssock = openSharkTrustCon(&ctx, &ssl);
   char* ipAddr = getIpAddr(ssock);
   gethostname(hostname, sizeof(hostname));
   printf("Local IP Addr: %s, hostname: %s \n",ipAddr,hostname);
   FILE* fp = fopen("DEVICE.KEY", "rb");
   if( !fp ) /* If not registered */
   {
     L_mustRegister:
      printf("Sending Command: Register\n");
      SSL_write(ssl, cmdRegister, sizeof(cmdRegister)-1);
      writeHttpHeader(ssl,NULL,ipAddr);
      writeHttpHeader(ssl,"X-Name",hostname);
      SSL_write(ssl, "\n", 1); /* End HTTP header */
      /*
        Response can be one of: Success, Forbidden, ServerError, or
        ClientError.
        getSharkTrustResponse() manages: Forbidden and ClientError
      */
      getSharkTrustResponse(ssl, recBuffer, sizeof(recBuffer));
      closeAll(ssl, ssock, ctx);
      if(recBuffer[2]) /* Not OK: Can only be ServerError */
      {
         secSleep(70);
         ssock = openSharkTrustCon(&ctx, &ssl);
         goto L_mustRegister;
      }
      memcpy(deviceKey,recBuffer+4, 20);
      deviceKey[20]=0;
      printf("Our new device Key (X-Dev) %s\n",deviceKey);
      fp = fopen("DEVICE.KEY", "wb");
      fwrite(deviceKey, 20, 1, fp);
      fclose(fp);
      netConvU16((uint8_t*)&slen, recBuffer+24); /* Fetch device name length */
      if(slen != strlen(hostname)) /* Named: hostname#, where # is a number */
      {
         printf("Another device is using %s; server selected name: ",hostname);
         /* The sub-domain name used by the SharkTrust DNS service */
         memcpy(hostname,recBuffer+26,slen);
         hostname[slen]=0;
         printf("%s\n",hostname);
      }
      ssock = openSharkTrustCon(&ctx, &ssl);
   }
   else
   {
      fread(deviceKey, 20, 1, fp);
      fclose(fp);
      deviceKey[20]=0;
   }
   for(;;)
   {
      int16_t certlen;
      int32_t secondsUntilExp; /* When cert expires */
      printf("Sending Command: GetCertificate\n");
      SSL_write(ssl, cmdGetCert, sizeof(cmdGetCert)-1);
      writeHttpHeader(ssl,NULL,ipAddr);
      writeHttpHeader(ssl,"X-Dev",deviceKey);
      SSL_write(ssl, "\n", 1); /* End HTTP header */
      /*
        Response can be any of the response codes
        getSharkTrustResponse manages: Forbidden and ClientError
      */
      getSharkTrustResponse(ssl, recBuffer, sizeof(recBuffer));
      closeAll(ssl, ssock, ctx);
      switch(recBuffer[2])
      {
         case RSP_UNKNOWN: /* our device key has been invalidated by server */
            ssock = openSharkTrustCon(&ctx, &ssl);
            goto L_mustRegister;
         case RSP_PROCESSING:
         case RSP_SERVERERROR:
            secSleep(70);
            ssock = openSharkTrustCon(&ctx, &ssl);
            continue;
      }
      /* Success */
      netConvU32((uint8_t*)&secondsUntilExp, recBuffer+4);
      printf("Certificate expires in %u days\n",secondsUntilExp/86400);
      netConvU16((uint8_t*)&certlen, recBuffer+8);
      printf("Saving certificate; length %d\n",certlen);
      fp = fopen("DeviceCert.pem", "wb");
      fwrite(recBuffer+10,certlen,1,fp);
      fclose(fp);
      fp = fopen("DeviceKey.pem", "wb");
      netConvU16((uint8_t*)&slen, recBuffer+10+certlen);
      printf("Saving certificate's private key; length %d\n",slen);
      fwrite(recBuffer+12+certlen,slen,1,fp);
      fclose(fp);
      break;
   }

   /*
     The following (optional) code fetches the full Domain Name (DN)
    */
   printf("Sending Command: GetDN\n");
   ssock = openSharkTrustCon(&ctx, &ssl);
   writeHttpHeader(ssl,NULL,"GetDN");
   writeHttpHeader(ssl,"X-Dev",deviceKey);
   SSL_write(ssl, "\n", 1); /* End HTTP header */
   getSharkTrustResponse(ssl, recBuffer, sizeof(recBuffer));
   closeAll(ssl, ssock, ctx);
   if(RSP_SUCCESS == recBuffer[2])
   {
      netConvU16((uint8_t*)&slen, recBuffer+4); /* DN length */
      recBuffer[6+slen]=0; /* convert to string */
      printf("Your server URL: https://%s\n",recBuffer+6);
      printf("Test DNS as follows: ping %s\n",recBuffer+6);
   }

   return 0;
}

