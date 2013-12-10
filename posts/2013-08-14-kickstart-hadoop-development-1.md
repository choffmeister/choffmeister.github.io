title: "Kickstart Hadoop development - Part 1"
publishDate: "2013-08-14"
abstract: |
  This post will show you have to get a super fast kickstart into development
  with Hadoop (1.2.1). We will use Vagrant (1.2.7) to supply a virtual Hadoop
  server machine...

This post will show you have to get a super fast kickstart into development with [Hadoop](http://hadoop.apache.org/) (1.2.1). We will use [Vagrant](http://vagrantup.com/) (1.2.7) to supply a virtual Hadoop server machine. First of all visit the Vagrant homepage and install it on your system. In addition we need [VirtualBox](https://www.virtualbox.org/) (4.x) to actually run our VM.

Done with that, create a new directory and create a new file called ```Vagrantfile```. This will contain our configuration for the virtual machine that runs Hadoop.

<script src="https://gist.github.com/choffmeister/7874613.js?file=Vagrantfile"></script>

We use Ubuntu LTS 12.04.2 x64 as operating system, 2 GB of RAM and 2 virtual CPU cores. The machine will be reachable under the IP 10.10.10.10 from our local machine. Now lets delegate the nifty work of creating and booting a VM to Vagrant by executing

<script src="https://gist.github.com/choffmeister/7874613.js?file=cmd1.sh"></script>

Vagrant will load the base image, configure the network and start the VM with VirtualBox. When Vagrant has finished you can SSH into the machine with

<script src="https://gist.github.com/choffmeister/7874613.js?file=cmd2.sh"></script>

Create a secure shell to the VM by its private network IP 10.10.10.10 is possible, too, but by now we don't have a username/password to get access that way. So lets enter the VM with ```vagrant ssh``` and install Hadoop. For that I have create a single script that does all the work.

<script src="https://gist.github.com/choffmeister/7874613.js?file=cmd3.sh"></script>

We just have to agree to the license of [Oracle Java 6](http://www.oracle.com/technetwork/java/index.html) (I could not find the way to bypass this single interactive step). Everything else is done by the script. The single steps are commentated as good as possible. Receive a copy of my script and start the installation by executing

<script src="https://gist.github.com/choffmeister/7874613.js?file=cmd4.sh"></script>

Wait a while, accept the Java license and you are done. A fully working Hadoop server for your pocket. To ensure that everythings works as intended lets execute some test commands.

<script src="https://gist.github.com/choffmeister/7874613.js?file=cmd5.sh"></script>

That's it for now. In the next post we will create our first own Hadoop task with [Maven](http://maven.apache.org/) (yeah, another Apache project!).