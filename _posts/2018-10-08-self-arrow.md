---
layout: post
title: "Desambiguating 'this' in Scala, or what the hell means `self =>`?"
author: ragb
---

This is a quick Scala tip on a somehow unknown feature of the Scala language, what I call *self aliasing* or *unconstrained self type annotations*. One sees that in some libraries or even in the Scala standard library itself.
It goes something like this:

```scala
trait MyTrait { self =>
  //...
}
```

What? You probably have seen a similar self type annotation within the context of the now infamous cake pattern:

```scala
trait A {
  def doAStuff = ???
}

trait B {
  this: A =>
  def doBStuff = doAStuff
}
```

This means that the `B` trait can only be mixed in something that mixes `A`, which makes `A` members available to `B`.
Someone just thought this pattern was awesome for dependency injection and everyone started using that, but it doesn't scale at all... And then lots of pain and legacy to maintain.

Anyway, getting back to our first example, why that `self =>`
 thing? It's not constraining anything whatsoever... It is giving another name to `this`:
 
```scala
trait MyTrait { self => }
// is equivalent to
trait MyTrait2 {
  private val self = this
}
```

Without any context it can be difficult to grasp why one needs to give a different name to `this`, so let us show a small example.

We will show the definition for a function (`Function1`) from some type `A` to `Option[B]` (for some type `B`). Moreover we will implement the ` andThen` method to compose two such functions, if the first function returns some value `B`
(there is a powerful abstraction for this concept called a [kleisli arrow][kleisli], but it's out of the scope of this article).

Let's start from the basic trait's definition:

```scala
trait Function1Option[-A, +B] {
  def apply(a: A): Option[B]
}
```

So we define an abstract `apply` method (as function-like things do in scala) which concrete instances must implement. Still, without knowing about the concrete `apply`
one can easily define the `andThen` implementation, right?
 
```scala
trait Function1Option[-A, +B] {
  def apply(a: A): Option[B]
  
  final def andThen[C](that: Function1Option[B, C]): Function1Option[A, C] =
    new Function1Option[A, C] {
      override def apply(a: A): Option[C] = this.apply(a) match {
        case Some(b) => that.apply(b)
        case None => None
      }
    }
}
// <console>:21: error: type mismatch;
//  found   : b.type (with underlying type C)
//  required: B
//                case Some(b) => that.apply(b)
//                                           ^
```
 
This "`b.type` with underlying type `C`" mismatch means basicaly the compiler is telling you that `b` is not of `B` type but of `C`, and `that` function is expecting a `B` value, as we requested it to be.
Can you spot the problem there?

You are calling `this.apply(a)`, but.. who is `this`?
By the fact the compiller is telling you that `this.apply(a)` is returning something with a `C` value there, I believe you can get what it is trying to call: the inner `apply` method.
`this`, in the inner function's context, means that same object, not any outer trait. It is shadowing the outer `this`.

And how do you get to the outer trait's apply?
You've got it: alias `this` to something else in the outer trait's context.
 
```scala
trait Function1Option[-A, +B] { self =>
  def apply(a: A): Option[B]
  
  final def andThen[C](that: Function1Option[B, C]): Function1Option[A, C] =
    new Function1Option[A, C] {
      override def apply(a: A): Option[C] = self.apply(a) match {
        case Some(b) => that.apply(b)
        case None => None
      }
    }
}
```
 
Voilà!
 
This is a very contrived example and not something you'll probably do in practice. However, it shows you one instance where aliasing `this` to something else makes possible to desambiguate a method name.
Such a pattern is very useful when you define anonymous instances or inner traits/classes, and you want to be clear on what object you are refering to, even if you don't need to explicitly desambiguate anything.
 
Hope it helps.
 
[kleisli]: https://typelevel.org/cats/datatypes/kleisli.html
