---
layout: post
title: Type constraints for code reuse and readability
author: jguitana
---

The case for statically typed languages is so that we can prove our programs are right at compile time. Although our languages are not powerful enough to achieve this all the time, we certainly not always use their full capabilities. Our intuition should guide us to reduce implementation space and improve code reuse, allowing us to focus on small parts of a big problem. We can only do this if we choose the right abstraction in the form of Types, because these act as constraints on the implementation space, and if built correctly bring with them reusable and tested code.

Let's take for example the `Int` and the `Nat` types. Int represents a number from `-x to x`. Nat represents a number from `0 to x`.

*The crux of the question is*: Whenever we expect a natural number in some closure, is it different to pass an Int argument then it is passing a Nat argument?

We are free to make a choice here, and many of us will not think about Nat.

Or maybe just take Int for performance reasons? Well, not all abstractions are free of cost, but the same reason we give for not using lower level languages applies - we want to develop software faster.

Maybe we will use negative numbers in the future? Well, first the program must run in the present. Refactoring constraints is ok, the compiler will help.

And will our program be correct if we do use Int? It might, but we will have to test the case when Int goes negative. This is what is meant by reducing implementation space. Using Nat achieves this, but Int will not. So we end up by having to write extra tests. We can see that in a dynamic language with no types, everything is unconstrained to some primitive types, thus all implementations must be tested.

We've made a quick mental exercise on the cases above and we can see downsides and upsides as with most things. The bottom line is that if we are not solving a C10k like problem, we are probably better off building a more readable, smaller, well constrained program.

Let's now take a look at `List` and `NonEmptyList` (from cats library).

List represents something which may or may not have elements and can be constructed as such:
- `List()` is the empty list
- `List(x)` is the list of one element
- `List(x, y, ...)` is the list of many elements

NonEmptyList represents something which may never have the first case above.
- `NonEmptyList(x)` is the list of one element
- `NonEmptyList(x, y, ...)` is the list of many elements

And it is actually a simple data type: `case class NonEmptyList[+A](head: A, tail: List[A])`.

Also note that we can represent the empty list case with `Option[NonEmptyList[A]]` where None is the empty list.

Now, we can choose to implement this simple fold using a List or a NonEmptyList.

```
def merge[A](x: A, y: A): A = ???

def fromList[A](ls: List[A]): Option[A] =
    ls.foldLeft(Option.empty[A])((b, a) => b.map(merge(_, a)))

def fromNel[A](nel: NonEmptyList[A]): A =
    nel.tail.foldLeft(nel.head)(merge)
```
Take a moment to appreciate that we removed the need for Option from the `fromNel` function implementation. We delayed the need to implement such behavior. This is due to List having an extra check compared to NonEmptyList: `isEmpty`. Our NonEmptyList function is more robust as it requires no testing for this case.

Actually, isEmpty is equivalent to `NonEmptyList.fromList` which accepts a `List` and returns an `Option[NonEmptyList[A]]`. So anytime we are doing multiple isEmpty checks we should probably realize our program should be working with a NonEmptyList.

Also note that `.filter` on a NonEmptyList will transform it back to a List, because it may remove all elements. So we should also consider consolidating filtering in our programs.

As yet another example, let's say we are parsing some data into a case class and that data has a List field which is never empty.
- `case class Unconstrained(ints: List[Int])`
- `case class Constrained(nats: NonEmptyList[Nat])`

Our parsing logic for `Constrained` will be more involved (unless it was built already, which is a common thing with json parsing for example), but as soon as we create the parser for this data, we gain in that we do not require extra checks anywhere else in our code. If this class is used multiple times, we get multiple checks for free.

With a more constrained type we avoid having to make an extra conditional check in possibly many places in our code. This effectively means less code and tests. Also, if these types are used often enough, it will improve readability for everyone since we make less assumptions.

Scala and other strong static languages will only help with correctness as long as our decisions are to constrain our programs as much as we can. This simple awareness is very important as it offers the opportunity to reduce the amount of code paths in the universe, and it spares our minds from excess suffering.

Thank you for reading!