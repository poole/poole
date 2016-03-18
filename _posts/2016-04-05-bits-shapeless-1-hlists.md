---
layout: post
title: "Bits of Shapeless part 1: HLists"
author: ragb
---

[Shapeless][shapeless] is a well known library for generic programming in scala. It is the basis for many widely used libraries  and recent interesting projects in the Scala ecosystem, such as [spray][spray], [Circe][circe], [Scodec][scodec] and [many others][manyOthers].

This is the first tutorial in a series where we seek to explain some of shapeless's more interesting features.

In this installment we will cover one of the basic building blocks of shapeless and its generic programming capabilities: the **heterogeneous List** or simply `HLists`, along with type-level recursion. We will make a parallelism between common linked lists and hlists to better introduce these concepts.

It is assumed that the reader is familiar with Scala and is confortable with language constructs like generic types and implicit parameters.

### Recapping Linked Lists

A simplified definition of Scala's Immutable List is the following (full code [here][scalaLists]):

```scala
sealed abstract class List[+T] {
  def ::[U >: T](head: U): List[U] = new ::[U](head, this)
}
case class ::[T](head: T, tail: List[T]) extends List[T]
case object Nil extends List[Nothing]
```

Creating a list of integers is easy (remember that `::`is right-associative in scala and `a :: b`is desugared  to `b.::(a)`).

```scala
1 :: 2 :: 3 :: Nil
// res0: List[Int] = List(1, 2, 3)
```

The fact that the list is by nature recursive is crucial when manipulating it. For instance, summing a list of integers can be implemented as the following recursive function:

```scala
def sumInts(l: List[Int]): Int = l match {
  case Nil => 0 // termination case
  case head :: tail => head + sumInts(tail) // recursion
}
// sumInts: (l: List[Int])Int

sumInts(1 :: 2 :: 3 :: Nil)
// res1: Int = 6
```


This simple recursive pattern can be used to implement many algorithms and is the basis for the remainder of this post, even if it doesn't seem so at first glance.

### HLists

If one requires a list with elements of different types, things are not that straight-forward with  linked lists:

```scala
1 :: 1.0 :: Nil
// res2: List[AnyVal] = List(1, 1.0)

1 :: "hello" :: Nil
// res3: List[Any] = List(1, hello)
```

Notice that the list's element type becomes the least upper bound between the `head` element and `tail`'s type parameter, which for many purposes is desirable.
However, if one wants to keep type information around  -- i.e. -- wants a list of an integer and a string, each element type information must be encoded in the list type itself.
The **Heterogeneous** list solves exactly this necessity.

The shapeless definition of this data structure is somehow similar to the List definition above (full code [here][hlists]):

```scala
// Simplified definition:
sealed trait HList extends Product with Serializable
final case class ::[+H, +T <: HList](head : H, tail : T) extends HList
sealed trait HNil extends HList {
  def ::[H](h : H) = shapeless.::(h, this)
}
case object HNil extends HNil
```

There are a couple of interesting things happening here:

- `HNil` is the `Nil` counterpart for hlists.
- The `::`(cons) case class definition has two generic type parameters, one for the head element type, `H`, and one for the tail, `T`, which itself must be an `HList`. Recursion, what else...
- `HNil` is both defined as a sealed trait and as the single incarnation of that trait. This allows the usage of `HNil` as a type and a value. If it was just a case object its type would be `HNil.type`, which would be ugly to read.
- `::`is defined as a method of `HNil` so 1 :: HNil can be properly written.

Observe the result type of the following expressions:

```scala
import shapeless._
// import shapeless._

1 :: "hello" :: true :: HNil
// res4: shapeless.::[Int,shapeless.::[String,shapeless.::[Boolean,shapeless.HNil]]] = 1 :: hello :: true :: HNil

1 :: 2 :: 3 :: HNil
// res5: shapeless.::[Int,shapeless.::[Int,shapeless.::[Int,shapeless.HNil]]] = 1 :: 2 :: 3 :: HNil

1 :: (1 :: HNil) :: "hello" :: HNil
// res6: shapeless.::[Int,shapeless.::[shapeless.::[Int,shapeless.HNil],shapeless.::[String,shapeless.HNil]]] = 1 :: (1 :: HNil) :: hello :: HNil
```

Although probably convoluted at first, you can see that all element type information is retained in the second type parameter of `shapeless.::`, even for nested `HLists`.

HLists share many of the operations we are used to in Scala Collections, with all type information available at compile time:

```scala
val l = 1 :: "hello" :: true :: HNil
// l: shapeless.::[Int,shapeless.::[String,shapeless.::[Boolean,shapeless.HNil]]] = 1 :: hello :: true :: HNil

l.head
// res7: Int = 1

l.tail
// res8: shapeless.::[String,shapeless.::[Boolean,shapeless.HNil]] = hello :: true :: HNil

l(1)
// res9: String = hello

l(2)
// res10: Boolean = true

l.length // Return's a type representation of a natural number
// res11: shapeless.Succ[shapeless.Succ[shapeless.Succ[shapeless._0]]] = Succ()

l.length.toInt // Type class ToInt[l.length] is implicitly computed at compile time.
// res12: Int = 3

l.drop(3)
// res13: shapeless.HNil = HNil
```

Moreover, we have some guarantees at compile time that are impossible to achieve with common single-typed Lists and other collections. For instance:

```scala
l.drop(4)
// <console>:17: error: Implicit not found: shapeless.Ops.Drop[shapeless.::[Int,shapeless.::[String,shapeless.::[Boolean,shapeless.HNil]]], shapeless.Succ[shapeless.Succ[shapeless.Succ[shapeless.Succ[shapeless._0]]]]]. You requested to drop an element at the position shapeless.Succ[shapeless.Succ[shapeless.Succ[shapeless.Succ[shapeless._0]]]], but the HList shapeless.::[Int,shapeless.::[String,shapeless.::[Boolean,shapeless.HNil]]] is too short.
//        l.drop(4)
//              ^
```

As the `HList`size is known in compile time (is encoded in the type itself) the `drop` is written in such a way that the compiler verifies that one is not dropping more elements than the known length. In this case it is, so the compilation fails.

### Recursion with HLists

suppose we want to compute the "size" of an HList and we define the size as the following:

- The size of the HList is the sum of the sizes of all the hlist's elements
- The size of an integer is 1.
- The size of a String is the string's length

(we could have defined size for other types of course, but we will only use ints and strings for our example).

This translates pretty nicely to a type class [^poly], with corresponding instances for Int, String and the `HList.`

In Scala, type classes are usually encoded as a trait with a generic Type and instances for concrete types being present in scope as implicit values or definitions.

The `Sized` type class definition [^sized] is then as follows:

```scala
trait Sized[-T] {
  def size(t: T): Int
}

object Sized {
  // Helper to get the size for a value
  def size[T](t: T)(implicit tSized: Sized[T]) = tSized.size(t)

  // Helper to create a type class instance from a function from T to Int
  def instance[T](f : T => Int) = new Sized[T] {
    def size(t: T) = f(t)
  }
}
```

And instances for `int`and `String`are simply:

```scala
implicit val intSized: Sized[Int] = Sized.instance(_ => 1)
// intSized: Sized[Int] = Sized$$anon$1@5fa2e9bf

implicit val stringSized: Sized[String] = Sized.instance(s => s.length)
// stringSized: Sized[String] = Sized$$anon$1@694c6499
```

Lets try it out:

```scala
import Sized.size
// import Sized.size

size(1)
// res16: Int = 1

size("hello")
// res17: Int = 5
```

It works. However, we are still missing a way to process the HList and its elements

As we have done with simple Lists, we will use recursion to process the `HList`, defining both a base (termination) case and the recursive invocation. However, instead of a runtime function with two cases (which in Scala maps to pattern matching) we will encode these in the type system with type class instances, one for `HNil` and another for the `::` recursive structure.

For `HNil`we define a size of 0 (the empty list):


```scala
implicit val hnilSized = Sized.instance[HNil](_ => 0)
```

For `::` we define the size as the size of the head of the HList plus the size of the tail, which is also another `HList`. 

```scala
implicit def hconsSized[H, T <: HList]
  (implicit hSized: Sized[H], tSized: Sized[T]) =
  Sized.instance[H :: T] { l =>
    hSized.size(l.head) + tSized.size(l.tail)
}
```

Let's analyse this definition:

- The implicit definition has two type parameters, one representing the type of the head of the HList, `H`, and another representing the type of the tail of the list, `T`, which is required to by a subtype of `HList`.
- `hSized` and `tSized` are implicit parameters resolved to `sized` type instances available in the implicit scope. 
- `hSized`is whatever implicit `Sized[H]`the compiler finds, for simple examples a `Sized[Int]`or `Sized[String]`.
- However `tSized`is necessarily a `Sized[_ <: HList]` which is either `hnilSized`(the base case) or the recursive invocation of `hconsSized`until the base case is reached.
- The body of the function is simply the summation of the sizes for the list's head and tail, with no unbounded recursive call at runtime.

Let's test it:

```scala
size(HNil)
// res18: Int = 0

size(1 :: "hello" :: HNil)
// res19: Int = 6

size(1 :: "" :: 1 :: HNil)
// res20: Int = 2

size(1 :: (1 :: "hello" :: HNil) :: HNil)
// res21: Int = 7
```

To better understand what is going on, here is a snippet where we explicitly pass the needed type classe instances to compute the `sized` instance for a `Int :: String :: HNil` HList  -- the work that the implicit resolution mechanism does for us:

```scala
val l: Int :: String :: HNil = 1 :: "hello" :: HNil
// l: shapeless.::[Int,shapeless.::[String,shapeless.HNil]] = 1 :: hello :: HNil

val lSized: Sized[Int :: String :: HNil] = hconsSized(
  intSized,
  hconsSized(stringSized, hnilSized))
// lSized: Sized[shapeless.::[Int,shapeless.::[String,shapeless.HNil]]] = Sized$$anon$1@4e149069

lSized.size(l)
// res22: Int = 6
```

This can be mind-blowing at first, but in the end is quite straightforward, given the fact that the Scala compiler can recursively resolve implicit parameters for a method, computed by the same method.

### Conclusion

We have covered just a small bit of what can be done with heterogeneous lists, but explained the  powerful concept of type-level recursion. Type-level recursion, either along with HLists or with other types will be the basis for the next posts on Shapeless, which will cover more advanced topics such as generic derivation, labelled generics, natural numbers (in types), and so on.

At [E.Near][enear] we have used Shapeless to solve many problems in a clean and elegant way. Some of them will be showcased as more advanced concepts are introduced...

[shapeless]: https://github.com/milessabin/shapeless
[spray]: http://spray.io
[Circe]: https://github.com/travisbrown/circe
[scodec]: https://github.com/scodec/scodec
[manyOthers]: https://github.com/milessabin/shapeless/wiki/Built-with-shapeless
[scalaLists]: https://github.com/scala/scala/blob/2.11.x/src/library/scala/collection/immutable/List.scala
[hlists]: https://github.com/milessabin/shapeless/blob/master/core/src/main/scala/shapeless/hlists.scala
[enear]: http://www.enear.co


[^poly]: There is a much simpler implementation of this idea with polymorphic functions in shapeless's documentation, but for explanation purposes we are using a type class based approach.

[^sized]: There is a `Sized` type class in Scala which is used for collections with statically known size. That has nothing to do with our example.
