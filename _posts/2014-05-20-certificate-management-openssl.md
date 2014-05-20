---
layout: post
title: "Simple certificate management with OpenSSL"
date: "2014-05-20 21:42:12"
categories: ssl security
abstract: "This is a simple how-to for my own remembering on how to create and package a fresh SSL certificate."
---

First create an empty dir for your new certificate:

~~~ bash
$ cd
$ mkdir com.mydomain
$ cd com.mydomain
~~~

Generate the private key and a certificate sign request:

~~~ bash
$ openssl genrsa -out com.mydomain.key 2048
$ openssl req -new -key com.mydomain.key -out com.mydomain.csr
~~~

Now pass the csr to for example [StartSSL](https://www.startssl.com/) and save the certificate to `com.mydomain.crt`. Create a file `ca.crt` containing all CA certificates concatenated. Bundle the key, the certificate and any needed (intermediate) CA certificates into a PKCS12 file:

~~~ bash
openssl pkcs12 -export -in com.mydomain.crt -inkey com.mydomain.key -certfile ca.pem -certfile ca.crt -name "mydomain.com" -out com.mydomain.p12
~~~

Now the `com.mydomain.p12` file contains all you need.

To change or remove the passphrase later on, you can do:

~~~ bash
$ openssl pkcs12 -in com.mydomain.p12 -nodes -out temp.pem
$ openssl pkcs12 -export -in temp.pem  -out com.mydomain-2.p12
$ rm temp.pem
~~~

To split the P12 file into its parts again just execute

~~~ bash
$ openssl pkcs12 -in com.mydomain.p12 -out com.mydomain.txt -nodes
~~~

and then extract the single parts from the output file.
