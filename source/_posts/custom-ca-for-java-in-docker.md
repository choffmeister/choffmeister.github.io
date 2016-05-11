---
title: Custom CA for Java in Docker image
tags: [java, docker, ssl]
date: 2016-05-11 09:40:21
---

To enable your Java services to talk to other services using a custom CA, you have to use the [Java keytool][java-keytool]. There is a little bit of digging around involved to get the needed command. Especially the default keystore password took me some time to find, since I guessed the default is a password-less keystore. Well, it is not. The default keystore password is `changeit`...

I love Docker, so I wrapped everything you need to use custom CAs with your Java services in a Docker example. The following `Dockerfile` adds a custom CA cert to the Java keystore and runs a simple test to ensure, that everything worked. As prerequisite you must place your CA certificate to next to the Docker file as `ca.crt`:

```docker
# FROM java:8u66-jre
# ENV JAVA_CACERTS=$JAVA_HOME/lib/security/cacerts
FROM java:8u66-jdk
ENV JAVA_CACERTS=$JAVA_HOME/jre/lib/security/cacerts

ADD ca.crt /tmp
RUN echo yes | keytool -keystore JAVA_CACERTS -storepass changeit -importcert -alias myca -file /tmp/ca.crt

RUN wget -qO SSLPoke.java https://gist.githubusercontent.com/choffmeister/a8986a6a1fb1ed41af74171840f4cd6b/raw/f7e8e5cb960752e4ede505efeb59c276ba23aa83/SSLPoke.java
RUN javac SSLPoke.java
RUN java SSLPoke mydomain.com 443
```

The `SSLPoke` class is originally from [here][gist-sslpoke]. It creates a test connection against the given domain and port. When you see the output `Successfully connected` then everything went fine.

[java-keytool]: http://docs.oracle.com/javase/6/docs/technotes/tools/solaris/keytool.html
[gist-sslpoke]: https://gist.github.com/4ndrej/4547029
