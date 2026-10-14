# POSIX/OpenSSL examples. getzkey.ch defaults to the shared st.sharkssl.com zone.
CFLAGS ?= -O2
CFLAGS += -std=c99 -Wall -Wextra
LDLIBS += -lssl -lcrypto

.PHONY: all clean
all: SharkTrust-Client SharkTrust-Client-Obfuscated-Key

SharkTrust-Client: SharkTrust-Client.c

SharkTrust-Client-Obfuscated-Key: SharkTrust-Client-Obfuscated-Key.c SharkTrust-Client.c getzkey.ch

SharkTrust-Client SharkTrust-Client-Obfuscated-Key:
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@ $< $(LDLIBS)

clean:
	$(RM) SharkTrust-Client SharkTrust-Client-Obfuscated-Key
