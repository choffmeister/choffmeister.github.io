---
layout:     post
title:      "Kickstart Hadoop development - Part 2"
date:       2013-08-15 18:10:23
categories: hadoop
---

In the last part we saw, how to kickstart a [Hadoop](http://hadoop.apache.org/) Server with [Vagrant](http://vagrantup.com/) and execute one of the example jobs shipped with Hadoop. Today we want to create our own job and let Hadoop execute it. For that we will use [Maven](http://maven.apache.org/) to manage the needed Java libraries and bundle our job into a JAR file that fits the needs of Hadoop (i.e. set the main file manifest and bundle the external libraries except for the Hadoop libraries).

For unknown reasons the [hadoop-core](http://central.maven.org/maven2/org/apache/hadoop/hadoop-core/1.2.1/) artifact does not ship with a javadoc- or sources-JAR. To fix that, I've bundle those two JARs and uploaded them to my own Maven repository at [http://maven.choffmeister.de/maven2/](http://maven.choffmeister.de/maven2/). By including this repository in our pom.xml, we can use the Maven Eclipse plugin to automatically download the sources and javadoc and link them to the original JAR in the Eclipse project files. This way we can read the javadoc directly in Eclipse and also navigate the original source code of the Hadoop classes to find out more about the implementation details.

So enter your development folder and execute

```bash
# clone barebone project
$ git clone git://github.com/choffmeister/hadoop-barebone.git
```

to clone my Hadoop barebone project. This has all properly configured and is ready to go.

```bash
$ cd hadoop-barebone
# generate eclipse project files from pom.xml
$ mvn eclipse:eclipse
# build project and package into Hadoop conform JAR file
$ mvn install
```

This will download all dependencies, configure the Eclipse project files and compile everything into a JAR. The JAR can be found at ```target/hadoop-barebone-0.0-SNAPSHOT-job.jar```. This JAR contains the same word count algorithm as in the shipped examples from Hadoop itself. To make sure that everything works as intended, start the Hadoop VM (see [Part 1](/hadoop/2013/08/13/kickstart-hadoop-development-1.html)) and copy the JAR to the server by executing

```bash
$ scp target/hadoop-barebone-0.0-SNAPSHOT-job.jar hadoop@10.10.10.10:.
```

Now SSH into the machine and tell Hadoop to execute our compiled Hadoop job.

```bash
# connect to the machine
$ ssh hadoop@10.10.10.10
# ensure that we are in the home folder
$ cd
# start hadoop (if not already running)
$ start-all.sh
# create some text to test
$ echo "fish one fish two green fish red fish" > text
# move text to Hadoop fs
$ hadoop fs -put text text-input
# execute job
$ hadoop jar hadoop-barebone-0.0-SNAPSHOT-job.jar text-input text-output
# show results, should be fish 4 / green 1 / one 1 / red 1 / two 1
$ hadoop fs -cat text-output/*
# cleanup
$ hadoop fs -rm text-input
$ hadoop fs -rmr text-output
# disconnect
$ exit
```
