
### zones table
The zones table stores all zones (domains), the key is the zone and the value is the 40 byte zone key.

**Storage: data/zones.json**

String Key | String Value
--------- | ------------
zone name | 40 byte zone key

### zone table
The zone table stores information related to one zone (domain).

**Storage: data/z.[40 byte zone key].json**

String&nbsp;Key | Value | Info
---------- | ------| -------------
uname | String | The zone admin's username is the email address
ha1 | String | zone admin's HA1 password hash
zname | String | The zone (domain) name
rtime | number | The registration time (secs. since Jan 1970)
devices| table | a key/val map of registered devices, where key is the device's sub-domain name and value is the 20 byte device key.
certs | table | a key/val map of registered devices certificate, where key is the device's sub-domain name and value is the expiration date.

### zone wan table
The zone wan table groups devices per wan IP address for a specific zone.

**Storage: data/w.[40 byte zone key].json**

The key is the wan address and the value is a table, where the key is the sub-domain name and the value is the device's local IP address.

### device table
The device table stores device specific data

**Storage: data/d.[20 byte zone key].json**

String&nbsp;Key | Value | Info
---------- | ------| -------------
atime | Number | Last device access time by SetIpAddress/GetCertificate (secs. since Jan 1970).
dns | String | DNS A record type, which can be local (default), WAN IP Address, or both. WAN and both can be used for device with router pinhole (port forward). Values: local/wan/both.
info | String | Optional device info
ip | String | The device's local IP address
name | String | the device's sub-domain name
wan | String | The device's public WAN IP address
