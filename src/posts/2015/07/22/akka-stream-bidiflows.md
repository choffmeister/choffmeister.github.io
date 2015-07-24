---
layout: post
title: "Use akka-stream BidiFlows with an IRC client"
date: 2015-07-22 19:44:00 +0100
comments: true
categories: scala akka stream reactive
---
Just a few days ago the awesome [Akka][akka] guys released the [akka-stream][akka-stream] and akka-http library in version 1.0. So now it is finally a good time, to really dig into that stuff. I have already made some very good experience with using akka-http for an image service. Although, I already faced the raw akka-stream API while doing this project, I still had many open questions especially about [stream graphs][akka-stream-graphs]. In this blog post I want to give a brief introduction in how to write a fully reactive backpressured IRC client with Akka.

I assume, that you already have some basic knowledge on akka-streams. If not feel free to look into one of my older posts [here](posts:posts-2015-01-16-an-evening-with-akka-streams-and-akka-http). Flows are a really powerful stream abstraction, that allow unidirectional data transfer in a reactive and backpressured manner. But if you think about protocols like HTTP, IRC, SMTP and so on, one direction of data flow is not sufficient. Here does the `BidiFlow` (abbreviation for bidirectional flow) come into play. From the outside view it is basically two flows in opposite directions: one representing the input data flow from upstream to downstream and one representing the output dataflow from downstream to upstream. The inner view of a `BidiFlow` on the other hand can do what ever it wants, from simple stuff like (de)serializing binary data into objects and vice versa to complex stateful stuff.

# Composition

You can compose multiple `BidiFlow`s together. Let's say you want to implement a client (like the IRC client we are heading to): Then you have on the one side the TCP stack with an input data stream to read from and an output data stream to write to. To make the client run, we have to somehow connect the input data stream with the output data stream by something protocol aware, that writes the correct output messages in reaction to input messages. In between there often several good to separate steps like serialization, logging, filtering and stuff. The general picture looks like this:

![Akka BidiFlow composition](images:akka-bidiflow-composition.png)

`BidiFlow`s as well as `Flow`s are strongly typed in terms of what type of elements they can consume and produce. So two `BidiFlow`s are composable if and only if the `out1`-type of `A` is compatible with the `in1`-type of B and the `out2`-type of B is compatible with the `in2`-type of `A`.

# Simple logging BidiFlow example

As our first `BidiFlow` let's implement one, that is just passing through the data in both directions, but creates a log output for every item passed. There are several convienent ways, to create a `BidiFlow` in Akka. Since here we are in a simple case, where input and output stream are unrelated, the code is rather simple:

```scala
def logging: BidiFlow[ByteString, ByteString, ByteString, ByteString, Unit] = {
  // function that takes a string, prints it with some fixed prefix in front and returns the string again
  def logger(prefix: String) = (chunk: ByteString) => {
    println(prefix + chunk.utf8String)
    chunk
  }

  val inputLogger = logger("> ")
  val outputLogger = logger("< ")

  // create BidiFlow with a separate logger function for each of both streams
  BidiFlow(inputLogger, outputLogger)
}
```

Now `logging` is a reusable `BidiFlow` that consumes and produces `ByteString`s on all its ends, and logs everything to the console.

# Simple echo TCP client

This is a simple TCP client that echos every chunk coming from the server back to the server. In between we join in our logging `BidiFlow`, so that we can watch the data on the console.

```scala
// connect via TCP to google.de:80
Tcp().outgoingConnection(new InetSocketAddress("google.de", 80))
  // log all incoming and outgoing data chunks
  .join(logging)
  // for each data chunk coming in write the same data chunk to the output
  .join(Flow[ByteString])
  // runs the client
  .run()
```

# Writing an IRC client

Writing an IRC client is a good way more complex than a simple echo client. But not to hard either, thanks to Akka's nice API.

First let's start of with some (de)serialization code that allows us convert between the raw byte stream from the TCP stack and strongly typed classes representing the individual IRC commands:

```scala
import akka.util.ByteString
import scala.util._

case class IrcCommand(command: String, args: Seq[String], source: Option[String] = None)

object IrcCommand {
  def read(raw: ByteString): Try[IrcCommand] = {
    val regex = """(:([^ ]+) )?([A-Z0-9]+)( (.*))?""".r
    raw.utf8String match {
      case regex(_, sourceOrNull, command, _, argsStringOrNull) =>
        val source = Option(sourceOrNull)
        val argsRaw = Option(argsStringOrNull).map(_.split(" ", -1).toSeq).getOrElse(Nil)
        val args = argsRaw.indexWhere(_.startsWith(":")) match {
          case -1 => argsRaw
          case c => argsRaw.take(c) ++ Seq(argsRaw.drop(c).mkString(" ").drop(1))
        }
        Success(IrcCommand(command, args, source))
      case _ =>
        Failure(new Exception(s"Cannot parse '${raw.utf8String}'"))
    }
  }

  def write(cmd: IrcCommand): ByteString = {
    val p1 = cmd.source.map(":" + _ + " ").getOrElse("")
    val p2 = cmd.command
    val p3 = cmd.args match {
      case Nil => ""
      case last :: Nil => " :" + last
      case args => args.init.map(" " + _).mkString + " :" + args.last
    }
    ByteString(p1 + p2 + p3)
  }
}
```

OK, done (sure, there are more performant implementations for that). Now we implement a small part of the IRC protocol. That is

* sending nick-, user- and realname to the server and
* responding with a pong for every ping coming from the server.

The basic IRC client with (de)serialization, logging and no sending but just listening to the server looks like this:

```scala
/**
 * Reads/writes byte strings from/to the upstream.
 * Writes/reads typed IRC commands to/from the downstream.
 */
def serialization: BidiFlow[ByteString, IrcCommand, IrcCommand, ByteString, Unit] = {
  val read = Flow[ByteString]
    // ensure, that the byte strings are aligned to CRLF
    .via(Framing.delimiter(ByteString("\r\n"), 65536))
    // convert ByteString to IrcCommand
    .map(IrcCommand.read)
    // pass on successfully parsed IrcCommands and strip out unparseble ones
    .mapConcat {
      case Success(cmd) => cmd :: Nil
      case Failure(cause) => Nil
    }

  val write = Flow[IrcCommand]
    // convert IrcCommand to ByteString
    .map(IrcCommand.write)
    // append CRLF
    .map(_ ++ ByteString("\r\n"))

  // create BidiFlow with these to separated flows
  BidiFlow.wrap(read, write)((m1, m2) => ())
}

/**
 * Reads/writes IRC commands on all its ends.
 * Logs everything to console
 */
def logging: BidiFlow[IrcCommand, IrcCommand, IrcCommand, IrcCommand, Unit] = {
  def logger(prefix: String) = (cmd: IrcCommand) => {
    println(prefix + IrcCommand.write(cmd).utf8String)
    cmd
  }

  BidiFlow(logger("> "), logger("< "))
}

// raw tcp stream
// Flow[ByteString, ByteString, Future[OutgoingConnection]]
Tcp().outgoingConnection(new InetSocketAddress("irc.server.com", 6667))
  // with (de)serialization
  // Flow[IrcCommand, IrcCommand, Future[OutgoingConnection]]
  .join(serialization)
  // with logging
  // Flow[IrcCommand, IrcCommand, Future[OutgoingConnection]]
  .join(logging)
  // combine input with output, while just listening and not saying anything
  // RunnableGraph[Future[OutgoingConnection]]
  .join(Flow[IrcCommand].filter(_ => false))
  // Future[OutgoingConnection]
  .run()
```

This wires everything up, starts the client and runs all the communication. The result value is a promise, that is completed with as soon as the connection has been opened (you can also alter the future, to wait, until the whole communication has been finished).

## Handling ping messages

Who can we now handle ping messages. The [RFC-2812][rfc-2812] says that for every incoming `PING` message there has to be an outgoing `PONG` response. We can handle all this in a single `BidiFlow` and join it together without leaking anything out into the rest of the program:

![Akka BidiFlow ping handling](images:akka-bidiflow-irc-ping-handling.png)

Well, that is more complex than the stuff we had before, but let's break it down:

1. Every incoming message is duplicated in the "Broadcast" node and these duplications are splitted up into two indivual streams.
2. One stream leads to a "Filter", that lets only non `PING` messages pass. These messages get send to the downstream.
3. The other stream leads to a "Filter", that lets only `PING` messages pass. These messages get converted from a `PING` to a `PONG` message in the "Map" node.
4. The converted `PONG` messages are merge together at the "Merge" node with all the other incoming upstream messages and send out to the overall upstream of the `BidiFlow`.

Long story short: When joining in this BidiFlow, incoming `PING` messages are immediatly transformed to `PONG` messages and send back to the upstream. All other messages get normally passed downstream. All incoming upstream messages get normally passed upstream.

To represent this in code, akka-stream as a beautiful and powerful API, to create such graphs. Take a look, how closely the sourcecode relates to the diagram shown:

```scala
import akka.stream.scaladsl._

def ping: BidiFlow[IrcCommand, IrcCommand, IrcCommand, IrcCommand, Unit] = {
  // create a new BidiFlow from a stream graph
  BidiFlow() { implicit builder =>
    FlowGraph.Implicits._

    // create the Broadcast node with two outgoing ports
    val broadcast = builder.add(Broadcast[IrcCommand](2))

    // create the Merge node with two incoming ports
    val merge = builder.add(Merge[IrcCommand](2))

    // create the Filter node that only lets PINGs pass
    val filterPing = builder.add(Flow[IrcCommand].filter(_.command == "PING"))

    // create the Filter node that only lets non-PINGs pass
    val filterNotPing = builder.add(Flow[IrcCommand].filter(_.command != "PING"))

    // create the Map node, that converts a PING into a PONG
    val mapPingToPong = builder.add(Flow[IrcCommand].map(ping => IrcCommand("PONG", ping.args, None)))

    // connect the first broadcast outport to the one filter
    broadcast.out(0) ~> filterNotPing

    // connect the second boradcast outport the the other filter and that to the map and that to the first merge inport
    broadcast.out(1) ~> filterPing ~> mapPingToPong ~> merge.in(0)

    // create the BidiFlow with its four ports:
    // upstream in -> broadcast in
    // non-PING filter -> upstream out
    // downstream in -> merge in
    // merge out -> downstream out
    BidiShape(broadcast.in, filterNotPing.outlet, merge.in(1), merge.out)
  }
}
```

To finish things up, we can now easily enable `PING` message handling by joining the new `BidiFlow` in:

```scala
Tcp().outgoingConnection(new InetSocketAddress("irc.server.com", 6667))
  .join(serialization)
  .join(logging)
  .join(ping)
  .join(Flow[IrcCommand].filter(_ => false))
  .run()
```

# Conclusion

With just some dozen lines of code we could implement the basic parts for an fully reactive and backpressured IRC client. All the individual parts were easily separated and put together afterwards in a composable manner. I have to say: I am really looking forward to continue my IRC client and that is remarkable, since implementing stuff like that has always been a pain for me so far.

[akka]: http://akka.io/
[akka-stream]: http://doc.akka.io/docs/akka-stream-and-http-experimental/1.0/scala.html
[akka-stream-graphs]: http://doc.akka.io/docs/akka-stream-and-http-experimental/1.0/scala/stream-graphs.html
[rfc-2812]: https://tools.ietf.org/html/rfc2812
