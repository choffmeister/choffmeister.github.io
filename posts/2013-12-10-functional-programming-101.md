title: "Functional Programming 101"
publishDate: "2013-12-10"
abstract: |
  Functional programming is a big topic at the moment. In
  this post I will cover some basics of functional programming
  and give some motivations on why this could be useful for
  you. Many small code examples shall help to work through. These
  examples are writen in Scala, but they are so basic, that
  you will be able to understand them quickly.

In this post I want to give a short introduction to functional programming (FP). FP is quiet a big word at the moment and I want to take a little bit of it's mystic fog way. For showcasing code examples I will use [http://www.scala-lang.org/](Scala). So if you do not know Scala keep on reading, we will only need some basics which follow within this post. Note, that since I want to talk about FP I will skip all class definitions (but we can imagine all to happen in a big class).

So let's start with the mind of an old-school imperative programmer… To be honest, this should not be hard since almost all programmers started this way. In a classical imperative programm there are two types of objects: data and functions. Trivially as it sound, data is some value and functions are some instructions to "do something". Well, on the road to functional programming we must look a little bit deeper.

## A short tour of Scala

For the code example I will use Scala. For those of you that already know Scala, just skipp this section, the rest: don't be scared, we will keep it simple.

<script src="https://gist.github.com/choffmeister/7893177.js?file=tour-of-scala.scala"></script>

In total we have defined four things, two values and two function. But what precisely are the types of those?

* Type of `i` is `Int`
* Type of `s` is `String`
* Type of `concat` is `(String, String) => String`
* Type of `takeFirst` is `[T](T, T) => T`

The first two are easy, but the type of `concat` and `takeFirst` might look strange to you. But it is not. It just says "`concat` is function that takes two `String` parameters and returns a value of type `String`" and "`takeFirst` is a generic function that takes two parameters of the same type `T` and returns value of type `T`".

## Functions are data

What is a function? In a mathematical sense, a function is a mapping between values of one type to value of another (or the same) type. In mathematics a function has no side effects and more over, only depends on its parameters and only has access to its parameters (which is even stronger than to be free of side effects). In this post lets assume, functions in programming have this restriction, too. A simple example might be the function, that tells us, if an integer is even.

<script src="https://gist.github.com/choffmeister/7893177.js?file=even.scala"></script>

First of all it is a function within our restrictive definition: It only accesses its single parameter `i` and returns a value, in this case `true` if `i` is even and `false` if `i` is odd. What else to tell about this, this is just a function right? Well yes, but on the other hand it can also be seen as data. Think of this function as a simple table that maps values from the left column to the values of the right column:

```
     0 , true
    +1 , false
    -1 , false
    +2 , true
    -2 , true
     … , …
2^31-1 , false
 -2^31 , true
```

Then we can throw away our `even` function and replace it with this table and the instruction, that `even(i)` can be received by looking up `i` in our table and take the value to it's right. This can be done with every function. Hence, you could just rewrite every program you have and replace the functions by tables. In the end you only have on last master function left which is the function that looks up values in the tables.

## Data is a function

What is data? In a computer program data is the content of a memory for which we have some kind of named pointer to that memory. Simple example again:

<script src="https://gist.github.com/choffmeister/7893177.js?file=value.scala"></script>

The value `123` is a 32-Bit integer that remains anywhere in memory and with the symbol `x` we have the named pointer that tells us where this place in memory is. But we can see data as a function to. Just replace variable `x` with a function of the same name that takes no parameters and always returns the same value:

<script src="https://gist.github.com/choffmeister/7893177.js?file=value-as-function.scala"></script>

So in particular data is the most simple kind of function one can think of.

## Why not threat functions and data the same?

In total we have seen that functions and data are just two views on the same thing. But if they are the same, why do many languages not allow to pass a function as a parameter to a function? Or another question: What benefit would we get from allowing this?

We have a list of integers and want to filter it by some criteria: We want to seperate the list into the sublist of even and the sublist of odd numbers. Let's to it the imperative style:

<script src="https://gist.github.com/choffmeister/7893177.js?file=filter-first-order.scala"></script>

Note how we used our `even` function. But also note, how we have code repetition: In both cases we create a new empty list, iterate over the `numbers` list, check a condition for every element and add it, if the condition is satisfied, to the new list. To avoid this kind of duplication we need something that is called a higher-order function, i.e. a function that gets at least on function as an parameter.

Our ultimate goal is to filter an arbitrary list of integers by an arbitrary condition, called predicate. Think back to the short tour of scala at the beginning: what is the type that our predicate to filter Integer numbers must have? It must take an integer and return a boolean to indicate, whether the value should be kept or discarded. Hence the type must be `Int => Boolean`. The duplicated code we have can so be outsourced in a generic filter function like this:

<script src="https://gist.github.com/choffmeister/7893177.js?file=filter-higher-order.scala"></script>

We have the exact same flow: Iterate over all elements and when the predicate matches for an element, add it to the result list. But this time we made the predicate a parameter that can be passed in. For good sake let's make the function generic to work with all kind lists:

<script src="https://gist.github.com/choffmeister/7893177.js?file=filter-higher-order-generic.scala"></script>

Now filtering to odd and even numbers is simple:

<script src="https://gist.github.com/choffmeister/7893177.js?file=use-filter1.scala"></script>

Now why does this work? Let's check the types:

* Type of `filter` is `[T](List[T], T => Boolean) => List[T]`
* Type of `numbers` is `List[Int]`
* Type of `even` is `Int => Boolean`

So if we pass `numbers` as first parameter to `filter` then `T` must be `Int` in this case. Hence `predicate` must be of type `Int => Boolean` which is the case, too. All type match perfectly.

The define a function to test if a number is even is ok, but often you do not want to choose names for function everytime. For this purpose there are lambda expressions in Scala. A lambda expression is just a short way to write function without name, called anonymous functions.

The following two definitions are equivalent:

<script src="https://gist.github.com/choffmeister/7893177.js?file=lambda-expression.scala"></script>

This way we can write our example even shorter:

<script src="https://gist.github.com/choffmeister/7893177.js?file=use-filter2.scala"></script>

## Loose ends

I hope I could give you a first insight into functional programming. There are still many topics uncovered like composibility and functional idiomatic (the filter function in this post is not very FP-like!). I plan to cover these things in another post soon.