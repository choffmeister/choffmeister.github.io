---
layout: post
title: "Akka vs. Node"
date: 2015-01-20 13:01:12 +0100
comments: true
categories: akka nodejs benchmark
---

This post is about the two competitors [Akka](http://akka.io/) (akka-http respectively) and [NodeJS](http://nodejs.org/) and their abilitiy to scale. To create kind of a real word comparable benchmark, I have created the following scenario:

* There is a MongoDB database containing 10,000 user records (each consisting out of an id, a name and a description string)
* Both, akka-http and nodejs provide a single route `/api/user` where they create a query to MongoDB, that extracts randomly one user record and return it as JSON string
* This route is tortured with [wrk](https://github.com/wg/wrk) with different levels of concurrency

Having some kind of external IO service within the benchmark is intentional. Pure CPU/memory bounded REST services are not the usual real world thing and quite theoretically. Note, that for both server there is a time window in each request, where they have to wait for MongoDB to respond - hence they can show their ability to use this spare time for handling other incoming requests.

The benchmark execution is done by the following recipe:

1. Run both the Akka and the NodeJS server
2. Warm both servers up by accessing them both for several seconds
3. Start with a client request concurrency of 1
4. Access the route on the Akka server as fast as possible for one minute
5. Sleep a little
6. Access the route on the NodeJS server as fast as possible for one minute
7. Sleep a little
8. Double the concurrency level and repeat with step 4 until a concurrency level of 256 has been reached

I have run this benchmark on my MacBook Pro Retina 15" Mid 2014 (having a quad core Intel-i7 and 16 GiB of RAM). Obviously it would also be very interesting to have this benchmark running on a server machine with more cores available.

## Results

Raw results can be found [here](/data/akka-vs-node.tsv).

### Requests per second

This chart shows for both competitors who many requests they can handle per second depending on who much concurrent requests there are at a time.

<div id="chart1"></div>

For low concurrency NodeJS beats Akka by a fair amount. But spinning up the pressure Akka scales much better until it reaches it's saturation level. At this stage Akka handles about 54% more request per time as NodeJS does.

### Response times

The response times are also a good metric to compare. The next graph shows the average response time:

<div id="chart2"></div>

Having no concurrency both are really fast with response times below 5 milliseconds. Bringing concurrency in the average response time of Akka sky rockets up to around 45 milliseconds while NodeJS just raises a little bit. This shows Akka's needed overhead to manage real concurrent threads while NodeJS is just an event loop, hence single threaded. At an concurrency of 8 Akka's response time drop again by 50% (could have to do with the fact, that my MacBook has 4 cores with hyper threading). As concurrency goes up the response time of NodeJS raises proportionally. Akka again scales better until the point, where it beats NodeJS.

The last graph shows the 50%-quantile of the response times. That means, that is shows the response time in which 50% of all requests were handled:

<div id="chart3"></div>

We see: Even if NodeJS is better in average response time (for low/medium concurrency), Akka still manages to serve 50% of the requests faster than NodeJS most of the time regardless of the level of concurrency.

## Conclusion

This is short: Planning to build a big REST application? Use Akka! It just scales way better and allows to use every single bit of computation power you have.

<script src="/javascripts/d3.min.js"></script>
<script src="/javascripts/dimple.min.js"></script>
<script type="text/javascript">
  var svg1 = dimple.newSvg("#chart1", '100%', 400);
  var svg2 = dimple.newSvg("#chart2", '100%', 400);
  var svg3 = dimple.newSvg("#chart3", '100%', 400);

  var sort = function (a, b) {
    var an = parseInt(a.Concurrency, 10);
    var bn = parseInt(b.Concurrency, 10);
    return an < bn ? -1 : 1;
  };

  d3.tsv("/data/akka-vs-node.tsv", function (data) {
    data = dimple.filterData(data, "System", ["akka", "node"]);

    var chart1 = new dimple.chart(svg1, data);
    chart1.setMargins(70, 30, 30, 60);
    chart1.addCategoryAxis("x", "Concurrency").addOrderRule(sort);
    chart1.addMeasureAxis("y", "RequestsPerSec");
    chart1.addSeries("System", dimple.plot.line).addOrderRule(["akka", "node"], true);
    chart1.addLegend(60, 10, -80, 20, "right");
    chart1.draw();

    var chart2 = new dimple.chart(svg2, data);
    chart2.setMargins(70, 30, 30, 60);
    chart2.addCategoryAxis("x", "Concurrency").addOrderRule(sort);
    chart2.addMeasureAxis("y", "LatencyAvg");
    chart2.addSeries("System", dimple.plot.line).addOrderRule(["akka", "node"], true);
    chart2.addLegend(60, 10, -80, 20, "right");
    chart2.draw();

    var chart3 = new dimple.chart(svg3, data);
    chart3.setMargins(70, 30, 30, 60);
    chart3.addCategoryAxis("x", "Concurrency").addOrderRule(sort);
    chart3.addMeasureAxis("y", "Latency50");
    chart3.addSeries("System", dimple.plot.line).addOrderRule(["akka", "node"], true);
    chart3.addLegend(60, 10, -80, 20, "right");
    chart3.draw();

    window.onresize = function () {
      chart1.draw(0, true);
      chart2.draw(0, true);
      chart3.draw(0, true);
    };
  });
</script>
