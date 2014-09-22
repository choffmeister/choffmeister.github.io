---
layout: post
title: "Kickstart Hadoop development - Part 1"
date: "2013-08-14 12:00:00"
categories: java bigdata maven vagrant
abstract: This post will show you have to get a super fast kickstart into development with Hadoop (1.2.1). We will use Vagrant (1.2.7) to supply a virtual Hadoop server machine...
---

This post will show you have to get a super fast kickstart into development with [Hadoop](http://hadoop.apache.org/) (1.2.1). We will use [Vagrant](http://vagrantup.com/) (1.2.7) to supply a virtual Hadoop server machine. First of all visit the Vagrant homepage and install it on your system. In addition we need [VirtualBox](https://www.virtualbox.org/) (4.x) to actually run our VM.

Done with that, create a new directory and create a new file called `Vagrantfile`. This will contain our configuration for the virtual machine that runs Hadoop.

``` ruby Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.network :private_network, ip: "10.10.10.10"

  config.vm.provider :virtualbox do |vb|
    vb.gui = false
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.customize ["modifyvm", :id, "--cpus", "2"]
  end
end
```

We use Ubuntu LTS 12.04.2 x64 as operating system, 2 GB of RAM and 2 virtual CPU cores. The machine will be reachable under the IP 10.10.10.10 from our local machine. Now lets delegate the nifty work of creating and booting a VM to Vagrant by executing `vagrant up`. Vagrant will load the base image, configure the network and start the VM with VirtualBox. When Vagrant has finished you can SSH into the machine with `vagrant ssh`. Creating a secure shell to the VM by its private network IP 10.10.10.10 is possible, too, but by now we don't have a username/password to get access that way. So lets enter the VM with `vagrant ssh` and install Hadoop. For that I have create a single script that does all the work.

``` bash hadoop-install.sh
#!/usr/bin/env bash

## ========================
## Settings
## ========================

# Hadoop user and group
HADOOP_GROUP="hadoop"
HADOOP_USER="hadoop"

# Webproxy (just uncomment out the two following lines, if you are behind a proxy)
#PROXY_HTTP=""
#PROXY_HTTPS=""

## ========================
## Permission
## ========================

# assert that this script is run with root rights
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

## ========================
## Configure proxy
## ========================

# configure proxy for APT and export it to environment
if [[ $PROXY_HTTP ]]; then
    echo "Acquire::http::Proxy \"$PROXY_HTTP\";" >> /etc/apt/apt.conf.d/01proxy
    export http_proxy=$PROXY_HTTP
fi
if [[ $PROXY_HTTPS ]]; then
    echo "Acquire::https::Proxy \"$PROXY_HTTPS\";" >> /etc/apt/apt.conf.d/01proxy
    export https_proxy=$PROXY_HTTPS
fi

## ========================
## Base configuration
## ========================

# update packages
aptitude update

# install vim
aptitude install -y vim

## ========================
## Hadoop installation
## see http://hadoop.apache.org/docs/stable/single_node_setup.html
## ========================

# install Orac le Java PPA
aptitude install -y python-software-properties
sudo -E add-apt-repository -y ppa:webupd8team/java
aptitude update

# install Oracle Java 6 JDK and make it default Java environment
aptitude install -y oracle-java6-installer
update-java-alternatives -s java-6-oracle

# show Java VM information
java -version

# create group hadoop and user $HADOOP_USER
addgroup $HADOOP_GROUP
adduser --ingroup $HADOOP_GROUP --disabled-password --gecos "" $HADOOP_USER

# set password of $HADOOP_USER to $HADOOP_USER
echo -e "$HADOOP_USER\n$HADOOP_USER\n" | passwd $HADOOP_USER

# create an unencrpyted rsa keypair for user $HADOOP_USER and add it to its authorized keys
sudo -u $HADOOP_USER ssh-keygen -t rsa -P "" -f /home/$HADOOP_USER/.ssh/id_rsa
sudo -u $HADOOP_USER cp /home/$HADOOP_USER/.ssh/id_rsa.pub /home/$HADOOP_USER/.ssh/authorized_keys

# disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
cat /proc/sys/net/ipv6/conf/all/disable_ipv6

# download Hadoop
wget http://mirror.netcologne.de/apache.org/hadoop/core/hadoop-1.2.1/hadoop_1.2.1-1_x86_64.deb
dpkg -i hadoop_1.2.1-1_x86_64.deb

## ========================
## Hadoop configuration
## see http://hadoop.apache.org/docs/stable/single_node_setup.html
## ========================

# set JAVA_HOME variable to oracle java
sed -i /etc/hadoop/hadoop-env.sh -e 's/export JAVA_HOME=\/usr\/lib\/jvm\/java-6-sun/export JAVA_HOME=\/usr\/lib\/jvm\/java-6-oracle/g'

# format distributed file system
sudo -u $HADOOP_USER hadoop namenode -format

# configure Hadoop for pseudo-distributed operation
echo -e "<configuration>\n<property>\n<name>fs.default.name</name>\n<value>hdfs://localhost:9000</value>\n</property>\n</configuration>" > /etc/hadoop/core-site.xml
echo -e "<configuration>\n<property>\n<name>dfs.replication</name>\n<value>1</value>\n</property>\n</configuration>" > /etc/hadoop/hdfs-site.xml
echo -e "<configuration>\n<property>\n<name>mapred.job.tracker</name>\n<value>localhost:9001</value>\n</property>\n</configuration>" > /etc/hadoop/mapred-site.xml

# start Hadoop
sudo -u $HADOOP_USER start-all.sh

# display Hadoop user credentials
echo "============================================="
echo "Installation finished"
echo "Username: $HADOOP_USER"
echo "Password: $HADOOP_USER"
echo ""
echo "PLEASE CHANGE THE PASSWORD OF THE USER!"
echo "============================================="

# exit
exit 0
```

We just have to agree to the license of [Oracle Java 6](http://www.oracle.com/technetwork/java/index.html) (I could not find the way to bypass this single interactive step). Everything else is done by the script. The single steps are commentated as good as possible. Receive a copy of the script and execute it as root. Wait a while, accept the Java license and you are done. A fully working Hadoop server for your pocket. To ensure that everything works as intended lets execute some test commands.

``` bash
# login with the hadoop user (password is hadoop)
$ su hadoop
$ cd

# print the hadoop version
$ hadoop version

# create a file with some textual content
$ echo "Hello World - Let's rule the World with Hadoop" > text

# load text file into Hadoop filesystem
$ hadoop fs -put text text-input

# run the Hadoop word count example task
$ hadoop jar /usr/share/hadoop/hadoop-examples-1.2.1.jar wordcount text-input wordcount-output

# list content of Hadoop filesystem
$ hadoop fs -ls

# display the task results
$ hadoop fs -cat wordcount-output/*

# clean up
$ hadoop fs -rm text-input
$ hadoop fs -rmr wordcount-output
```

That's it for now. In the next post we will create our first own Hadoop task with [Maven](http://maven.apache.org/) (yeah, another Apache project!).
