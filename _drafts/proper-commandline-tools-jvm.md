---
layout: post
title: "How to write proper commandline tools for the JVM"
categories: java scala cli
abstract: "Many business applications are simple commandline tools that for example implement some kind of ETL process. Sadly, the adjective 'simple' is often reflected in the poor overall project structure and many fundamental mistakes when desiging such an application. This article will show you how to step around the biggest pitfalls."
---

# Application `main` method

~~~ java
public class Application {
  public static void main(String[] args) {
    try {
      // instantiate and run the application
      Application app = new Application();
      app.run(args);

      // return exit code indicating everything went fine
      System.exit(0);
    } catch (Exception ex) {
      // print exception to screen
      System.err.println(ex.toString());

      // return exit code indicating an error
      System.exit(1);
    }
  }

  public void run(String[] args) throws Exception {
    // application logic
  }
}
~~~

# Command line arguments

# Configuration

# Exception handling

# Exit code
