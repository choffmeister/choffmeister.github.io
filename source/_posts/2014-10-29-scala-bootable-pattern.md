---
layout: post
title: "Scala bootable pattern"
date: 2014-10-29 06:29:56 +0100
comments: true
categories: scala
---

When you are creating a service/daemon like application in Scala, you need to write your main class in a certain way: I needs the handle two main state transitions:

1. Startup the service and all asynchronous running tasks
2. Shutdown the service gracefully, for example when a `SIG_INT` or `SIG_TERM` is received

This short tutorial show who to properly package this behaviour into a trait and a class. First lets look at the involved trait, having a simple `() => Unit` function for each transition:

``` scala Bootable.scala
trait Bootable {
  def startup(): Unit
  def shutdown(): Unit
}
```

This trait has to be implemented by a stateful class, for example it could spin up an [Akka](http://akka.io/) actor system in it's `startup` method and shutdown the actor system in it's `shutdown` method. In addition we neeed a class that implements a default `main` function and takes over the act of calling the `startup` function and registering the execution of the `shutdown` function before the JVM gets shutdown. This looks like so:

``` scala BootableApp.scala
import scala.reflect.Manifest

class BootableApp[T <: Bootable: Manifest] extends App {
  val manifest = implicitly[Manifest[T]]
  val bootable = manifest.runtimeClass.newInstance.asInstanceOf[T]
  sys.ShutdownHookThread(bootable.shutdown())
  bootable.startup()
}
```

There are some things to notice:

1. `BootableApp` extends `App`, hence every object that extends `BootableApp` can act as valid entry point for your application.
2. `T` must extend our `Bootable` type and there must be an implicitly `Manifest[T]` in scope, when extending `BootableApp`. That allows the instantiation of a new instance of type `T` from within `BootableApp` (given that `T` has a parameterless constructor).
3. It automatically invokes the `startup` method and registers the `shutdown` method to be invoked before the JVM exits (gracefully).

Your individual server main class now might look something like this (the class `MyThread` is just for demonstration purposes):

``` scala Server.scala
object Server extends BootableApp[Server]

class Server extends Bootable {
  // create some background thread
  val thread = new MyThread()

  def startup() = {
    println("startup")
    // start the thread
    thread.start()
  }

  def shutdown() = {
    println("shutdown")
    // tell the thread to stop
    thread.terminate()
    // wait for the thread to stop
    thread.join()
  }
}

class MyThread extends Thread {
  private var i = 0
  private var terminating = false

  def terminate() = terminating = true

  /** Prints the next number every second. */
  override def run(): Unit = {
    while (!terminating) {
      println(i)
      i = i + 1

      Thread.sleep(1000L)
    }
  }
}
```

Running this application and then pressing `Ctrl+C` after some seconds then yields the following ouput:

``` plain
startup
0
1
2
3
^Cshutdown
```
