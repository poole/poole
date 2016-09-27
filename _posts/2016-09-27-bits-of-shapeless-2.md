---
layout: post
title: "Bits of Shapeless part 2: Generic Derivation"
author: ragb
---

This is the second installment in a series of articles about [Shapeless][shapeless].
The [first post][shapeless1] explained heterogeneous lists (HLists) and how to use them to do type-level recursion. Building on this ground, we will now talk about Generic derivation of case classes and sealed trait hierarchies. Along the way we shall cover other related subjects such as singleton-typed literals, products, coproducts (and labelled versions of those) and shapeless syntax goodies.

At the end of this post you will have built a basic Json rendering library for sealed hierarchies of case classes. Actually, if you aim to be a rockstar Scala coder you have to do a Json library one way or another :).

It is assumed that the reader knows about json, shapeless heterogeneous lists and how to work with them (see my [last post][firstPost]), knows about implicit resolution and is acquainted with the concept of type classes in Scala.

### Setup

Further from [Shapeless][shapeless] itself, we will use the [JAWN][jawn] Json parsing and `AST` library.
Some imports are assumed:

```scala
import shapeless._
import jawn.ast._
```

### HLists and beyond

Let's look at some very nice syntax shapeless provides us to manipulate objects as if they were HLists:

```scala
import syntax.std.tuple._
// import syntax.std.tuple._

(1,2,3).head
// res0: Int = 1

(1,2,3).tail
// res1: (Int, Int) = (2,3)
```

How is this possible?

```scala
(1,"a", 1.0).productElements // give me an HList
// res2: shapeless.::[Int,shapeless.::[String,shapeless.::[Double,shapeless.HNil]]] = 1 :: a :: 1.0 :: HNil
```

Maybe there is an implicit conversion from tuple to HList involved somehow... But:

```scala
case class C(x: Int, y: String)
// defined class C

val c = C(1, "hello")
// c: C = C(1,hello)

c.length
// res3: shapeless.Succ[shapeless.Succ[shapeless._0]] = Succ()

c.head
// res4: Int = 1

c.productElements
// res5: shapeless.::[Int,shapeless.::[String,shapeless.HNil]] = 1 :: hello :: HNil
```

As you might know, both tuples and case classes are products, so we may assume that the machinery involved is the same.

Let us go back a bit and explain how all these things were magically converted to HLists:



### Generic and products

Here I present you the `Generic`type class:

```scala
trait Generic[T] extends Serializable {
  type Repr
  def to(t : T) : Repr
  def from(r : Repr) : T
}
```

What this essentially means is that instances of `Generic[T]` can convert back and forth  from `T`to `Repr` -- a generic representation of `T`. However two questions arise:

1. How do we get instances of `Generic[T]`, further from implementing them by hand?
2. And shouldn't be `Repr` some kind of `HList`?

To answer those:

```scala
val gen = Generic[(Int, String)]
// gen: shapeless.Generic[(Int, String)]{type Repr = shapeless.::[Int,shapeless.::[String,shapeless.HNil]]} = anon$macro$24$1@753b3812

gen.to((1, "hello"))
// res6: gen.Repr = 1 :: hello :: HNil
```

Note the type of the `gen`variable: the inner type `Repr`is automatically derived for us. This `Generic` type might be strange for some. There exists an associated `Generic.Aux[T, Repr]`, which is more commonly used, as you will see below. If you are not familiar with the Aux pattern, [this is a good explanation][auxPattern], and [this answer explains its applicability  in shapeless][genericAux].

```scala
val genc = Generic[C]
// genc: shapeless.Generic[C]{type Repr = shapeless.::[Int,shapeless.::[String,shapeless.HNil]]} = anon$macro$27$1@6dee40f3

genc.to(c)
// res7: genc.Repr = 1 :: hello :: HNil

genc.from(1 :: "bye" :: HNil)
// res8: C = C(1,bye)
```

Hopefully you are now convinced that `Generic` instances can be derived for product types, namely tuples and case classes. The exact implementation details are not important for common usage, but for the brave ones [here is the code][shapelessGeneric].

Meanwhile, case classes convey more information than a product of elements. 
They associate a label with each element. How can this concept be represented in a generic form?

### Types for All Literals

What if we had specific types for all literals? For instance, a single type for the literal `1` which is a subtype of integer? You might think "ah, nice, good for you". Believe this will become useful.

Shapeless provides singleton typed literals -- `Witness` -- for this purpose:

```scala
Witness(1)
// res9: shapeless.Witness.Aux[Int(1)] = shapeless.Witness$$anon$1@2febff2f

Witness("hello")
// res10: shapeless.Witness.Aux[String("hello")] = shapeless.Witness$$anon$1@dea9afe
```

Notice the types of these expressions, they refine integers and other literal types.

And they can be put to work:

```scala
// A function that only accepts the integer 2:
def just2(arg: Witness.`2`.T) = arg
// just2: (arg: Int(2))Int

just2(2)
// res12: Int = 2
```

It fails, at compile-time, for every integer except 2.

```scala
just2(3)
// <console>:23: error: type mismatch;
//  found   : Int(3)
//  required: Int(2)
//        just2(3)
//              ^

just2(0)
// <console>:23: error: type mismatch;
//  found   : Int(0)
//  required: Int(2)
//        just2(0)
//              ^
```


This `Witness.<literal>` weird syntax is just Scala's [dynamic member lookup][dynamic] along with more macro-based machinery. Details [here][singletons].

Last but not the least look at the signature of the following function:

```scala
def singletonValue[K <: Symbol](implicit ev: Witness.Aux[K]): ev.T = ev.value
// singletonValue: [K <: Symbol](implicit ev: shapeless.Witness.Aux[K])ev.T

singletonValue[Witness.`'name`.T]
// res15: Symbol with shapeless.tag.Tagged[String("name")] = 'name
```


This expression computes the `Witness` and singleton type for the symbol `'name`. If we associate a value and its type with a singleton typed symbol, we have a good starting point to handle case classes in a Generic way.


### Labelling values with types

As you may already have guessed, shapeless provides exactly what we need to label our values:

```scala
Object Labelled {
//...
  type FieldType[K, +V] = V with KeyTag[K, V]
  trait KeyTag[K, +V]
//...
}
```

`FieldType[K,V]` specialises the type `V`, tagging it with the `K` type. And `K`, can be a  symbol, tagged with the literal symbol's name. Actually `K`is a singleton type which covers what we need to make a better Generic representation of case classes (and other types):

```scala
case class Person(name: String, age: Int)
// defined class Person

val p1 = Person("John", 30)
// p1: Person = Person(John,30)

val genPerson = LabelledGeneric[Person]
// genPerson: shapeless.LabelledGeneric[Person]{type Repr = shapeless.::[String with shapeless.labelled.KeyTag[Symbol with shapeless.tag.Tagged[String("name")],String],shapeless.::[Int with shapeless.labelled.KeyTag[Symbol with shapeless.tag.Tagged[String("age")],Int],shapeless.HNil]]} = shapeless.LabelledGeneric$$anon$1@48552363

val reprP1 = genPerson.to(p1)
// reprP1: genPerson.Repr = John :: 30 :: HNil
```

Pay attention to the `Repr`type of the second last expression. It is essentially a`HList` of the case class elements, each one refined wit the `FieldType` tagging type described above. Shapeless calls this a `Record`, and it has many interesting operations: by itself

```scala
import record._
// import record._

reprP1.get('name)
// res16: String = John

reprP1.get('age)
// res17: Int = 30

reprP1.toMap
// res18: Map[Symbol with shapeless.tag.Tagged[_ >: String("age") with String("name") <: String],Any] = Map('age -> 30, 'name -> John)

reprP1.keys
// res19: shapeless.::[Symbol with shapeless.tag.Tagged[String("name")],shapeless.::[Symbol with shapeless.tag.Tagged[String("age")],shapeless.HNil]] = 'name :: 'age :: HNil

reprP1.values
// res20: shapeless.::[String,shapeless.::[Int,shapeless.HNil]] = John :: 30 :: HNil

reprP1.remove('age)
// res21: (Int, shapeless.::[String with shapeless.labelled.KeyTag[Symbol with shapeless.tag.Tagged[String("name")],String],shapeless.HNil]) = (30,John :: HNil)
```

note that all the value types are properly retained.

Moreover, `LabelledGeneric` is very much like `Generic`, but specialised for these labelled product types.

 Magic? No... Just even more macros and implicits along the way.

### Rendering Json


This post's motivation is to render case class type instances into Json. For this we need to step back -- again -- to scaffold the necessary infrastructure. If you know some other type class-based Json library this should be familiar ground to you.

We define the `JsonWrites`typeclass bellow:

```scala
trait JsonWrites[-T] {
  def write(t: T): JValue
}

// Companion object
object JsonWrites {
  def apply[T](f: T => JValue) = new JsonWrites[T] {
    def write(t: T) = f(t)
  }
}

// some default instances
// probably better in the companion object...
implicit val stringWrites = JsonWrites(JString(_:String))
implicit val intWrites =  JsonWrites[Int](JNum(_))
implicit val longWrites = JsonWrites[Long](JNum(_))
implicit def optionWrites[T](implicit tWrites: JsonWrites[T]) = JsonWrites[Option[T]](_.fold[JValue](JNull)(t => tWrites.write(t)))
  // .......

// Some nice syntax
implicit class ToJsonOps[T](t: T)(implicit writes: JsonWrites[T]) {
  def toJson = writes.write(t)
}
```

Let's test the basics:

```scala
"hello".toJson
// res30: jawn.ast.JValue = "hello"

1.toJson
// res31: jawn.ast.JValue = 1

(Some(1): Option[Int]).toJson
// res32: jawn.ast.JValue = 1

(None: Option[Int]).toJson
// res33: jawn.ast.JValue = null
```

Ok, we have the basics in place, so let's get our hands dirty.

### Deriving case Classes

To derive `JsonWrites` for case classes in a generic way we need to know:

* A Labelled generic representation of the case class
* How to render all the values in the case class
* How to render values along with their tagging symbols, and combine those.

As you may recall from the [previous post][firstPost], we process `HLists`recursively and stop on `HNil`. So let us have a go there first:

```scala
implicit val hnilToJson = JsonWrites[HNil](_ => JObject.empty)
```

Next we shall derive the recursive case from what we already know and, not surprisingly, from the recursive definition itself:

```scala
import labelled.FieldType

implicit def hconsToJson[Key <: Symbol, Head, Tail <: HList](
    implicit key: Witness.Aux[Key],
    headWrites: JsonWrites[Head],
    tailWrites: JsonWrites[Tail])
    : JsonWrites[FieldType[Key, Head] :: Tail] =
    JsonWrites[FieldType[Key, Head] :: Tail] { l =>
      // compute the tail json:
      val json = tailWrites.write(l.tail)
      // JObject has a mutable map, just add to it:
      // (yes, Mutable).
      json.set(key.value.name, headWrites.write(l.head))
      json
  }
```

To finish we just have to use the labelled product representation of the case class to render it to Json, so we tell exactly that to the compiler, given we can always infer an implicit labelled generic representation for our type `T`:

```scala
implicit def lgenToJson[T, Repr](
    implicit lgen: LabelledGeneric.Aux[T, Repr],
    reprWrites: JsonWrites[Repr]) = JsonWrites[T] { t =>
    reprWrites.write(lgen.to(t))
  }
// lgenToJson: [T, Repr](implicit lgen: shapeless.LabelledGeneric.Aux[T,Repr], implicit reprWrites: JsonWrites[Repr])JsonWrites[T]
```

Testing it:

```scala
Person("John", 30).toJson
// res35: jawn.ast.JValue = {"age":30,"name":"John"}

case class Address(Street: String, Number: Option[Int])
// defined class Address

Address("Small Street", None).toJson
// res36: jawn.ast.JValue = {"Number":null,"Street":"Small Street"}

Address("Big Street", Some(22))
// res37: Address = Address(Big Street,Some(22))
```

### Deriving sealed hierarchies

The canonicall way to represent **ADTs** -- abstract data types -- in scala is using sealed traits and case classes/objects, such as the following:

```scala
sealed trait Shape extends Product with Serializable
case class Square(side: Long) extends Shape
case class Rectangle(width: Long, eight: Long) extends Shape
case class Circle(radius: Long) extends Shape
```

We can render a square, circle or rectangle to json, since they are case classes and we already know how to render those:

```scala
Circle(2).toJson
// res38: jawn.ast.JValue = {"radius":2}

Square(4).toJson
// res39: jawn.ast.JValue = {"side":4}

Rectangle(2,4).toJson
// res40: jawn.ast.JValue = {"eight":4,"width":2}
```

However, if we don't know what kind of shape we have there is a problem:

```scala
def shapeToJson(s: Shape) = implicitly[JsonWrites[Shape]].write(s)
// <console>:36: error: could not find implicit value for parameter e: JsonWrites[Shape]
//        def shapeToJson(s: Shape) = implicitly[JsonWrites[Shape]].write(s)
//                                              ^
```

To solve this problem there is the concept of a **Coproduct**, the dual concept of a product.
As oposed to the product, a coproduct represents one element that belong to just one of a set of types. It is like scale's Either extended to an arbitrary number of alternatives. In Shapeless:

```scala
type stringOrIntCP = String :+: Int :+: CNil
// defined type alias stringOrIntCP
```

This type represents something that can be a string or an integer.

Let us see what the coproduct definition looks like in shapeless:

```scala
sealed trait Coproduct extends Product with Serializable

sealed trait :+:[+H, +T <: Coproduct] extends Coproduct {
  // Non-recursive fold (like Either#fold)
  def eliminate[A](l: H => A, r: T => A): A
}

final case class Inl[+H, +T <: Coproduct](head : H) extends :+:[H, T] {
  override def eliminate[A](l: H => A, r: T => A) = l(head)
}

final case class Inr[+H, +T <: Coproduct](tail : T) extends :+:[H, T] {
  override def eliminate[A](l: H => A, r: T => A) = r(tail)
}

sealed trait CNil extends Coproduct {
  def impossible: Nothing
}
```

It is a bit more involved than `HList`.

* As analogous to HList's `HNil`, `CNil` marks the end of the type definition, and is used to stop recursion and to enable proper type construction.
* `:+:` is analogous to Hlist's `::` type constructor, however it can be either an `Inl`or `Inr`.
* At runtime if we have an instance of `Inl`we Know we are handling an instance of the "head" of the coproduct.
* Else if we come across an `Inr`we've got the "tail", which can have either an `Inl` or another nested `Inr` inside. 
* We are not supposed to reach `CNil`, ever.
* The `eliminate` method works much like `either`'s `fold`. If it is called on an instance of `Inl` the first function is used to produce an `A` value from the "head" element, else the second one is used to handle the recursive case within the "tail" part of the coproduct, eventually returning an `A` value.

The derivation example below will make this all much clearer.

Shapeless `LabelledGeneric` is capable of generating a coproduct representation of a sealed trait hierarchy, having all the known children as the possible values, tagged with its class's name -- a labelled coproduct.

```scala
LabelledGeneric[Shape]
// res41: shapeless.LabelledGeneric[Shape]{type Repr = shapeless.:+:[Square with shapeless.labelled.KeyTag[Symbol with shapeless.tag.Tagged[String("Square")],Square],shapeless.:+:[Rectangle with shapeless.labelled.KeyTag[Symbol with shapeless.tag.Tagged[String("Rectangle")],Rectangle],shapeless.:+:[Circle with shapeless.labelled.KeyTag[Symbol with shapeless.tag.Tagged[String("Circle")],Circle],shapeless.CNil]]]} = shapeless.LabelledGeneric$$anon$2@46e64391
```

Note the type of the expression result; all shapes are there, properly tagged.

To make our generic shape json-renderable (and other sealed trait hierarchies) let us tell the compiler how to render `Coproduct`instances into Json.

Although `CNil` should never be reached, we need an implicit `JsonWrites[CNil]` in scope, so the compiler can properly infer the right implicit (stop the type-level recursion):

```scala
implicit def cnilJsonWrites: JsonWrites[CNil] =
    JsonWrites[CNil](_ => throw new RuntimeException("shall not happen"))
```

The recursive case is easy, we add a `"$type"` field with the class's simple name so a deserializer can differentiate among types.

```scala
implicit def cconsJsonWrites[Key <: Symbol, Head, Tail <: Coproduct](
    implicit key: Witness.Aux[Key],
    headWrites: JsonWrites[Head],
    tailWrites: JsonWrites[Tail])
    : JsonWrites[FieldType[Key, Head] :+: Tail] =
  JsonWrites[FieldType[Key, Head] :+: Tail] {
    _.eliminate({ head =>
      val json = headWrites.write(head)
      // Add the $type discriminator
      json.set("$type", JString(key.value.name))
      json
    }, tail => tailWrites.write(tail))
}
```

It is quite similar to what we did with the `HList` above.
Instead of using the clever `eliminate` method we could certainly have employed pattern matching, something like:

```scala
case Inl(head) => ...
case Inr(tail) => ...
```

We already defined the conversion from `T` to its generic representation above, so it will be used as such (the new coproduct-related implicit will be picked automatically).

Now our `shapeToJson`method already works:

```scala
def shapeToJson(s: Shape) = implicitly[JsonWrites[Shape]].write(s)
// shapeToJson: (s: Shape)jawn.ast.JValue

shapeToJson(Circle(20))
// res42: jawn.ast.JValue = {"$type":"Circle","radius":20}

shapeToJson(Rectangle(2,3))
// res43: jawn.ast.JValue = {"$type":"Rectangle","eight":3,"width":2}
```

Voi la!

### Conclusion

What we have shown is the basic pattern for processing case classes and sealed trait hierarchies. In summary:

* Define how labelled products (case classes) are to be processed. Cases for HNil and `FieldType[Key, Head] :: Tail`.
* Define processing of labelled coproducts (sealed traits). Cases for `CNil` and `FieldType[Key, Head] :+: Tail`.
* Use the automatically derived generic `T`representation to  process values of type `T`, i.e. implicit parameters of type `LabelledGeneric.Aux[T, Repr]`.

### Further considerations

The Json dumping code we have shown is pretty basic and not that flexible (think, for instance in treatment of absent values, we could have omitted them instead of using `null`). Moreover, it would be good to have the *reading* infrastructure (`JsonReads[T]`), which is left as an exercise. It is a bit more verbose and complex to implement due to failure handling, so I chose to present the more simpler example to avoid distractions.

There are proper Scala Json libraries using shapeless.
[spray-json-shapeless][sprayJsonShapeless] is a very interesting case since the code is very clear and concise, and has some nice ideas and patterns for this sort of implementations.
[Circe][circe]'s generic derivation is more complex, although much more complete and flexible.

In the shapeless realm there is [automatic type class derivation][autoTypeclass] which can help a bit with generic derivation, although I find the presented pattern more flexible for intricate problems.

Two nice articles that cover this subject which I also recommend are [this][genericDerivation] and [this][cakeGeneric].

At [e.Near][enear] we have directly relied on Shapeless generic derivation to implement such things as writing/reading XML or producing messages to Kafka topics.

[shapelessGeneric]: https://github.com/milessabin/shapeless/blob/master/core/src/main/scala/shapeless/generic.scala
[dynamic]: http://blog.scalac.io/2015/05/21/dynamic-member-lookup-in-scala.html
[singletons]: https://github.com/milessabin/shapeless/blob/master/core/src/main/scala/shapeless/singletons.scala
[auxPattern]: http://gigiigig.github.io/posts/2015/09/13/aux-pattern.html
[firstPost]: http://enear.github.io/2016/04/05/bits-shapeless-1-hlists/
[genericDerivation]: https://meta.plasm.us/posts/2015/11/08/type-classes-and-generic-derivation/
[genericAux]: http://stackoverflow.com/questions/33725935/shapeless-generic-aux
[cakeGeneric]: http://www.cakesolutions.net/teamblogs/solving-problems-in-a-generic-way-using-shapeless
[shapeless]: https://github.com/milessabin/shapeless
[Circe]: https://github.com/travisbrown/circe
[enear]: http://www.enear.co
[autoTypeclass]: https://github.com/milessabin/shapeless/wiki/Feature-overview:-shapeless-2.0.0#automatic-type-class-instance-derivation
[sprayJsonShapeless]: https://github.com/fommil/spray-json-shapeless
[shapeless1]: http://enear.github.io/2016/04/05/bits-shapeless-1-hlists/
[jawn]: https://github.com/non/jawn
