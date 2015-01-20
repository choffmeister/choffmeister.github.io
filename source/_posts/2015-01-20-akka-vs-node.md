---
layout: post
title: "Akka vs. Node"
date: 2015-01-20 06:53:24 +0100
comments: true
draft: true
categories: akka nodejs benchmark
---

## Requests per second

<div id="chart1"></div>

## Average latency

<div id="chart2"></div>

## Latency of 50% of the request

<div id="chart3"></div>

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
