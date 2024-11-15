## C Source Code Examples


# SharkTrust Client Examples

This directory includes two ready-to-compile and run test programs. These programs register with a SharkTrust portal, wait for the certificate to be generated, and save the Let's Encrypt signed certificate and private key to the directory where the examples are running.

## Step 1: Compile the Program

To compile the `SharkTrust-Client` program, run the following command:

```bash
gcc -o SharkTrust-Client SharkTrust-Client-Obfuscated-Key.c -lssl -lcrypto
```

## Step 2: Run the Program
Execute the compiled program:

```bash
./SharkTrust-Client
```
You should see output similar to the following:

```bash
Local IP Addr: 192.168.1.100, hostname: NUC
Sending Command: Register
SharkTrust response 0 : Success
Our new device Key (X-Dev) BED9E41A53647B58A5F1
Sending Command: GetCertificate
SharkTrust response 3 : Processing
Sleeping for 70 seconds ......................................................................
Sending Command: GetCertificate
SharkTrust response 3 : Processing
Sleeping for 70 seconds ......................................................................
Sending Command: GetCertificate
SharkTrust response 0 : Success
Certificate expires in 89 days
Saving certificate; length 2873
Saving certificate's private key; length 47
Sending Command: GetDN
SharkTrust response 0 : Success
```
You can now load the generated certificate and private key into your web server.
## Step 3: Study the code
Carefully review the comments in both SharkTrust-Client-Obfuscated-Key.c and SharkTrust-Client.c for further details.

## Ready-to-Run Minnow Web Server Example

The SharkTrust client examples above download and save the private key and certificate from the SharkTrust portal, but do not embed a web server within the SharkTrust client example code. However, the [SharkSSL GitHub repository](https://github.com/RealTimeLogic/SharkSSL) includes an example that combines the SharkTrust client with the [Minnow Web Server](https://realtimelogic.com/products/sharkssl/minnow-server/), automatically installing the certificate and private key in the web server.

### Running the Example

To run the SharkTrust Minnow Server example, follow these steps:

```bash
git clone https://github.com/RealTimeLogic/SharkSSL.git
cd SharkSSL/build/
./SharkTrust
```

When the example runs successfully, you should see output similar to the following:

```
./SharkTrust
SharkTrust and Minnow Server Demo.

Bind error: port 443
WebSocket server listening on 9443
Sending Command: Register
SharkTrust response 0 : Success
Our new device Key (X-Dev) 80955398A9FA9647497F
Sending Command: GetDN
SharkTrust response 0 : Success
--------------------------------------------
Your server URL: https://minnow.equip.run
Test DNS as follows: ping minnow.equip.run
--------------------------------------------
Sending Command: GetCertificate
SharkTrust response 3 : Processing
Certificate not ready
Installing embedded default certificate
Next SharkTrust HTTP poll in 70 seconds
Minnow Server is running and waiting for connections.
Sending Command: GetCertificate
SharkTrust response 0 : Success
Certificate expires in 89 days
Installing certificate fetched from SharkTrust
```

Once the certificate is installed, navigate to https://SUBDOMAIN.equip.run:9443 to access your server.


## The SharkTrust Demo Portal

The following instructions are for using our demo portal:

1. Open SharkTrust-Client.c in an editor and study the code
2. Navigate to [freenom.com](https://freenom.com/) and sign in / create an account
3. Register a free domain name; Any name will do
4. Click Services -> My Domains -> Manage Domain
5. Click Management Tools -> Nameservers
6. Set Nameserver 1 to ns1.realtimelogic.com and Nameserver 2 to ns2.realtimelogic.com
7. Click Change Nameservers, and **wait one hour before the next step**
8. Navigate to Real Time Logic's SharkTrust demo portal: [https://sharktrust.realtimelogic.com/](https://sharktrust.realtimelogic.com/)
9. Enter the domain name registered at freenome, and sign up for the portal
10. Follow the instructions provided by the SharkTrust demo portal
11. When you receive the email with the Zone Key, copy the key, and paste the key into SharkTrust-Client.c **[1]**

You may find the information provided in the
[Barracuda App Server's Let's Encrypt tutorial](https://makoserver.net/articles/Lets-Encrypt)
useful if you are new to domain names and configuring name servers for
a domain name. The tutorial goes into detail on how DNS and name
servers work.

Our demo portal is purely designed for testing/learning purposes and
should not be used for deployment. In the end, you must set up your
own SharkTrust server and not use our demo portal.

The online portal creates a unique registration key after completing
the "new zone" registration process. A zone is a domain name and the
registration key is known as the Zone Key.

The Zone Key must be used by the SharkTrust client program connecting
to the online portal. The following instructions, which simulates a
scenario where your end users register their own zone and create their
own zone key, must be performed prior to compiling the example C code.


**[1]**
Open the C code in any text editor and scroll down until you
see: **#define SHARK_TRUST_ZONE_KEY**. Replace the
**the-64-byte-key** string with your zone key. Remove
the **#error** directive on the line below. Compile
the code as instructed per comments inside the C source code
example.

You may run the executable from the command line as soon as you
have compiled the source code with a valid zone key. The example
connects to the online SharkTrust demo portal and uses commands
as specified in the SharkTrust Specification.


## Security and Private Data

The certificate's private key must be protected. We recommend
downloading the certificate and the certificate's private key each
time the device starts and to store the certificate data in RAM
memory and not persistently on a disk. The pre-compiled example
detailed below follows this design guideline.

The zone key must also be protected and our example, which
includes the Zone Key as a string in the executable is not secure
at all. It is very easy to extract the zone key from the example
program you compiled. Run the following on the command line to
print the zone key:

```
strings SharkTrust-Client.exe | grep 'X-Key'
```

**Figure 3: Extracting secrets from anexecutable**

The [strings command](https://linux.die.net/man/1/strings) prints all
strings in a binary file. The above command sends all strings to grep,
where we use grep to search for the Zone Key. As we explained above,
embedding the zone key in the executable/firmware is used for the use
case scenario when the device manufacturer wants all end-users to use
the same domain name e.g. -- https://xxx.product.company.com, where
xxx is the sub-domain name unique to the device. The Zone Key must be
protected when hard coded in the executable/firmware and the example
SharkTrust-Client.c does not do a good job protecting this key.

There are several obfuscating techniques that may be applied to make
it virtually impossible to extract the key from the binary file. The
online SharkTrust service includes C code generation for obfuscating
the Zone Key.

The example SharkTrust-Client-Obfuscated-Key.c shows how to use the
auto generated obfuscated key. The source code includes build
instructions in the comment at the top of the file.
