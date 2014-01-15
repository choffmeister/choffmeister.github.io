---
layout: post
title: "An introduction to group theory"
categories: maths
abstract: "TODO"
---

In this post I will give an introduction to the mathematical discipline of _group theory_. Except for some basic school knowledge in maths and the will to look at the equations with love there is nothing to know to read this post. Before we go into the definition of what a _group_ actually is, let's start off with some properties of the integers and the addition of integers.

## Addition of integers

In maths, the set of integers is denoted with $\mathbb Z$. This symbol is derived from the German word for integers, "Zahlen". I guess everyone uses some simple rules without even thinking about it

### The identity element

If we have any integer and add 0 to it, then the integer does not change. In mathematical notation this can be expressed with

$$ \forall a \in \mathbb Z : a + 0 = a. $$

The symbol $\forall$ can be translated with "for all". Hence this reads "for all integers $a$ the equation $a + 0 = a$ holds". Adding 0 from the left works also:

$$ \forall a \in \mathbb Z: 0 + a = a $$

This property gives 0 a special name: It is called the _identity element_ of the integer addition.

### Associativity

Suppose we want to add three integers together. Then it does not matter if we first add the first two together and then add the third, or if we first add the second and the third integer and then add this result to the first:

$$ \forall a,b,c \in \mathbb Z : (a + b) + c = a + (b + c) $$

This property is called associativity.

### The inverse element

We already know a special element in the integers, the 0, which is the identity element of the addition of integers. Every integer has a special brother, called _inverse element_, so that their sum is equal to the identity element 0. For any integer $a$ the _inverse element_ is called $(-a)$.

$$ \forall a \in \mathbb Z \exists (-a) \in \mathbb Z : a + (-a) = 0 $$

Here we have a new cryptic symbol $\exists$. It can be translated with "exists". So "for all integers $a$ there exists another integer called $(-a)$, such that $a + (-a) = 0$ holds".

## Definition of a group

We are almost done with the definition of a _group_. We already have seen all properties of a _group_. So we know how a _group_ behaves. Remains open, what a _group_ is. Here is the formal definition:

**Definition:** Let $G$ be a set of elements and $\circ : G \times G \to G$ a _function_. Then the tuple $(G,\circ)$ is called a _group_, if the following three properties hold:

* (G1) Associativity: $\forall a,b,c \in G : (a \circ b) \circ c = a \circ (b \circ c)$
* (G2) Existence of a identity element: $\exists e \in G \forall a \in G : e \circ a = a = a \circ e$
* (G3) Existence of inverse elements: $\forall a \in G \exists b \in G : a \circ b = e$

> Decrypting the $\circ : G \times G \to G$ part: In maths a function is a mapping from elements of one set to elements of another (or the same) set. The definition $f : A \to B$ means, that $f$ is a function that takes elements from the set $A$ and returns elements from the set $B$. In our case, the function $\circ$ takes elements from $G \times G$ and returns elements from $G$. The set $G \times G$ is simply the set of pairs of elements from $G$. Hence $\circ$ takes to elements from $G$ and returns one element from $G$. The addition of integers fits in in this pattern. Adding two integers yields another integer. To make the addition make look more like a function you could just write $+(a,b) = c$ instead of $a + b = c$.

The set $G$ is called the set of the group and the function $\circ$ is called the operation. Most of the times the operation is denoted with $+$ or $\cdot$, like in our integer example. Hence the group we described in the beginning is denoted by $(\mathbb Z, +)$. If the operation is denoted by $+$, then the identity element is often denoted by $0$ and if the operation is denoted by $\cdot$, then the identity is often denoted by $1$.

## Some rules

**Lemma 1:** Let $(G,+)$ be a group and $a,b,c \in G$ such that $a+c = b+c$. Then $a = b$.

> This lemma allows one to reduce equal right sides of an equation of group elements.

**Proof:**

The following two equation chains can be obtained by using the rules (G2), (G3) and then (G1).

$$ a = a + 0 = a + (c + (-c)) = (a + c) + (-c) $$

$$ b = b + 0 = b + (c + (-c)) = (b + c) + (-c) $$

The right sides of the equations are equal, since $(a+c) = (b+c)$ is a prerequisite for this lemma. Hence $a = b$.
