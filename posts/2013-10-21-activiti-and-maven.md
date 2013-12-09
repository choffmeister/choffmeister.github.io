title: "Activiti and Maven"
publishDate: "2013-10-21"

Recently I was working on a .NET based tool to simulate business processes. Thanks to [BPMN 2.0](http://www.bpmb.de/images/BPMN2_0_Poster_EN.pdf) and its XML specification there is a widely adopted file format to exchange business process models between tools of different vendors. Today I was playing around with [Activiti](http://www.activiti.org/) and created a small Java application with Maven that runs the Activiti Engine on a demo business model. Assuming you have Java, Maven and GIT properly installed on your system, you can take this project as a starting point to try your own ideas with it.

Open up a console window and execute the following commands:

<script src="https://gist.github.com/choffmeister/7877886.js?file=clone.sh"></script>

Thats all. The unit test provided with the project creates a process engine, deploys a BPMN 2.0 XML into it, starts a process instance and completes the two manual tasks in it.

<script src="https://gist.github.com/choffmeister/7877886.js?file=AppTest.java"></script>

For simulations (thats what I was actually interested in) the process engine seems to be much to slow. By now I did not search the internet for this concern. But it might be worth a try, to investigate how suitable the Activiti Engine is for simulation purposes with some customizations...
