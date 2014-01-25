---
layout: post
title: "Scala tuples"
date: "2014-01-25 11:01:00"
categories: scala
abstract: "Scalas tuples are much mure useful than the ones from C#/.NET. This article shows why."
---

In Scala there are tuple types just like in C#. But in Scala tuples are part of the language while in C# tuples are part of the .NET library. Therefore Scalas tuple are more powerful and easy to use. Tuples are useful, if for example a function must return two ore more different values. In this case you have two options: Create a new simple data container type to encapsulate the different return values into one, or use generic tuples (which of course at compile time creates a new type, too). Especially in functional proramming these tuples are very help full. But when I programmed C# I refused to use them, because the naming is akward. A little example:

Here is how tuples are used in C#:

~~~ csharp
class Test
{
  // Returns a tuple (name, age)
  public Tuple<String, Int> GetPerson()
  {
    return Tuple.Create("Tom", 23);
  }

  public void Main()
  {
    var person = GetPerson();
    var name = person.Item1;   // extract first value
    var age = person.Item2;    // extract second value
  }
}
~~~

As you can see, I have to manually extract the single tuple values into variables with helpful names. So I often ended up with creating a struct type that can hold the data.

In Scala there is much better support for tuples. The example from above looks much cleaner in Scala:

~~~ scala
class Test
{
  // returns a tuple (name, age)
  def getPerson() = ("Tom", 23)

  // manual extraction
  def main() {
    val person = getPerson()
    val name = person._1
    val age = person._2
  }

  // automatic extraction
  def main2() {
    val (name, age) = getPerson()
  }
}
~~~

So creating a new tuple is done with `(value1, value2, value3, ...)` and thanks to type inference the tuples are strongly typed. To get access to the values of a tuple, one can either access the fields manually with

~~~ scala
val tuple = ("foo", 123, List(1,2,3)) // has type (String, Int, List[Int])
val text = tuple._1
val number = tuple._2
val list = tuple._3

println(text + " " + number + " " + list)
~~~

or can create multiple named variables from the tuple at once with

~~~ scala
val tuple = ("foo", 123, List(1,2,3)) // has type (String, Int, List[Int])
val (text, number, list) = tuple

println(text + " " + number + " " + list)
~~~

It is really just syntactic sugar, but it makes me use tuples much more as return types (for internal functions).
