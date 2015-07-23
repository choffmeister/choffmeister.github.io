---
layout: post
title: "Activiti and Maven"
date: "2013-10-21 12:00:00"
categories: java maven activiti bpmn
abstract: Today I was playing around with Activiti and created a small Java application with Maven that runs the Activiti Engine on a demo business model...
comments: true
---

Recently I was working on a .NET based tool to simulate business processes. Thanks to [BPMN 2.0](http://www.bpmb.de/images/BPMN2_0_Poster_EN.pdf) and its XML specification there is a widely adopted file format to exchange business process models between tools of different vendors. Today I was playing around with [Activiti](http://www.activiti.org/) and created a small Java application with Maven that runs the Activiti Engine on a demo business model. Assuming you have Java, Maven and GIT properly installed on your system, you can take this project as a starting point to try your own ideas with it.

Open up a console window and execute the following commands:

```bash
$ git clone https://github.com/choffmeister/activiti-demo.git
$ cd activiti-demo
$ mvn test
```

Thats all. The unit test provided with the project creates a process engine, deploys a BPMN 2.0 XML into it, starts a process instance and completes the two manual tasks in it.

```java
// AppTest.java
package de.choffmeister.activitidemo;

import java.util.List;

import org.activiti.engine.*;
import org.activiti.engine.runtime.*;
import org.activiti.engine.task.*;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * Unit test for simple App.
 */
public class AppTest extends TestCase {
    /**
     * Create the test case
     *
     * @param testName
     *            name of the test case
     */
    public AppTest(String testName) {
        super(testName);
    }

    /**
     * @return the suite of tests being tested
     */
    public static Test suite() {
        return new TestSuite(AppTest.class);
    }

    public void testApp() {
        // Create Activiti process engine
        ProcessEngine processEngine = ProcessEngineConfiguration
                .createProcessEngineConfigurationFromResourceDefault()
                .buildProcessEngine();

        // Get Activiti services
        RepositoryService repositoryService = processEngine.getRepositoryService();
        RuntimeService runtimeService = processEngine.getRuntimeService();
        TaskService taskService = processEngine.getTaskService();

        // Deploy the process definition
        repositoryService.createDeployment().addClasspathResource("test1.bpmn20.xml").deploy();

        // Assert that no process instance is running
        assertEquals(0L, runtimeService.createProcessInstanceQuery().count());

        // Start a process instance
        ProcessInstance instance = runtimeService.startProcessInstanceByKey("financialReport");

        // Assert that one process instance is running
        assertEquals(1L, runtimeService.createProcessInstanceQuery().count());

        List<Task> tasks = taskService.createTaskQuery().taskCandidateGroup("accountancy").list();
        Task task = tasks.get(0);

        taskService.claim(task.getId(), "fozzie");
        taskService.complete(task.getId());

        List<Task> tasks2 = taskService.createTaskQuery().taskCandidateGroup("management").list();
        Task task2 = tasks2.get(0);

        taskService.claim(task2.getId(), "fozzie");
        taskService.complete(task2.getId());

        // Assert that no process instance is running anymore
        assertEquals(0L, runtimeService.createProcessInstanceQuery().count());
    }
}
```

For simulations (thats what I was actually interested in) the process engine seems to be much to slow. By now I did not search the internet for this concern. But it might be worth a try, to investigate how suitable the Activiti Engine is for simulation purposes with some customizations...
