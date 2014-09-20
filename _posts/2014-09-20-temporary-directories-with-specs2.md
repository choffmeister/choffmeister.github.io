---
layout: post
title: "Clean and safe temporary directories with specs2"
date: "2014-09-20 19:51:00"
categories: scala specs2
abstract: "A simple code snippet to simplify and harden the creation and usage of temporary directories with specs2."
---

In some scenarios you might have to write tests against the real file system. In this case you almost always need a dedicated temporary directory for each single spec (since they might execute in parallel). This behavior can be factored out into a seperate object with ease. In addition it allows to make sure, that these temporary directory get properly cleaned up afterwards. The code looks like this:

~~~ scala
import java.io.{ File, FileOutputStream }
import java.util.UUID

import org.specs2.execute._
import org.specs2.mutable._

object TempDirectory {
  def apply[R: AsResult](a: File ⇒ R) = {
    val temp = createTemporaryDirectory("")
    try {
      AsResult.effectively(a(temp))
    } finally {
      removeTemporaryDirectory(temp)
    }
  }

  /** Creates a new temporary directory and returns it's location. */
  def createTemporaryDirectory(suffix: String): File = {
    val base = new File(new File(System.getProperty("java.io.tmpdir")), "gittimeshift")
    val dir = new File(base, UUID.randomUUID().toString + suffix)
    dir.mkdirs()
    dir
  }

  /** Removes a directory (recursively). */
  def removeTemporaryDirectory(dir: File): Unit = {
    def recursion(f: File): Unit = {
      if (f.isDirectory) {
        f.listFiles().foreach(child ⇒ recursion(child))
      }
      f.delete()
    }
    recursion(dir)
  }
}
~~~

We define an object with an `apply` function that takes an argument `a` of type `File => R`. In this function we create a temporary directory, pass it to `a` and convert `a`'s return value to match specs2's needs. In the finally blog we ensure that the directory gets erased after executing our inner function `a`. Having this one can easily use it with specs2 to inject the temporary directory into single specs:

~~~ scala
class MySpec extends Specification {
  "MySpec" should {
    "have a temporary directory " in TempDirectory { temp ⇒
      // temp is now an unique temporary directory which gets removed after executing the test
    }
  }
}
~~~

That's it. Clean, easy and reusable!
