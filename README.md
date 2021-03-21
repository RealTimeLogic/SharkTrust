# SharkTrust
Automatic SSL Certificate Management for Intranet Web Servers

See the [SharkTrust home page](https://realtimelogic.com/services/SharkTrust/) for details.

## Initial Test

As an initial test and to get an understanding of how SharkTrust
works. Download the ready to use demo server with integrated
SharkTrust client. The pre-compiled example bundles the SharkTrust
client and the secure
[Minnow Server](https://realtimelogic.com/products/sharkssl/minnow-server/).
The certificate and private key are stored in memory only. The
private Zone Key embedded in the software uses the obfuscation
technique explained later. The ready to use Windows
executable simulates how your end users could use SharkTrust with
a hard coded SharkTrust registration key embedded inside the
executable. SharkTrust enables different use case scenarios and
embedding the registration in the executables/firmware is just one
of several options.

### HTTPS/SOCKS Proxy Users

The ready to use test server is not designed for networks requiring HTTPS/SOCKS Proxy connections!

### Download Ready To Use Test Server
Download and run the example: [examples/SharkTrustMinnow.exe](examples/SharkTrustMinnow.exe)

The registration key embedded in the example program is for the
portal (domain name) [https://equip.run/](https://equip.run/)

A new SharkTrust client must first register before it can
download a certificate and the certificate's private key. The
example program initially registers with the online portal, saves
the device key in the current directory, and waits for the online
portal to complete the certificate process. The following figure
shows the printouts from the example program when it initially
registers:

```
$ ./SharkTrust-Client
Local IP Addr: 192.168.1.108, hostname: RTL-LAB
Sending Command: Register
SharkTrust response 0 : Success
Our new device Key (X-Dev) E18720BBC998CC6107B2
Sending Command: GetCertificate
SharkTrust response 3 : Processing
Sleeping for 70 seconds .................................
Sending Command: GetCertificate
SharkTrust response 3 : Processing
Sleeping for 70 seconds .................................
Sending Command: GetCertificate
SharkTrust response 0 : Success
Certificate expires in 90 days
Saving certificate; length 3563
Saving certificate's private key; length 1675
Sending Command: GetDN
SharkTrust response 0 : Success
Your server URL: https://RTL-LAB.equip.run
Test DNS as follows: ping RTL-LAB.equip.run
```
**Figure 1: Printouts from The SharkTrustclient example program**

The online portal shows proof of domain ownership by
setting a TXT record for the sub-domain + domain name given to the
registered device. This process takes just over two minutes and the
client is designed to poll for the certificate every 70 seconds, as
can be seen from the above printouts.

After at least two minutes and when you see the text 'Your server
URL...', either enter this URL in the browser or navigate to
[https://equip.run/](https://equip.run/) and click the link shown in
the portal.

Note that the link provided in the portal expects the server to listen
on the default HTTPS port 443. Just add the HTTPS port number that the
server is listening on to the end of the URL should the link not work;
e.g. :9443.

You may have a type of DNS filtering that blocks the translation of
DNS names to internal IP addresses if the domain name is not
working. This must be turned off if you plan on using the domain name
designed for local use. Older browsers were susceptible to DNS
rebinding attacks, and blocking internal IP address translation helped
older browsers stay secure.

The following figure shows the printouts when the SharkTrust
client is restarted and when a device key (DEVICE.KEY) is found in
the current directory.

```
$ ./SharkTrust-Client
Local IP Addr: 192.168.1.108, hostname: RTL-LAB
Sending Command: GetCertificate
SharkTrust response 0 : Success
Certificate expires in 90 days
Saving certificate; length 3563
Saving certificate's private key; length 1675
Sending Command: GetDN
SharkTrust response 0 : Success
Your server URL: https://RTL-LAB.equip.run
Test DNS as follows: ping RTL-LAB.equip.run
```
**Figure 2: Re-starting the SharkTrust clientwhen the client is registered and when the online portal has prepared a certificate**

## Integrating the C Code in Your Server

See the [examples directory](examples/README.md) for details.


## Documentation

See [doc/README.md](doc/README.md)
