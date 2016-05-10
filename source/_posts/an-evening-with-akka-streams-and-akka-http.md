---
layout: post
title: An evening with akka-streams and akka-http
date: 2015-01-16 01:34:43 +0100
tags: [scala, akka]
---

This evening I had the pleasure to join a talk about the two new [Akka](http://akka.io/) components akka-streams and akka-http from [Dr. Roland Kuhn](http://rolandkuhn.com/) at Xing's central in Hamburg, Germany. I was very interested in this since I am using [Spray](http://spray.io/) for quiet some time now and had some struggle with it when it comes to streaming data. So now there is just a little bit more time to wait until Spray's successor akka-http will reach it's first final release. The first release will hit us at the end of February and at the end of April there should everything be in place for real production usage.

## akka-streams

What are streams, what is the problem here? One might run into the trap and think that streams and collections are kind of the same. They are not. While collections are always finite and can be hold in the hand as one piece, streams are possible infinite and time based. Data might flow in at an unbounded rate and a consumer has to deal with that.

### Push model

Consider some kind of sensor (for example temperature) and this sensor publishes a stream where he sends a thousand measurements per second. First note is, that what you will get from the stream depends an when you start to listen. You won't get the measurements from the past. They are gone. Second note is, that when you as consumer listen to these data stream from the producing sensor and want to handle it, like for example store it in a database, there are two edge cases:

1. Consumer is faster: You can store a single measurement faster in the database as the measurements come in.
2. Producer is faster: The sensor produces the measurements faster than you can store them away.
    1. Solution a: Buffer the measurements to not loose any measurement
    2. Solution b: Drop some measurements to prevent out of memory errors

Since we are in the push model (sensor fires measurements whenever he wants to) we would be happy if we as consumer are faster since then everything is fine. If we are slower, then either potentially infinite memory for the buffer is needed or some data has to be dropped. Neither of both is a sufficient solution.

### Pull model

Now consider a sensor, that only produces measurements if you ask him for. This is classical pull model an we as client could ask for a measurement, store it away and then ask for the next. This way there is no problem with unbounded incoming data. On the other side this will yield slow performance (the sensor might be able to produce more measurements if we would ask more often).

### Reactive Streams

The [reactive stream](http://www.reactive-streams.org/) idea lives between the push and the pull model. If the producer is faster then the stream degenerates into pull model and if the consumer is faster then the stream denegenerates into a push model. In both ways you get optimal performance without unnecessarily overwhelming the consumer nor boring the producer. This is reached by sending stream "data" downstream" and notifying "demand" for more data "upstream" (called back-pressure). Some visualization borrowed from [Typesafe](http://typesafe.com/):

![Reactive Streams](https://lh3.googleusercontent.com/_khRe-0lcq2nMlp886zUr7MDKyBanMXhy_2uN4X3Oxdq2qhES_g7QsO15NKvZHV4p_uz27jEqRBxezlcNGNXxFFFYT0FxMwfs4iY9YFnkTIw7Vlb6HY2oY58cJ4dlFFU)

In addition to easy back-pressure streams allow the familiar collection based transformations like `map`, `flatMap`, `take`, `drop` and so on. On top of that there are time-based operations. For example you can easily chop a stream to only yield data for the first 60 seconds.

## akka-http

Akka-http is fully based an reactive streams. The benefit over Spray therefore is, that you can easily model chunked requests/responses and (in the future) will have support for WebSockets. For users of Spray there is good news. Apart from namespaces there will just be subtle changes. Hence a migration from Spray (which can be considered deprecated) to akka-http should be very simple. To try it out now here some sample code. First you have to add the experimental libraries for akka-http itself and for the integration of spray-json:

```scala
// build.sbt
libraryDependencies ++= Seq(
  "com.typesafe.akka" %% "akka-http-experimental" % "1.0-M2",
  "com.typesafe.akka" %% "akka-http-spray-json-experimental" % "1.0-M2"
)
```

Some kind of minimal REST server now might look like this:

```scala
// Server.scala
import akka.actor._
import akka.http.Http
import akka.http.Http.ServerBinding
import akka.http.server.Directives._
import akka.http.server.Route
import akka.stream.FlowMaterializer

implicit val system = ActorSystem("akka-http-demo")
implicit val executionContext = system.dispatcher
implicit val materializer = FlowMaterializer()

lazy val route: Route =
  path("order" / HexIntNumber) { id ⇒
    get {
      complete(s"Received GET for order $id")
    } ~
    put {
      complete(s"Received PUT for order $id")
    }
  }

val binding: ServerBinding = Http(system).bind(interface = "localhost", port = 8080)
binding.startHandlingWith(route)
```

The `route` can be constructed just like it is possible with Spray. For more concrete information please refer to akka-http or Spray documentation.
