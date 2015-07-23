---
layout: post
title: "Simple certificate management with OpenSSL"
date: "2014-05-20 21:42:12"
categories: ssl security
abstract: "This is a simple how-to for my own remembering on how to create and package a fresh SSL certificate."
---

First create an empty dir for your new certificate:

```bash
# temporary export domain name
$ domain=mydomain.com
$ cd
$ mkdir $domain
$ cd $domain
```

Generate the private key and a certificate sign request:

```bash
$ openssl genrsa -out $domain.key 2048
$ openssl req -new -key $domain.key -out $domain.csr -sha256
```

Now pass the csr to for example [StartSSL](https://www.startssl.com/) and save the certificate to `$domain.crt`. Create a file `ca.crt` containing all CA certificates concatenated. Bundle the key, the certificate and any needed (intermediate) CA certificates into a PKCS12 file:

```bash
$ openssl pkcs12 -export -in $domain.crt -inkey $domain.key -certfile ca.pem -name "$domain" -out $domain.p12
```

Now the `$domain.p12` file contains all you need.

To change or remove the passphrase later on, you can do:

```bash
$ openssl pkcs12 -in $domain.p12 -nodes -out temp.pem
$ openssl pkcs12 -export -in temp.pem -out $domain-2.p12
$ rm temp.pem
```

To split the PKCS#12 container into its parts again just execute

```bash
$ openssl pkcs12 -in $domain.p12 -nodes -nokeys > $domain.crt
$ openssl pkcs12 -in $domain.p12 -nodes -nocerts > $domain.key
```

and then extract the single parts from the output file.

# Script for StartSSL

```bash
#!/bin/bash

domain=$1
mkdir $domain
cd $domain

echo "Download intermediate certificate..."
wget --quiet http://www.startssl.com/certs/class1/sha2/pem/sub.class1.server.sha2.ca.pem

echo "Create private key..."
openssl genrsa -out $domain.key 2048

echo "Create certificate sign request..."
openssl req -new -key $domain.key -out $domain.csr -sha256

echo "Create certificate..."
echo "* Visit http://www.startssl.com/"
echo "* Pass $domain.csr"
echo "* Save the certificate at $domain.crt"
echo "* Press any key when done"

echo "Create PKCS#12 container..."
openssl pkcs12 -export -in $domain.crt -inkey $domain.key -certfile sub.class1.server.sha2.ca.pem -name "$domain" -out $domain.p12
```
