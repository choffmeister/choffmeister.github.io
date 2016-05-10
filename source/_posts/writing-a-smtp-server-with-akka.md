---
layout: post
title: Writing a SMTP server with Akka
date: 2014-09-26 16:59:16 +0200
tags: [scala, akka]
---

Today I want to show you how to implement a purely reactive [Simple Mail Transfer Protocol](http://tools.ietf.org/html/rfc5321) server with [Akka](http://akka.io/). Of course at heart there will be actors involved and so, if you are not familiar with Akka and actors I suggest to go to [Akka's getting started guide](http://doc.akka.io/docs/akka/snapshot/intro/getting-started.html) first. The implementation we will dig in today is far away from beeing production ready. In particular things like Authentication, SSL/STARTTLS, Spamchecking and so on are out of scope of this article.

So let's get into it. If you want to follow along you can clone my project from [GitHub](https://github.com/choffmeister/akka-smtpserver). First we need a working [SBT](http://www.scala-sbt.org/) project with Akka as dependency. So lets create a project and add Akka:

```scala
// build.sbt
libraryDependencies ++= Seq(
  "com.typesafe.akka" %% "akka-actor" % "2.3.5",
  "com.typesafe.akka" %% "akka-slf4j" % "2.3.5"
)
```

### Server skeleton

As I assumed that you have basic knowledge on Akka I will just explain the basic skeleton with a few words:

```scala
// Application.scala
package de.choffmeister.akka.smtpserver

import akka.actor._

import scala.concurrent.duration._

class Application extends Bootable {
  implicit val system = ActorSystem("smtpserver")
  implicit val executor = system.dispatcher

  def startup() = {
    // register all needed actors
  }

  def shutdown() = {
    system.shutdown()
    system.awaitTermination(3.seconds)
  }
}

object Application {
  def main(args: Array[String]) {
    val app = new Application()
    app.startup()
  }
}

trait Bootable {
  def startup(): Unit
  def shutdown(): Unit

  sys.ShutdownHookThread(shutdown())
}
```

We have an object `Application` that acts as entry point and just creates one instance of the class `Application` and then executes the `run()` method. The `Bootable` trait defines two methods `startup` and `shutdown` whereas the `shutdown` method is registered to be invoked before the application is shut down (for example due to a `SIG_TERM` or `SIG_INT`). The Actor system is created on instantiation and is shutdown before termination. Note, that we wait at most 3 seconds for the actor system to acutally shutdown. If it takes longer the JVM exit will force the actor system to death.

> The `Application` class/object can be reused in all server like Akka applications.

### Akka TCP server

The next obvious thing we need is something to listen for incoming TCP connections. This is what the `TcpServer` actor is made for:

```scala
// TcpServer.scala
package de.choffmeister.akka.smtpserver

import java.net.InetSocketAddress

import akka.actor._
import akka.io.Tcp._
import akka.io._

class TcpServer(bind: InetSocketAddress, handler: ActorRef ⇒ Props)
    extends Actor with ActorLogging {
  implicit val system = context.system
  IO(Tcp) ! Bind(self, bind)

  def receive = {
    case Bound(local) ⇒
      log.debug("Bound to {}", local)

    case CommandFailed(_: Bind) ⇒
      log.error("Unable to bind to {}", bind)
      context.stop(self)

    case Connected(remote, local) ⇒
      log.debug("New connection from {}", remote)
      val connection = sender()
      context.actorOf(handler(connection))
  }
}
```

The `TcpServer` takes a local address to bind to, for example `new InetSocketAddress("0.0.0.0", 25)` to listen on port 25 on all network interfaces. In addition it takes a function of type `ActorRef ⇒ Props` that allows the creating of new handler actors (see step 3 in the following illustration). The creation function is given the TCP actor from `akka.io` that we have to register our handler actor with and must return an actor (or more precisely the `Props` for an actor).

![Akka TCP Server](/img/akka-tcp-server.png)
> Again the `TcpServer` class can be reused for any TCP server.


The most basic "Hello World" style TCP handler actor might just respond to every incoming byte string with exactly the same byte string. This, let's call it `EchoTcpHandler`, could look like this:

```scala
// EchoTcpHandler.scala
import akka.actor._
import akka.io.Tcp._

class EchoTcpHandler(connection: ActorRef) extends Actor {
  connection ! Register(adapter)

  def receive = {
    case Received(data) ⇒ connection ! Write(data)
  }
}
```

Suppose we wanted to build such a service, then in our `Application.startup` method we would just add:

```scala
val bind = new InetSocketAddress("0.0.0.0", 12345)
val server = system.actorOf(Props(
  new TcpServer(bind,conn ⇒ Props(new EchoTcpHandler(conn)))))
```

What does this do? The first line just defined on what port and what interface to listen on. The second line creates a new `TcpServer` actor and tells him, that on every incoming connection there should be a new `EchoTcpHandler` created to actually handle the new connection.

Now we already have a fully reactive Akka actor based TCP server that does one thing and that well: Yelling back at you what you yell to him.

### Simple Mail Transfer Protocol

The `SmtpServer` is basically a finite state machine reacting to incoming `Tcp.Received` events. Take a look at a typical SMTP transmission protocol:

```text
S: 220 foo.com Simple Mail Transfer Service Ready
C: HELO bar.com
S: 250 OK
C: MAIL FROM:<Smith@bar.com>
S: 250 OK
C: RCPT TO:<Jones@foo.com>
S: 250 OK
C: RCPT TO:<Green@foo.com>
S: 550 No such user here
C: RCPT TO:<Brown@foo.com>
S: 250 OK
C: DATA
S: 354 Start mail input; end with <CRLF>.<CRLF>
C: This is
C: my
C: mail!
C: .
S: 250 OK
C: QUIT
S: 221 foo.com Service closing transmission channel
```

When a client connects, the server starts with sending a `220` reply to the client and then just waits. Eventually the client responds with an `HELO` command and in respond to that the server replies with an `250` reply. This play goes back and forth. In every state there are only some valid commands that a client may send and all others are replied to with an `500` error reply. But if the client sends a valid command then the state of the server may change so that maybe other commands may be valid. Be happy, Akka has very good support for writing reactive finite state machines (see [FSM](http://doc.akka.io/docs/akka/snapshot/scala/fsm.html)).

We need six distinct states that our (simple) SMTP server can be in. In addition we have two different data types that can be attached to the states:

```scala
// SmtpServer.scala
object SmtpServer {
  sealed trait State
  case object State0 extends State
  case object State1 extends State
  case object State2 extends State
  case object State3 extends State
  case object State4 extends State
  case object State5 extends State

  sealed trait Data
  case object Empty extends Data
  case class Envelope(from: Option[String] = None, to: List[String] = Nil, body: ByteString = ByteString.empty) extends Data
}
```

After registering to the Tcp actor the SmtpServer sends itself a `Register` message and then starts up in `State1`waiting for the `Register` messages. This is kind of a starting shot. When the server receives the message it sends an `220 localhost` reply to the client and transists into state `State2`. From there on the server waits for either the `HELO` or `EHLO` command from the client. When he gets that, he replies with a `250 OK` and transists into state `State3`. You get the idea, right? The rest is just sticking to the RFC and reacting the the right messages in the right state extracting the necessary information and transisting into the right next state. If the client sends the `QUIT` command the server replies with `221 OK`, notifies the TCP actor to close the connection and transists into `State0`. In this state every incoming message is ignored silently, since the server just waits for the TCP connection to actually end. If this happends, the server actor releases itself.

```scala
// SmtpServer.scala
package de.choffmeister.akka.smtpserver

import java.net.InetSocketAddress

import akka.actor._
import akka.io.Tcp._
import akka.util.ByteString

class SmtpServer(connection: ActorRef) extends FSM[SmtpServer.State, SmtpServer.Data] {
  import de.choffmeister.akka.smtpserver.SmtpServer._

  connection ! Register(self)
  self ! Register(self)

  when(State0)(PartialFunction.empty)

  when(State1) {
    case Event(Register(_, _, _), _) ⇒
      reply(220, "localhost")
      goto(State2)
  }

  when(State2) {
    case Event(Received(Command("HELO", remoteName)), _) ⇒
      reply(250, "OK")
      goto(State3)

    case Event(Received(Command("EHLO", remoteName)), _) ⇒
      reply(250, "OK")
      goto(State3)
  }

  // ...

  whenUnhandled {
    // http://tools.ietf.org/html/rfc5321#section-4.1.1.10
    case Event(Received(Command("QUIT", _)), _) ⇒
      reply(221, "OK")
      connection ! Close
      goto(State0)

    case Event(_: ConnectionClosed, _) ⇒
      log.debug("Connection closed")
      context.stop(self)
      goto(State0)

    case Event(e, s) ⇒
      log.warning("received unhandled request {} in state {}/{}", e, stateName, s)
      reply(500, "What?")
      stay()
  }

  startWith(State1, Empty)
  initialize()

  def reply(code: Int, message: String = "") = adapter ! Write(Reply(code, message))
}
```

You might wonder, where the `Command` and `Reply` class come from: These are simple objects with an `unapply(raw: ByteString)` method that allow to deconstruct a raw `ByteString` into a "parsed" SMTP command/reply. Take a look at [SmtpProtocol.scala](https://github.com/choffmeister/akka-smtpserver/blob/master/src/main/scala/de/choffmeister/akka/smtpserver/SmtpProtocol.scala) for more details. It's really just some string splitting.

### Conclusion

We have seen the most important stuff around building an SMTP server with Akka IO. My project at GitHub contains some more advanced stuff like for example:

* A `DelimitedTcpPipeline` class that ensure, that the communication is always line based (i.e. the `SmtpServer` never receives a message like `Hello` and then `\r\nWorld\r\n`, but always well defined complete lines like `Hello\r\n` and then `World\r\n`).
* A `LoggingTcpPipeline` that logs all incoming and outgoing messages to the console.

To try it out just execute the following commands from your terminal:

```bash
$ git clone https://github.com/choffmeister/akka-smtpserver.git
$ cd akka-smtpserver
$ sbt run
```

Now you can open up another terminal and connect via `telnet` to port `25252`:

```bash
$ telnet localhost 25252
```
